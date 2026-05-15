enum MessageType {
  text,
  image,
  audio,
  video,
  document,

  // Calls
  call,
  videoCall,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
  failed,
}

class Message {
  // =========================================================
  // BASIC FIELDS
  // =========================================================

  final String id;
  final String senderId;
  final String receiverId;
  final String content;

  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;

  // =========================================================
  // MEDIA
  // =========================================================

  final String? mediaUrl;
  final String? originalFileName;
  final String? mimeType;
  final String? thumbnailUrl;

  // =========================================================
  // FLAGS
  // =========================================================

  final bool isDeleted;
  final bool isEdited;
  final bool isStarred;
  final bool isForwarded;

  // =========================================================
  // REPLY / REACTIONS
  // =========================================================

  final String? replyToMessageId;
  final Map<String, dynamic>? reactions;

  // =========================================================
  // CALL FIELDS
  // =========================================================

  final String? callStatus; // completed / missed / rejected
  final int? callDuration; // seconds

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.mediaUrl,
    this.originalFileName,
    this.mimeType,
    this.thumbnailUrl,
    this.isDeleted = false,
    this.isEdited = false,
    this.isStarred = false,
    this.isForwarded = false,
    this.replyToMessageId,
    this.reactions,
    this.callStatus,
    this.callDuration,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory Message.fromJson(
      Map<String, dynamic> json,
      ) {
    final id =
        json['id']?.toString() ??
            DateTime.now()
                .millisecondsSinceEpoch
                .toString();

    final content =
        _cleanString(
          json['content'],
        ) ??
            '';

    // Accept both file_url and media_url
    final fileUrl =
    _cleanString(json['file_url']);
    final mediaUrl =
    _cleanString(json['media_url']);
    final resolvedMediaUrl =
        fileUrl ?? mediaUrl;

    final fileName =
    _cleanString(json['file_name']);
    final mimeType =
    _cleanString(json['mime_type']);

    final messageType =
    _parseType(
      json['type'] ??
          json['message_type'],
      mimeType: mimeType,
      source:
      resolvedMediaUrl ??
          content,
    );

    final messageStatus =
    _parseStatus(
      json['status'],
      isSeen:
      json['is_seen'] == true,
    );

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
      content: content.isNotEmpty
          ? content
          : (fileName ?? ''),
      type: messageType,
      status: messageStatus,
      createdAt: _parseDate(
        json['created_at'],
      ),
      mediaUrl:
      resolvedMediaUrl,
      originalFileName:
      fileName,
      mimeType: mimeType,
      thumbnailUrl:
      _cleanString(
        json['thumbnail_url'],
      ),
      isDeleted:
      json['deleted'] ==
          true,
      isEdited:
      json['is_edited'] ==
          true,
      isStarred:
      json['is_starred'] ==
          true,
      isForwarded:
      json['is_forwarded'] ==
          true,
      replyToMessageId:
      _cleanString(
        json['reply_to'],
      ),
      reactions:
      json['reactions'] !=
          null
          ? Map<String,
          dynamic>.from(
        json['reactions'],
      )
          : null,
      callStatus:
      _cleanString(
        json['call_status'],
      ),
      callDuration:
      _parseInt(
        json['call_duration'],
      ),
    );
  }

  // =========================================================
  // FROM LIST
  // =========================================================

  static List<Message> fromList(
      List<dynamic> data,
      ) {
    try {
      final messages =
      data
          .map(
            (item) =>
            Message.fromJson(
              Map<String,
                  dynamic>.from(
                item,
              ),
            ),
      )
          .toList();

      // Remove duplicates by id
      final unique =
      <String, Message>{};

      for (final message
      in messages) {
        unique[message.id] =
            message;
      }

      final result =
      unique.values.toList();

      // Sort oldest -> newest
      result.sort(
            (a, b) => a.createdAt
            .compareTo(
          b.createdAt,
        ),
      );

      return result;
    } catch (_) {
      return [];
    }
  }

  // =========================================================
  // TO JSON
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'type': typeDbValue,
      'message_type':
      typeDbValue,
      'status': status.name,
      'created_at': createdAt
          .toUtc()
          .toIso8601String(),
      'file_url': mediaUrl,
      'media_url': mediaUrl,
      'file_name':
      originalFileName,
      'mime_type': mimeType,
      'thumbnail_url':
      thumbnailUrl,
      'deleted': isDeleted,
      'is_edited': isEdited,
      'is_starred': isStarred,
      'is_forwarded':
      isForwarded,
      'reply_to':
      replyToMessageId,
      'reactions': reactions,
      'call_status':
      callStatus,
      'call_duration':
      callDuration,
    };
  }

  // =========================================================
  // DATABASE TYPE VALUE
  // =========================================================

  String get typeDbValue {
    switch (type) {
      case MessageType.videoCall:
        return 'video_call';
      case MessageType.call:
        return 'call';
      default:
        return type.name;
    }
  }

  // =========================================================
  // BASIC GETTERS
  // =========================================================

  bool isMe(
      String currentUserId,
      ) {
    return senderId ==
        currentUserId;
  }

  bool get isText =>
      type == MessageType.text;

  bool get isImage =>
      type == MessageType.image;

  bool get isAudio =>
      type == MessageType.audio;

  bool get isVideo =>
      type == MessageType.video;

  bool get isDocument =>
      type ==
          MessageType.document;

  bool get isCall =>
      type == MessageType.call;

  bool get isVideoCall =>
      type ==
          MessageType.videoCall;

  bool get isAnyCall =>
      isCall || isVideoCall;

  bool get isVoiceMessage =>
      isAudio &&
          (mimeType
              ?.toLowerCase()
              .contains('audio') ??
              false);

  bool get isMissedCall =>
      callStatus == 'missed';

  bool get isSeen =>
      status ==
          MessageStatus.seen;

  bool get isDelivered =>
      status ==
          MessageStatus
              .delivered ||
          status ==
              MessageStatus.seen;

  bool get isSending =>
      status ==
          MessageStatus.sending;

  bool get isFailed =>
      status ==
          MessageStatus.failed;

  bool get hasMedia =>
      mediaUrl != null &&
          mediaUrl!
              .trim()
              .isNotEmpty;

  String get resolvedUrl =>
      mediaUrl ?? content;

  String get fileUrl =>
      resolvedUrl;

  // =========================================================
  // FILE NAME
  // =========================================================

  String get fileName {
    if (originalFileName !=
        null &&
        originalFileName!
            .trim()
            .isNotEmpty) {
      return originalFileName!;
    }

    if (content.isNotEmpty &&
        !content.startsWith(
          'http://',
        ) &&
        !content.startsWith(
          'https://',
        )) {
      return content;
    }

    try {
      final uri = Uri.parse(
        resolvedUrl,
      );

      if (uri.pathSegments
          .isEmpty) {
        return 'file';
      }

      return Uri.decodeComponent(
        uri.pathSegments.last,
      );
    } catch (_) {
      return 'file';
    }
  }

  // =========================================================
  // LINK CHECK
  // =========================================================

  bool get isLink {
    final value =
    content.trim();

    final isHttp =
        value.startsWith(
          'http://',
        ) ||
            value.startsWith(
              'https://',
            );

    if (!isHttp) {
      return false;
    }

    if (isImage ||
        isAudio ||
        isVideo ||
        isDocument ||
        isAnyCall) {
      return false;
    }

    return true;
  }

  // =========================================================
  // FORMATTED TIME
  // =========================================================

  String get formattedTime {
    int hour =
        createdAt.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

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

  // =========================================================
  // CALL DESCRIPTION
  // =========================================================

  String callDescription(
      String currentUserId,
      ) {
    final outgoing =
    isMe(currentUserId);
    final video =
        isVideoCall;

    if (isMissedCall) {
      return video
          ? 'Missed video call'
          : 'Missed voice call';
    }

    if (callStatus ==
        'rejected') {
      return video
          ? 'Rejected video call'
          : 'Rejected voice call';
    }

    if (outgoing) {
      return video
          ? 'You started a video call'
          : 'You started a voice call';
    }

    return video
        ? 'Incoming video call'
        : 'Incoming voice call';
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    String? mediaUrl,
    String? originalFileName,
    String? mimeType,
    String? thumbnailUrl,
    bool? isDeleted,
    bool? isEdited,
    bool? isStarred,
    bool? isForwarded,
    String? replyToMessageId,
    Map<String, dynamic>?
    reactions,
    String? callStatus,
    int? callDuration,
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
      status ??
          this.status,
      createdAt:
      createdAt ??
          this.createdAt,
      mediaUrl:
      mediaUrl ??
          this.mediaUrl,
      originalFileName:
      originalFileName ??
          this
              .originalFileName,
      mimeType:
      mimeType ??
          this.mimeType,
      thumbnailUrl:
      thumbnailUrl ??
          this.thumbnailUrl,
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
      reactions:
      reactions ??
          this.reactions,
      callStatus:
      callStatus ??
          this.callStatus,
      callDuration:
      callDuration ??
          this.callDuration,
    );
  }

  // =========================================================
  // TYPE PARSER
  // =========================================================

  static MessageType _parseType(
      dynamic value, {
        String? mimeType,
        required String source,
      }) {
    final type =
        value
            ?.toString()
            .toLowerCase()
            .trim() ??
            '';

    switch (type) {
      case 'call':
      case 'voice_call':
        return MessageType.call;

      case 'video_call':
        return MessageType.videoCall;

      case 'image':
        return MessageType.image;

      case 'audio':
      case 'voice':
        return MessageType.audio;

      case 'video':
        return MessageType.video;

      case 'document':
      case 'file':
        return MessageType.document;
    }

    final mime =
        mimeType
            ?.toLowerCase() ??
            '';

    if (mime.startsWith(
      'image/',
    )) {
      return MessageType.image;
    }

    if (mime.startsWith(
      'audio/',
    )) {
      return MessageType.audio;
    }

    if (mime.startsWith(
      'video/',
    )) {
      return MessageType.video;
    }

    if (mime.isNotEmpty) {
      return MessageType.document;
    }

    final ext =
    _extractExtension(source);

    const imageExt = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    };

    const audioExt = {
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'opus',
      'flac',
      'webm',
    };

    const videoExt = {
      'mp4',
      'mov',
      'avi',
      'mkv',
      '3gp',
      'webm',
    };

    const documentExt = {
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'xls',
      'xlsx',
      'txt',
      'csv',
      'json',
      'xml',
      'zip',
      'rar',
      '7z',
      'apk',
    };

    if (imageExt.contains(ext)) {
      return MessageType.image;
    }

    if (audioExt.contains(ext)) {
      return MessageType.audio;
    }

    if (videoExt.contains(ext)) {
      return MessageType.video;
    }

    if (documentExt.contains(ext)) {
      return MessageType.document;
    }

    return MessageType.text;
  }

  // =========================================================
  // STATUS PARSER
  // =========================================================

  static MessageStatus _parseStatus(
      dynamic value, {
        bool isSeen = false,
      }) {
    if (isSeen) {
      return MessageStatus.seen;
    }

    switch (value
        ?.toString()
        .toLowerCase()) {
      case 'sending':
        return MessageStatus
            .sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus
            .delivered;
      case 'seen':
      case 'read':
        return MessageStatus.seen;
      case 'failed':
        return MessageStatus
            .failed;
      default:
        return MessageStatus.sent;
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

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

  static String? _cleanString(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return null;
    }

    return text;
  }

  static int? _parseInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static String _extractExtension(
      String value,
      ) {
    try {
      final uri = Uri.parse(value);
      final path =
      uri.path.toLowerCase();

      if (!path.contains('.')) {
        return '';
      }

      return path
          .split('.')
          .last;
    } catch (_) {
      final lower =
      value.toLowerCase();

      if (!lower.contains('.')) {
        return '';
      }

      return lower
          .split('.')
          .last;
    }
  }

  // =========================================================
  // OVERRIDES
  // =========================================================

  @override
  bool operator ==(
      Object other,
      ) {
    return identical(
      this,
      other,
    ) ||
        other is Message &&
            other.id == id;
  }

  @override
  int get hashCode =>
      id.hashCode;

  @override
  String toString() {
    return '''
Message(
  id: $id,
  senderId: $senderId,
  receiverId: $receiverId,
  content: $content,
  type: ${type.name},
  mediaUrl: $mediaUrl,
  callStatus: $callStatus,
  createdAt: $createdAt
)
''';
  }
}