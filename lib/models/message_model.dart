enum MessageType {
  text,
  image,
  audio,
  video,
  document,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class Message {
  final String id;

  final String senderId;
  final String receiverId;

  final String content;

  final MessageType type;
  final MessageStatus status;

  final DateTime createdAt;

  /// 🔥 FUTURE FEATURES
  final bool isDeleted;
  final bool isEdited;
  final bool isStarred;
  final bool isForwarded;

  /// 🔁 REPLY
  final String? replyToMessageId;

  /// 📎 MEDIA
  final String? mediaUrl;
  final String? thumbnailUrl;

  /// ❤️ REACTION READY
  final Map<String, dynamic>?
  reactions;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,

    this.isDeleted = false,
    this.isEdited = false,
    this.isStarred = false,
    this.isForwarded = false,

    this.replyToMessageId,

    this.mediaUrl,
    this.thumbnailUrl,

    this.reactions,
  });

  /// =====================================
  /// 🔹 FROM JSON
  /// =====================================

  factory Message.fromJson(
      Map<String, dynamic> json,
      ) {
    final id =
    json['id']?.toString();

    if (id == null ||
        id.isEmpty) {
      throw Exception(
        "Invalid message id",
      );
    }

    return Message(
      id: id,

      senderId:
      json['sender_id']
          ?.toString() ??
          '',

      receiverId:
      json['receiver_id']
          ?.toString() ??
          '',

      content:
      (json['content'] ?? '')
          .toString()
          .trim(),

      type: _parseType(
        json['type'],
      ),

      status: _parseStatus(
        json['status'],
      ),

      createdAt: _parseDate(
        json['created_at'],
      ),

      isDeleted:
      json['deleted'] ??
          false,

      isEdited:
      json['is_edited'] ??
          false,

      isStarred:
      json['is_starred'] ??
          false,

      isForwarded:
      json['is_forwarded'] ??
          false,

      replyToMessageId:
      json['reply_to']
          ?.toString(),

      mediaUrl:
      json['media_url']
          ?.toString(),

      thumbnailUrl:
      json['thumbnail_url']
          ?.toString(),

      reactions:
      json['reactions'] !=
          null
          ? Map<String,
          dynamic>.from(
        json['reactions'],
      )
          : null,
    );
  }

  /// =====================================
  /// 🔹 FROM LIST
  /// =====================================

  static List<Message> fromList(
      List<dynamic> data,
      ) {
    try {
      final messages =
      data.map((e) {
        return Message.fromJson(
          Map<String, dynamic>.from(
            e,
          ),
        );
      }).toList();

      /// 🔥 SORT
      messages.sort(
            (a, b) => a.createdAt
            .compareTo(
          b.createdAt,
        ),
      );

      /// 🔥 REMOVE DUPLICATES
      final unique =
      <String, Message>{};

      for (final message
      in messages) {
        unique[message.id] =
            message;
      }

      return unique.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// =====================================
  /// 🔹 TO JSON
  /// =====================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'sender_id': senderId,
      'receiver_id':
      receiverId,

      'content': content,

      'type': type.name,
      'status': status.name,

      'created_at':
      createdAt
          .toIso8601String(),

      'deleted': isDeleted,
      'is_edited': isEdited,
      'is_starred': isStarred,
      'is_forwarded':
      isForwarded,

      'reply_to':
      replyToMessageId,

      'media_url': mediaUrl,
      'thumbnail_url':
      thumbnailUrl,

      'reactions': reactions,
    };
  }

  /// =====================================
  /// 🔹 TYPE PARSER
  /// =====================================

  static MessageType _parseType(
      dynamic value,
      ) {
    switch (value
        .toString()
        .toLowerCase()) {
      case 'image':
        return MessageType.image;

      case 'audio':
        return MessageType.audio;

      case 'video':
        return MessageType.video;

      case 'document':
        return MessageType.document;

      default:
        return MessageType.text;
    }
  }

  /// =====================================
  /// 🔹 STATUS PARSER
  /// =====================================

  static MessageStatus
  _parseStatus(
      dynamic value,
      ) {
    switch (value
        .toString()
        .toLowerCase()) {
      case 'sending':
        return MessageStatus
            .sending;

      case 'delivered':
        return MessageStatus
            .delivered;

      case 'seen':
        return MessageStatus.seen;

      case 'failed':
        return MessageStatus
            .failed;

      default:
        return MessageStatus.sent;
    }
  }

  /// =====================================
  /// 🔹 DATE PARSER
  /// =====================================

  static DateTime _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return DateTime.now();
    }

    try {
      return DateTime.parse(
        value.toString(),
      ).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  /// =====================================
  /// 🔹 HELPERS
  /// =====================================

  bool isMe(
      String currentUserId,
      ) {
    return senderId ==
        currentUserId;
  }

  bool get isSeen =>
      status ==
          MessageStatus.seen;

  bool get isDelivered =>
      status ==
          MessageStatus.delivered;

  bool get isSending =>
      status ==
          MessageStatus.sending;

  bool get isFailed =>
      status ==
          MessageStatus.failed;

  bool get hasMedia =>
      mediaUrl != null &&
          mediaUrl!.isNotEmpty;

  bool get isReply =>
      replyToMessageId != null;

  bool get hasReactions =>
      reactions != null &&
          reactions!.isNotEmpty;

  /// =====================================
  /// 🕒 FORMATTED TIME
  /// =====================================

  String get formattedTime {
    final hour =
    createdAt.hour > 12
        ? createdAt.hour - 12
        : createdAt.hour;

    final minute = createdAt
        .minute
        .toString()
        .padLeft(2, '0');

    final period =
    createdAt.hour >= 12
        ? 'PM'
        : 'AM';

    return '$hour:$minute $period';
  }

  /// =====================================
  /// 🔹 COPY WITH
  /// =====================================

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,

    MessageType? type,
    MessageStatus? status,

    DateTime? createdAt,

    bool? isDeleted,
    bool? isEdited,
    bool? isStarred,
    bool? isForwarded,

    String? replyToMessageId,

    String? mediaUrl,
    String? thumbnailUrl,

    Map<String, dynamic>?
    reactions,
  }) {
    return Message(
      id: id ?? this.id,

      senderId:
      senderId ??
          this.senderId,

      receiverId:
      receiverId ??
          this.receiverId,

      content:
      content ??
          this.content,

      type: type ?? this.type,

      status:
      status ?? this.status,

      createdAt:
      createdAt ??
          this.createdAt,

      isDeleted:
      isDeleted ??
          this.isDeleted,

      isEdited:
      isEdited ??
          this.isEdited,

      isStarred:
      isStarred ??
          this.isStarred,

      isForwarded:
      isForwarded ??
          this.isForwarded,

      replyToMessageId:
      replyToMessageId ??
          this
              .replyToMessageId,

      mediaUrl:
      mediaUrl ??
          this.mediaUrl,

      thumbnailUrl:
      thumbnailUrl ??
          this.thumbnailUrl,

      reactions:
      reactions ??
          this.reactions,
    );
  }

  /// =====================================
  /// 🔹 DEBUG
  /// =====================================

  @override
  String toString() {
    return '''
Message(
  id: $id,
  sender: $senderId,
  receiver: $receiverId,
  content: $content,
  type: ${type.name},
  status: ${status.name},
  createdAt: $createdAt
)
''';
  }

  /// =====================================
  /// 🔹 EQUALITY
  /// =====================================

  @override
  bool operator ==(
      Object other,
      ) {
    return identical(
      this,
      other,
    ) ||
        (other is Message &&
            other.id == id);
  }

  @override
  int get hashCode =>
      id.hashCode;
}