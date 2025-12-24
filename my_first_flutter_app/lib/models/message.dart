class Message {
  final String id;
  final String from;
  final String text;
  final int timestamp;
  final bool private;

  Message({required this.id, required this.from, required this.text, required this.timestamp, this.private = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'text': text,
        'timestamp': timestamp,
        'private': private,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        from: j['from'] as String,
        text: j['text'] as String,
        timestamp: j['timestamp'] as int,
        private: (j['private'] ?? false) as bool,
      );
}
