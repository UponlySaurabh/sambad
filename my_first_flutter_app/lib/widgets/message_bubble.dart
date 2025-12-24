import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final bg = isMe ? Colors.white : Colors.white24;
    final textColor = isMe ? Colors.black87 : Colors.white;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: isMe
                ? BorderRadius.only(topLeft: radius.topLeft, topRight: radius.topRight, bottomLeft: radius.bottomLeft)
                : BorderRadius.only(topLeft: radius.topLeft, topRight: radius.topRight, bottomRight: radius.bottomRight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.private)
                    const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Icon(Icons.lock, size: 14, color: Colors.white70),
                    ),
                  Flexible(child: Text(message.text, style: TextStyle(color: textColor))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatTime(message.timestamp), style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
