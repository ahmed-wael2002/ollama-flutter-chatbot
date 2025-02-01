class Message {
  final DateTime date;
  final String text;
  final bool isUser;

  Message({required this.date, required this.text, required this.isUser});

  Map<String, String> toChatMessage() {
    return {
      "role": isUser ? "user" : "assistant", // Changed 'system' to 'assistant'
      "content": text,
    };
  }

  factory Message.fromChatMessage(Map<String, dynamic> chatMessage) {
    return Message(
      date: DateTime.now(),
      text: chatMessage["content"] ?? "",
      isUser: chatMessage["role"] == "user",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "role": isUser ? "user" : "assistant",
      "content": text,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      date: DateTime.now(),
      text: json["content"] ?? "",
      isUser: json["role"] == "user",
    );
  }
}
