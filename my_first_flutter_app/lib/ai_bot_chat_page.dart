import 'package:flutter/material.dart';

class AIBotChatPage extends StatefulWidget {
  const AIBotChatPage({super.key});

  @override
  State<AIBotChatPage> createState() => _AIBotChatPageState();
}

class _AIBotChatPageState extends State<AIBotChatPage> {
  // REVERT: simple single-thread chat, no groups
  final List<_BotMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_BotMessage(text, true));
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(_BotMessage(_generateBotReply(text), false));
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  String _generateBotReply(String message) {
    // ...existing code (help / hello / reverse reply)...
    if (message.toLowerCase().contains('help')) return 'How can I assist you today?';
    if (message.toLowerCase().contains('hello') || message.toLowerCase().contains('hi')) return 'Hello! I am your AI bot.';
    return 'AI: ${message.split('').reversed.join()}';
  }

  void _scrollToBottom() {
    // ...existing code...
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
    // ...AppBar and Scaffold setup unchanged...
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Row(
          children: const [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, color: Colors.deepPurple),
            ),
            SizedBox(width: 12),
            Text(
              'AI Bot',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF181A20),
      body: Column(
        children: [
          // REVERT: remove group selector, keep only chat list
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF181A20), Color(0xFF23272F)],
                ),
              ),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isMe = m.isUser;
                  return Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.smart_toy,
                            color: Colors.deepPurple,
                            size: 18,
                          ),
                        ),
                      if (!isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.deepPurple : Colors.white10,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isMe) const SizedBox(width: 8),
                      if (isMe)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.deepPurple,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          // existing input area (TextField + send button) unchanged
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF23272F),
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask the AI bot... ',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotMessage {
  final String text;
  final bool isUser;
  _BotMessage(this.text, this.isUser);
}
