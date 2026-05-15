class CallModel {
  final String id;

  // Database fields
  final String callerId;
  final String receiverId;
  final String callType; // voice | video
  final String direction; // outgoing | incoming
  final String status; // completed | missed | rejected | cancelled
  final int durationSeconds;

  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  // UI fields
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.direction,
    required this.status,
    required this.durationSeconds,
    required this.createdAt,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.startedAt,
    this.endedAt,
  });

  // =========================================================
  // FROM JSON
  // =========================================================

  factory CallModel.fromJson(
      Map<String, dynamic> json,
      ) {
    // -------------------------------------------------------
    // Avatar
    // -------------------------------------------------------
    String avatar =
    (json['other_user_avatar'] ??
        json['avatar_url'] ??
        '')
        .toString()
        .trim();

    if (avatar.isEmpty) {
      avatar = '';
    }

    // -------------------------------------------------------
    // Normalize call type
    // Supports:
    // - voice
    // - video
    // - call
    // - video_call
    // -------------------------------------------------------
    String rawType =
    (json['call_type'] ??
        json['type'] ??
        'voice')
        .toString()
        .toLowerCase()
        .trim();

    String normalizedType;

    if (rawType == 'video' ||
        rawType == 'video_call') {
      normalizedType = 'video';
    } else {
      normalizedType = 'voice';
    }

    // -------------------------------------------------------
    // Normalize direction
    // -------------------------------------------------------
    final direction =
    (json['direction'] ?? 'outgoing')
        .toString()
        .toLowerCase()
        .trim();

    // -------------------------------------------------------
    // Normalize status
    // -------------------------------------------------------
    final status =
    (json['status'] ?? 'completed')
        .toString()
        .toLowerCase()
        .trim();

    // -------------------------------------------------------
    // Duration
    // Supports:
    // - duration_seconds
    // - call_duration
    // -------------------------------------------------------
    int duration = 0;

    final durationValue =
        json['duration_seconds'] ??
            json['call_duration'];

    if (durationValue is num) {
      duration = durationValue.toInt();
    } else if (durationValue != null) {
      duration =
          int.tryParse(
            durationValue.toString(),
          ) ??
              0;
    }

    // -------------------------------------------------------
    // Name
    // -------------------------------------------------------
    String name =
    (json['other_user_name'] ??
        json['name'] ??
        json['full_name'] ??
        json['display_name'] ??
        json['username'] ??
        'Unknown User')
        .toString()
        .trim();

    if (name.isEmpty) {
      name = 'Unknown User';
    }

    // -------------------------------------------------------
    // Other user ID
    // -------------------------------------------------------
    final otherUserId =
    (json['other_user_id'] ??
        json['receiver_id'] ??
        '')
        .toString();

    return CallModel(
      id: (json['id'] ?? '').toString(),

      callerId:
      (json['caller_id'] ?? '').toString(),

      receiverId:
      (json['receiver_id'] ?? '').toString(),

      callType: normalizedType,

      direction: direction,

      status: status,

      durationSeconds: duration,

      startedAt: json['started_at'] != null
          ? DateTime.tryParse(
        json['started_at']
            .toString(),
      )
          : null,

      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(
        json['ended_at']
            .toString(),
      )
          : null,

      createdAt:
      DateTime.tryParse(
        (json['created_at'] ?? '')
            .toString(),
      ) ??
          DateTime.now(),

      otherUserId: otherUserId,

      otherUserName: name,

      otherUserAvatar:
      avatar.isEmpty ? null : avatar,
    );
  }

  // =========================================================
  // TO JSON
  // =========================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'direction': direction,
      'status': status,
      'duration_seconds': durationSeconds,
      'started_at':
      startedAt?.toUtc().toIso8601String(),
      'ended_at':
      endedAt?.toUtc().toIso8601String(),
      'created_at':
      createdAt.toUtc().toIso8601String(),
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
    };
  }

  // =========================================================
  // TYPE HELPERS
  // =========================================================

  bool get isVoiceCall =>
      callType.toLowerCase() == 'voice';

  bool get isVideoCall =>
      callType.toLowerCase() == 'video';

  // Legacy compatibility
  String get type =>
      isVideoCall ? 'video_call' : 'call';

  // =========================================================
  // DIRECTION HELPERS
  // =========================================================

  bool get isOutgoing =>
      direction.toLowerCase() == 'outgoing';

  bool get isIncoming =>
      direction.toLowerCase() == 'incoming';

  // =========================================================
  // STATUS HELPERS
  // =========================================================

  bool get isMissed =>
      status.toLowerCase() == 'missed';

  bool get isMissedCall => isMissed;

  bool get isCompleted =>
      status.toLowerCase() == 'completed';

  bool get isRejected =>
      status.toLowerCase() == 'rejected';

  bool get isCancelled =>
      status.toLowerCase() == 'cancelled';

  // =========================================================
  // DURATION HELPERS
  // =========================================================

  int get duration => durationSeconds;

  bool get hasDuration =>
      durationSeconds > 0;

  Duration get durationObject =>
      Duration(seconds: durationSeconds);

  String get formattedDuration {
    if (durationSeconds <= 0) {
      return '0:00';
    }

    final hours =
        durationSeconds ~/ 3600;
    final minutes =
        (durationSeconds % 3600) ~/ 60;
    final seconds =
        durationSeconds % 60;

    if (hours > 0) {
      return '${hours.toString()}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString()}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // DESCRIPTION
  // =========================================================

  String description(
      String currentUserId,
      ) {
    final outgoing =
        callerId == currentUserId;

    final typeText =
    isVideoCall
        ? 'video call'
        : 'voice call';

    if (isMissed) {
      return 'Missed $typeText';
    }

    if (isRejected) {
      return 'Rejected $typeText';
    }

    if (isCancelled) {
      return 'Cancelled $typeText';
    }

    return outgoing
        ? 'Outgoing $typeText'
        : 'Incoming $typeText';
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  CallModel copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    String? callType,
    String? direction,
    String? status,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId:
      callerId ?? this.callerId,
      receiverId:
      receiverId ?? this.receiverId,
      callType:
      callType ?? this.callType,
      direction:
      direction ?? this.direction,
      status:
      status ?? this.status,
      durationSeconds:
      durationSeconds ??
          this.durationSeconds,
      startedAt:
      startedAt ?? this.startedAt,
      endedAt:
      endedAt ?? this.endedAt,
      createdAt:
      createdAt ?? this.createdAt,
      otherUserId:
      otherUserId ??
          this.otherUserId,
      otherUserName:
      otherUserName ??
          this.otherUserName,
      otherUserAvatar:
      otherUserAvatar ??
          this.otherUserAvatar,
    );
  }
}