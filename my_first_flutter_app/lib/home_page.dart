import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';
import 'models/contact.dart';
import 'widgets/contact_tile.dart';
import 'widgets/right_sidebar.dart';
import 'services/chat_service.dart';
import 'ai_bot_chat_page.dart';
import 'profile_section_page.dart';
import 'package:share_plus/share_plus.dart';
import 'add_contact_dialog.dart';
import 'phonebook_permission_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomeGroupCreateResult {
  final String name;
  final List<String> memberIds;

  _HomeGroupCreateResult({required this.name, required this.memberIds});
}

class _HomePageState extends State<HomePage> {
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  Contact? _selectedContact;
  String _searchQuery = '';
  String? _profileName;
  // Removed unused fields _profilePhone and _loadingProfile

  Future<void> _startSidebarCall({required bool video}) async {
    // Use the same free Jitsi backend as private chat for demo.
    const room = 'sambad-private-room';
    final uri = Uri.parse(
      video
          ? 'https://meet.jit.si/$room'
          : 'https://meet.jit.si/$room#config.startWithVideoMuted=true',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start call right now.')),
      );
    }
  }

  Future<void> _createGroup(BuildContext context) async {
    final svc = context.read<ChatService>();
    final contacts = svc.contacts;
    final nameController = TextEditingController();
    final Set<String> selectedIds = <String>{};

    final _HomeGroupCreateResult?
    result = await showDialog<_HomeGroupCreateResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23272F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Create group',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (ctx, setInnerState) {
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select members',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedIds.isEmpty
                          ? 'No members selected'
                          : '${selectedIds.length} member(s) selected',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: contacts.isEmpty
                          ? const Center(
                              child: Text(
                                'You have no contacts yet. Add some to create a group.',
                                style: TextStyle(color: Colors.white60),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                final bool selected = selectedIds.contains(
                                  contact.id,
                                );
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (val) {
                                    setInnerState(() {
                                      if (val == true) {
                                        selectedIds.add(contact.id);
                                      } else {
                                        selectedIds.remove(contact.id);
                                      }
                                    });
                                  },
                                  activeColor: Colors.deepPurple,
                                  checkColor: Colors.white,
                                  title: Text(
                                    contact.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    contact.phone,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop(
                  _HomeGroupCreateResult(
                    name: name,
                    memberIds: selectedIds.toList(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Create',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (!context.mounted) return;
    if (result != null && result.name.trim().isNotEmpty) {
      await svc.addGroup(result.name.trim(), memberIds: result.memberIds);
    }
  }

  Widget highlightText(String text) {
    if (_searchQuery.isEmpty) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }
    final lcText = text.toLowerCase();
    final lcQuery = _searchQuery.toLowerCase();
    final start = lcText.indexOf(lcQuery);
    if (start < 0) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }
    final end = start + lcQuery.length;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, start),
            style: const TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(end),
            style: const TextStyle(color: Colors.white),
          ),
        ],
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Removed: setState(() => _loadingProfile = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) {
        return;
      }
      final uri = Uri.parse('http://10.0.2.2:3000/me');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data != null && data['success'] == true && data['user'] != null) {
          final user = data['user'];
          if (!mounted) return;
          setState(() {
            _profileName = user['name'] as String?;
            // Removed: _profilePhone assignment
          });
          return;
        }
      }
      await prefs.remove('jwt');
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
    // Removed: setState(() => _loadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSectionPage()),
            );
          },
        ),
        title: const Text(
          'Sambad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          SizedBox(
            width: 220,
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                if (_searchQuery.length >= 3 && _searchFocus.hasFocus)
                  Consumer<ChatService>(
                    builder: (context, svc, _) {
                      final allContacts = svc.contacts;
                      final matches = allContacts
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                c.phone.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();
                      if (matches.isEmpty) return const SizedBox();
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: 48,
                        child: Material(
                          color: const Color(0xFF23272F),
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: matches.length,
                            itemBuilder: (context, idx) {
                              final c = matches[idx];
                              return ListTile(
                                title: highlightText(c.name),
                                subtitle: highlightText(c.phone),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Contact',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF23272F,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: const Text(
                                          'Delete Contact',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete ${c.name}?',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      if (!context.mounted) return;
                                      final svc = context.read<ChatService>();
                                      await svc.deleteContact(c.id);
                                      if (_selectedContact?.id == c.id) {
                                        setState(() {
                                          _selectedContact = null;
                                          _currentIndex = 0;
                                        });
                                      }
                                    }
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    _currentIndex = 2;
                                    _selectedContact = c;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                  _searchFocus.unfocus();
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          final Widget mainContent = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                  child: Text(
                    _profileName != null && _profileName!.trim().isNotEmpty
                        ? 'Hey ${_profileName!}, you are doing awesome!'
                        : 'Hey there, you are doing awesome!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_currentIndex == 0) {
                        return Consumer<ChatService>(
                          builder: (context, svc, _) {
                            final allContacts = svc.contacts;
                            final contacts = _searchQuery.isEmpty
                                ? allContacts
                                : allContacts
                                      .where(
                                        (c) =>
                                            c.name.toLowerCase().contains(
                                              _searchQuery.toLowerCase(),
                                            ) ||
                                            c.phone.toLowerCase().contains(
                                              _searchQuery.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                            final groups = svc.groups
                                .where((g) => !svc.blockedGroups.contains(g))
                                .toList();

                            Widget buildContactsSection() {
                              if (allContacts.isEmpty) {
                                return Center(
                                  child: Card(
                                    color: const Color(0xFF23272F),
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0,
                                        vertical: 36,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.share,
                                                color: Colors.deepPurple,
                                                size: 32,
                                              ),
                                              SizedBox(width: 16),
                                              Icon(
                                                Icons.person_add,
                                                color: Colors.deepPurple,
                                                size: 32,
                                              ),
                                              SizedBox(width: 16),
                                              Icon(
                                                Icons.import_contacts,
                                                color: Colors.deepPurple,
                                                size: 32,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 28),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await Share.share(
                                                'Join me on Sambad! Download the app and chat with me.',
                                              );
                                            },
                                            icon: const Icon(Icons.share),
                                            label: const Text(
                                              'Share Link to Invite Friends',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurple,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) =>
                                                    AddContactDialog(
                                                      onAdd: (contact) async {
                                                        final svc = context
                                                            .read<
                                                              ChatService
                                                            >();
                                                        await svc.addContact(
                                                          contact,
                                                        );
                                                        setState(() {
                                                          _currentIndex = 0;
                                                          _selectedContact =
                                                              contact;
                                                        });
                                                      },
                                                    ),
                                              );
                                            },
                                            icon: const Icon(Icons.person_add),
                                            label: const Text('Add Contact'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.deepPurple,
                                              side: const BorderSide(
                                                color: Colors.deepPurple,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) =>
                                                    PhonebookPermissionDialog(
                                                      onAllow: () {
                                                        Navigator.of(ctx).pop();
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Phonebook extraction not implemented.',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      onDeny: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                    ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.import_contacts,
                                            ),
                                            label: const Text(
                                              'Extract Phone Book (with consent)',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.deepPurple,
                                              side: const BorderSide(
                                                color: Colors.deepPurple,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                itemCount: contacts.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      color: Colors.white12,
                                      indent: 72,
                                      endIndent: 16,
                                      height: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final Contact c = contacts[index];
                                  final bool unread = index % 4 == 0;
                                  return ContactTile(
                                    contact: c,
                                    onTap: () {
                                      setState(() {
                                        _currentIndex = 2;
                                        _selectedContact = c;
                                      });
                                    },
                                    unreadCount: unread ? 1 : 0,
                                  );
                                },
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Groups',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _createGroup(context),
                                        icon: const Icon(
                                          Icons.group_add,
                                          color: Colors.deepPurple,
                                        ),
                                        label: const Text(
                                          'New group',
                                          style: TextStyle(
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 54,
                                  child: groups.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'No groups yet. Create one to start a group chat.',
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          itemBuilder: (ctx, i) {
                                            final String name = groups[i];
                                            return ActionChip(
                                              label: Text(
                                                name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: const Color(
                                                0xFF23272F,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _currentIndex = 2;
                                                  _selectedContact = null;
                                                });
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatPage(
                                                      name: name,
                                                      isPrivate: false,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          separatorBuilder: (_, i) =>
                                              const SizedBox(width: 8),
                                          itemCount: groups.length,
                                        ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: Text(
                                    'Contacts',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(child: buildContactsSection()),
                              ],
                            );
                          },
                        );
                      } else if (_currentIndex == 1) {
                        return Container(color: const Color(0xFF181A20));
                      } else if (_currentIndex == 2) {
                        final bool isPrivate = _selectedContact == null;
                        final String chatName = isPrivate
                            ? 'Private'
                            : _selectedContact!.name;
                        return ChatPage(
                          name: chatName,
                          isPrivate: isPrivate,
                          onCall: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Call feature coming soon!'),
                              ),
                            );
                          },
                        );
                      } else if (_currentIndex == 3) {
                        return const AIBotChatPage();
                      } else {
                        return Container(color: const Color(0xFF181A20));
                      }
                    },
                  ),
                ),
              ],
            ),
          );

          final Widget sidebar = RightSidebar(
            onAddContact: () {
              showDialog(
                context: context,
                builder: (ctx) => AddContactDialog(
                  onAdd: (contact) async {
                    final svc = context.read<ChatService>();
                    await svc.addContact(contact);
                    setState(() {
                      _currentIndex = 0;
                      _selectedContact = contact;
                    });
                  },
                ),
              );
            },
            onInvite: () async {
              await Share.share(
                'Join me on Sambad! Download the app and chat with me.',
              );
            },
            onCall: (_currentIndex == 2 && _selectedContact != null)
                ? () => _startSidebarCall(video: false)
                : null,
            onVideoCall: (_currentIndex == 2 && _selectedContact != null)
                ? () => _startSidebarCall(video: true)
                : null,
            showCall: (_currentIndex == 2 && _selectedContact != null),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: mainContent),
                const SizedBox(width: 8),
                sidebar,
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: mainContent),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: 80, child: sidebar),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        heroTag: 'home_private_fab',
        onPressed: () => setState(() => _currentIndex = 2),
        tooltip: 'Private Chat',
        child: const Icon(Icons.lock, color: Colors.black87),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black87,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => _currentIndex = 0),
                  icon: Icon(
                    Icons.home,
                    color: _currentIndex == 0 ? Colors.white : Colors.white70,
                  ),
                  tooltip: 'Contacts',
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: Icon(
                    Icons.settings,
                    color: _currentIndex == 1 ? Colors.white : Colors.white70,
                  ),
                  tooltip: 'Settings',
                ),
              ),
              const Expanded(child: SizedBox()), // space for FAB
              Expanded(
                child: IconButton(
                  onPressed: () => setState(() => _currentIndex = 3),
                  icon: Icon(
                    Icons.smart_toy,
                    color: _currentIndex == 3 ? Colors.white : Colors.white70,
                  ),
                  tooltip: 'AI Bot',
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}
