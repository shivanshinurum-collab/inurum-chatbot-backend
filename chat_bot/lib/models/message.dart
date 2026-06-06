class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  factory Message.user(String text) {
    return Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory Message.agent(String text) {
    return Message(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
