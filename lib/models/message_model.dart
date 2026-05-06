enum MessageType { text, image, audio }
enum MessageStatus { sent, delivered, seen }

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  /// 🔹 FROM SUPABASE
  factory Message.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();

    if (id == null || id.isEmpty) {
      throw Exception("Invalid message id");
    }

    return Message(
      id: id,
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: (json['content'] ?? '').toString().trim(),
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  /// 🔹 LIST PARSE
  static List<Message> fromList(List<dynamic> data) {
    return data
        .map((e) => Message.fromJson(
      Map<String, dynamic>.from(e),
    ))
        .toList();
  }

  /// 🔹 TO SUPABASE
  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content.trim(),
      'type': type.name,
      'status': status.name,
    };
  }

  /// 🔹 TYPE PARSER
  static MessageType _parseType(dynamic value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  /// 🔹 STATUS PARSER
  static MessageStatus _parseStatus(dynamic value) {
    switch (value) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'seen':
        return MessageStatus.seen;
      default:
        return MessageStatus.sent;
    }
  }

  /// 🔹 DATE PARSER
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  /// 🔹 HELPERS
  bool isMe(String currentUserId) => senderId == currentUserId;

  bool get isSeen => status == MessageStatus.seen;
  bool get isDelivered => status == MessageStatus.delivered;

  /// 🔹 COPY
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 🔹 DEBUG
  @override
  String toString() {
    return 'Message(id: $id, type: ${type.name}, status: ${status.name}, content: $content)';
  }

  /// 🔹 EQUALITY
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is Message && other.id == id);

  @override
  int get hashCode => id.hashCode;
}