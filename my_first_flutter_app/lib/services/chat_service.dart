import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/contact.dart';
import '../models/message.dart';

class ChatService extends ChangeNotifier {
  Future<void> blockContact(String contactId) async {
    if (!_blockedContacts.contains(contactId)) {
      _blockedContacts.add(contactId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedKey, jsonEncode(_blockedContacts));
      notifyListeners();
    }
  }

  Future<void> unblockContact(String contactId) async {
    if (_blockedContacts.remove(contactId)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedKey, jsonEncode(_blockedContacts));
      notifyListeners();
    }
  }

  static const _blockedKey = 'chat_blocked_v1';
  List<String> _blockedContacts = [];

  List<String> get blockedContacts => _blockedContacts;
  Future<void> deleteContact(String contactId) async {
    debugPrint('[ChatService] Deleting contact: $contactId');
    _contacts.removeWhere((c) => c.id == contactId);
    _messages.remove(contactId);
    await _saveContacts();
    await _saveMessages();
    debugPrint(
      '[ChatService] Contacts after delete: \n${_contacts.map((c) => c.toJson())}',
    );
    notifyListeners();
  }

  static const _contactsKey = 'chat_contacts_v1';
  static const _messagesKey = 'chat_messages_v1';
  static const _privateKeyPref = 'private_key_v1';
  static const privateConversationId = 'private';
  static const _privateTtlMs = 30 * 60 * 1000; // 30 minutes
  static const _privateSessionKey = 'private_session_last_v1';
  static const _groupsKey = 'chat_groups_v1';
  static const _groupMembersKey = 'chat_group_members_v1';
  static const _blockedGroupsKey = 'chat_blocked_groups_v1';

  List<Contact> _contacts = [];
  Map<String, List<Message>> _messages = {};
  List<String> _groups = [];
  Map<String, List<String>> _groupMembers = {};
  List<String> _blockedGroups = [];
  int? _lastPrivateActivity; // millisSinceEpoch of last private chat activity
  encrypt.Encrypter? _encrypter;
  encrypt.IV Function()? _makeIv;
  Timer? _cleanupTimer;

  ChatService() {
    // periodic cleanup every minute
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupOldPrivateMessages(),
    );
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  List<Contact> get contacts => _contacts;
  List<String> get groups => _groups;
  Map<String, List<String>> get groupMembers => _groupMembers;
  List<String> get blockedGroups => _blockedGroups;

  List<String> membersForGroup(String name) => _groupMembers[name] ?? const [];

  // messagesFor is implemented below (returns decrypted copy)

  Future<void> init() async {
    debugPrint('[ChatService] Initializing ChatService...');
    final prefs = await SharedPreferences.getInstance();
    // ensure private key exists
    String? keyB64 = prefs.getString(_privateKeyPref);
    if (keyB64 == null) {
      final keyBytes = encrypt.Key.fromSecureRandom(32).bytes;
      keyB64 = base64Encode(keyBytes);
      await prefs.setString(_privateKeyPref, keyB64);
    }
    final keyBytes = base64Decode(keyB64);
    final key = encrypt.Key(keyBytes);
    // initialize encrypter with real key
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    _makeIv = () => encrypt.IV.fromSecureRandom(16);
    final cJson = prefs.getString(_contactsKey);
    final mJson = prefs.getString(_messagesKey);
    final bJson = prefs.getString(_blockedKey);
    final gJson = prefs.getString(_groupsKey);
    final gmJson = prefs.getString(_groupMembersKey);
    final bgJson = prefs.getString(_blockedGroupsKey);
    final sessionJson = prefs.getString(_privateSessionKey);
    if (cJson != null) {
      final arr = jsonDecode(cJson) as List<dynamic>;
      _contacts = arr
          .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      debugPrint(
        '[ChatService] Loaded contacts: \n${_contacts.map((c) => c.toJson())}',
      );
    } else {
      _contacts = [];
      debugPrint('[ChatService] No contacts found in storage.');
    }
    if (mJson != null) {
      final map = jsonDecode(mJson) as Map<String, dynamic>;
      _messages = map.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((e) => Message.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        ),
      );
    } else {
      _messages = {};
    }
    if (bJson != null) {
      final arr = jsonDecode(bJson) as List<dynamic>;
      _blockedContacts = arr.cast<String>();
    } else {
      _blockedContacts = [];
    }
    if (gJson != null) {
      final arr = jsonDecode(gJson) as List<dynamic>;
      _groups = arr.cast<String>();
    } else {
      _groups = [];
    }
    if (gmJson != null) {
      try {
        final map = jsonDecode(gmJson) as Map<String, dynamic>;
        _groupMembers = map.map(
          (key, value) =>
              MapEntry(key, (value as List<dynamic>).cast<String>()),
        );
      } catch (e) {
        debugPrint('[ChatService] Error loading group members: $e');
        _groupMembers = {};
      }
    } else {
      _groupMembers = {};
    }
    if (bgJson != null) {
      final arr = jsonDecode(bgJson) as List<dynamic>;
      _blockedGroups = arr.cast<String>();
    } else {
      _blockedGroups = [];
    }
    if (sessionJson != null) {
      try {
        _lastPrivateActivity = int.parse(sessionJson);
      } catch (_) {
        _lastPrivateActivity = null;
      }
    } else {
      _lastPrivateActivity = null;
    }
    notifyListeners();
  }

  /// Mark that user interacted with the private chat "session" just now.
  Future<void> markPrivateActivity() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastPrivateActivity = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privateSessionKey, now.toString());
  }

  Future<void> sendMessage(
    String contactId,
    String from,
    String text, {
    bool private = false,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    String storedText = text;
    if (private && _encrypter != null && _makeIv != null) {
      try {
        final iv = _makeIv!();
        final encrypted = _encrypter!.encrypt(text, iv: iv);
        // store iv:cipherText base64
        storedText = '${base64Encode(iv.bytes)}:${encrypted.base64}';
      } catch (e) {
        // fallback to plain text
        storedText = text;
      }
    }
    final msg = Message(
      id: '${contactId}_$ts',
      from: from,
      text: storedText,
      timestamp: ts,
      private: private,
    );
    _messages.putIfAbsent(contactId, () => []).add(msg);
    await _saveMessages();
    notifyListeners();
  }

  /// Helper to compute a stable group conversation id from a group name
  static String groupIdForName(String name) =>
      'chat_${name.toLowerCase().replaceAll(' ', '_')}';

  /// Return decrypted messages copy for read-only use
  List<Message> messagesFor(String contactId) {
    final list = _messages[contactId] ?? [];
    return list.map((m) {
      if (!m.private) return m;
      final parts = m.text.split(':');
      if (parts.length != 2) return m;
      try {
        if (_encrypter == null) {
          return Message(
            id: m.id,
            from: m.from,
            text: '<encrypted>',
            timestamp: m.timestamp,
            private: true,
          );
        }
        final iv = encrypt.IV(base64Decode(parts[0]));
        final enc = encrypt.Encrypted.fromBase64(parts[1]);
        final dec = _encrypter!.decrypt(enc, iv: iv);
        return Message(
          id: m.id,
          from: m.from,
          text: dec,
          timestamp: m.timestamp,
          private: true,
        );
      } catch (e) {
        return Message(
          id: m.id,
          from: m.from,
          text: '<decryption_failed>',
          timestamp: m.timestamp,
          private: true,
        );
      }
    }).toList();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _messages.map(
      (k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()),
    );
    await prefs.setString(_messagesKey, jsonEncode(map));
  }

  Future<void> _cleanupOldPrivateMessages() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    var changed = false;
    for (final key in _messages.keys.toList()) {
      final list = _messages[key]!;
      final before = list.length;
      list.removeWhere((m) => m.private && (now - m.timestamp) > _privateTtlMs);
      if (list.length != before) changed = true;
    }
    if (changed) {
      await _saveMessages();
      notifyListeners();
    }

    // Also enforce a 30-minute private session timeout: if there has been
    // no private activity for more than _privateTtlMs, wipe all private chat.
    final last = _lastPrivateActivity;
    if (last != null && (now - last) > _privateTtlMs) {
      await purgePrivateMessages();
      _lastPrivateActivity = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_privateSessionKey);
    }
  }

  /// Purge all private messages immediately (used when app goes to background/offline)
  Future<void> purgePrivateMessages() async {
    var changed = false;
    for (final key in _messages.keys.toList()) {
      final list = _messages[key]!;
      final before = list.length;
      list.removeWhere((m) => m.private);
      if (list.length != before) changed = true;
    }
    if (changed) {
      await _saveMessages();
      notifyListeners();
    }

    // Reset private session marker when we purge everything.
    _lastPrivateActivity = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privateSessionKey);
  }

  /// Called by lifecycle watcher to purge on leaving app
  void handleAppLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      purgePrivateMessages();
    }
  }

  Future<void> addContact(Contact contact) async {
    debugPrint('[ChatService] Adding contact: ${contact.toJson()}');
    _contacts.add(contact);
    await _saveContacts();
    debugPrint(
      '[ChatService] Contacts after add: \\n${_contacts.map((c) => c.toJson())}',
    );
    notifyListeners();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    // Check available space (approximate, since SharedPreferences is limited)
    // This is a placeholder: in real apps, use platform channels for disk info
    try {
      final contactsJson = jsonEncode(
        _contacts.map((c) => c.toJson()).toList(),
      );
      if (contactsJson.length > 500000) {
        debugPrint(
          '[ChatService] Warning: Contacts data is very large (${contactsJson.length} bytes).',
        );
      }
      await prefs.setString(_contactsKey, contactsJson);
    } catch (e) {
      debugPrint('[ChatService] Error saving contacts: $e');
    }
  }

  Future<void> addGroup(
    String name, {
    List<String> memberIds = const [],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_groups.contains(trimmed)) return;
    _groups.add(trimmed);
    if (memberIds.isNotEmpty) {
      _groupMembers[trimmed] = List<String>.from(memberIds);
      await _saveGroupMembers();
    }
    await _saveGroups();
    notifyListeners();
  }

  Future<void> deleteGroup(String name) async {
    if (_groups.remove(name)) {
      final id = groupIdForName(name);
      _messages.remove(id);
      _groupMembers.remove(name);
      _blockedGroups.remove(name);
      await _saveGroups();
      await _saveGroupMembers();
      await _saveBlockedGroups();
      await _saveMessages();
      notifyListeners();
    }
  }

  Future<void> _saveGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groupsKey, jsonEncode(_groups));
    } catch (e) {
      debugPrint('[ChatService] Error saving groups: $e');
    }
  }

  Future<void> _saveGroupMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groupMembersKey, jsonEncode(_groupMembers));
    } catch (e) {
      debugPrint('[ChatService] Error saving group members: $e');
    }
  }

  Future<void> _saveBlockedGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_blockedGroupsKey, jsonEncode(_blockedGroups));
    } catch (e) {
      debugPrint('[ChatService] Error saving blocked groups: $e');
    }
  }

  Future<void> blockGroup(String name) async {
    final trimmed = name.trim();
    if (!_blockedGroups.contains(trimmed)) {
      _blockedGroups.add(trimmed);
      await _saveBlockedGroups();
      notifyListeners();
    }
  }

  Future<void> unblockGroup(String name) async {
    if (_blockedGroups.remove(name)) {
      await _saveBlockedGroups();
      notifyListeners();
    }
  }
}
