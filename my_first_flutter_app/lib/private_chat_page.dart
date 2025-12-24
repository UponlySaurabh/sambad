import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/message.dart';
import 'services/chat_service.dart';
import 'widgets/message_bubble.dart';

class PrivateChatPage extends StatefulWidget {
  const PrivateChatPage({super.key});

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Opening the private chat counts as session activity.
    // This helps enforce the 30-minute private session timeout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatService>().markPrivateActivity();
      }
    });
  }

  Future<void> _startCall({required bool video}) async {
    // Use a free Jitsi Meet room as a demo call backend.
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

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final svc = context.read<ChatService>();
    await svc.markPrivateActivity();
    await svc.sendMessage(
      ChatService.privateConversationId,
      'me',
      text,
      private: true,
    );
    _ctrl.clear();
    // simple AI bot reply after a delay
    Future.delayed(const Duration(milliseconds: 800), () async {
      final reply = _generateBotReply(text);
      await svc.markPrivateActivity();
      await svc.sendMessage(
        ChatService.privateConversationId,
        'bot',
        reply,
        private: true,
      );
    });
    _scrollToBottom();
  }

  String _generateBotReply(String message) {
    // simple rule-based reply for demo purposes
    if (message.toLowerCase().contains('hi') ||
        message.toLowerCase().contains('hello')) {
      return 'Hello — I am your private assistant.';
    }
    if (message.endsWith('?')) {
      return 'Good question — I will remember that privately.';
    }
    return 'I heard you: "$message"';
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
    final messages = svc.messagesFor(ChatService.privateConversationId);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final Message m = messages[i];
              final isMe = m.from == 'me';
              return MessageBubble(message: m, isMe: isMe);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.black54,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.lock, color: Colors.white),
                  tooltip: 'Private & encrypted',
                ),
                IconButton(
                  onPressed: () => _startCall(video: false),
                  icon: const Icon(Icons.call, color: Colors.greenAccent),
                  tooltip: 'Private call',
                ),
                IconButton(
                  onPressed: () => _startCall(video: true),
                  icon: const Icon(
                    Icons.videocam,
                    color: Colors.lightBlueAccent,
                  ),
                  tooltip: 'Private video call',
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a private message',
                      hintStyle: const TextStyle(color: Colors.white54),
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
                  heroTag: 'private_send_fab',
                  onPressed: _send,
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.send, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
