import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/chat_service.dart';
import 'models/message.dart';
import 'widgets/message_bubble.dart';
import 'package:image_picker/image_picker.dart';

// NEW: Home page with groups
class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatGroupCreateResult {
  final String name;
  final List<String> memberIds;

  _ChatGroupCreateResult({required this.name, required this.memberIds});
}

class _ChatHomePageState extends State<ChatHomePage> {
  Future<void> _createGroup() async {
    final svc = context.read<ChatService>();
    final contacts = svc.contacts;
    final nameController = TextEditingController();
    final Set<String> selectedIds = <String>{};

    final _ChatGroupCreateResult?
    result = await showDialog<_ChatGroupCreateResult>(
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
                  _ChatGroupCreateResult(
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
    if (result != null && result.name.trim().isNotEmpty) {
      await svc.addGroup(result.name.trim(), memberIds: result.memberIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Create group',
            onPressed: _createGroup,
          ),
        ],
      ),
      body: Consumer<ChatService>(
        builder: (context, svc, _) {
          final groups = svc.groups
              .where((g) => !svc.blockedGroups.contains(g))
              .toList();
          if (groups.isEmpty) {
            return const Center(
              child: Text('No groups yet. Tap + to create one.'),
            );
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final groupName = groups[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group)),
                title: Text(groupName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatPage(name: groupName, isPrivate: false),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;
  final bool isPrivate;
  final VoidCallback? onCall;

  const ChatPage({
    super.key,
    required this.name,
    this.isPrivate = false,
    this.onCall,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<void> _pickAndSendImage({bool fromCamera = false}) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (image != null) {
        final svc = context.read<ChatService>();
        await svc.sendMessage(
          _contactId,
          'me',
          '[Image] ${image.path}',
          private: widget.isPrivate,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image sharing failed.')));
    }
  }

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  String get _contactId => widget.isPrivate
      ? ChatService.privateConversationId
      : ChatService.groupIdForName(widget.name);

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final svc = context.read<ChatService>();
    await svc.sendMessage(
      _contactId,
      'me',
      text,
      private: widget.isPrivate, // was: private: false
    );
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      final reply = _generateBotReply(text);
      await svc.sendMessage(
        _contactId,
        'bot',
        reply,
        private: widget.isPrivate, // was: private: false
      );
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  String _generateBotReply(String message) {
    if (message.toLowerCase().contains('how') && message.contains('?')) {
      return 'I am doing well — thanks for asking!';
    }
    if (message.toLowerCase().contains('hi') ||
        message.toLowerCase().contains('hello')) {
      return 'Hi there! How can I help?';
    }
    return 'AI reply: ${message.split('').reversed.join()}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ChatService>();
    final messages = svc.messagesFor(_contactId);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Text(widget.name, style: const TextStyle(color: Colors.white)),
            if (widget.isPrivate && widget.onCall != null) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.call, color: Colors.greenAccent),
                tooltip: 'Call',
                onPressed: widget.onCall,
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.isPrivate)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                final svc = context.read<ChatService>();
                final groupName = widget.name;
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF23272F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Delete group',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Are you sure you want to delete "$groupName" for this device? All its messages will be removed.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await svc.deleteGroup(groupName);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  }
                } else if (value == 'exit') {
                  await svc.blockGroup(groupName);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You exited "$groupName".')),
                  );
                  Navigator.of(context).pop();
                } else if (value == 'block') {
                  await svc.blockGroup(groupName);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You blocked "$groupName". It will be hidden.',
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete group')),
                PopupMenuItem(value: 'exit', child: Text('Exit group')),
                PopupMenuItem(value: 'block', child: Text('Block group')),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF000000), Color(0xFF2B2B2B)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12), // Padding from top
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final Message m = messages[i];
                      final isMe = m.from == 'me';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: MessageBubble(message: m, isMe: isMe),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                  ), // More space from bottom
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: Colors.black54,
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              // Pick image from gallery
                              await _pickAndSendImage(fromCamera: false);
                            },
                            icon: const Icon(Icons.photo, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () async {
                              // Capture image from camera
                              await _pickAndSendImage(fromCamera: true);
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                filled: true,
                                fillColor: Colors.white12,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: 'chat_send_fab',
                            onPressed: _send,
                            mini: true,
                            backgroundColor: Colors.white,
                            child: const Icon(
                              Icons.send,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Arrow button to scroll to bottom
          Positioned(
            right: 16,
            bottom: 90,
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, child) {
                final showArrow =
                    _scroll.hasClients &&
                    _scroll.offset < _scroll.position.maxScrollExtent - 100;
                return showArrow
                    ? FloatingActionButton(
                        heroTag: 'chat_scroll_fab',
                        mini: true,
                        backgroundColor: Colors.deepPurple,
                        onPressed: _scrollToBottom,
                        tooltip: 'Jump to latest',
                        elevation: 2,
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
