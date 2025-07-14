class Conversation {
  final int id;
  final String subject;
  final String customerEmail;
  final String customerUsername;
  final String status;
  final DateTime updatedAt;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.subject,
    required this.customerEmail,
    required this.customerUsername,
    required this.status,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json["id"],
    subject: json["subject"],
    customerEmail: json["customerEmail"],
    customerUsername: json["customerUsername"],
    status: json["status"],
    updatedAt: DateTime.parse(json["updatedAt"]),
    messages: json["messages"] == null
        ? []
        : List<Message>.from(json["messages"].map((x) => Message.fromJson(x))),
  );
}

class Message {
  final int id;
  final String content;
  final DateTime timestamp;
  final String senderEmail;
  final String senderUsername;
  final String senderRole;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderEmail,
    required this.senderUsername,
    required this.senderRole,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json["id"],
    content: json["content"],
    timestamp: DateTime.parse(json["timestamp"]),
    senderEmail: json["senderEmail"],
    senderUsername: json["senderUsername"],
    senderRole: json["senderRole"],
  );
}