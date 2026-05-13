class CallModel {
  final String id;

  // Current user is the caller
  final String callerId;

  // Other user is the receiver
  final String receiverId;

  /// 'voice' or 'video'
  final String callType;

  /// 'outgoing' or 'incoming'
  final String direction;

  /// 'ringing', 'answered', 'completed',
  /// 'missed', 'rejected', 'cancelled'
  final String status;

  /// Duration in seconds
  final int durationSeconds;

  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  // Additional fields used by calls_screen.dart
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
  // FACTORY
  // =========================================================

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id']?.toString() ?? '',
      callerId: json['caller_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      callType: json['call_type']?.toString() ?? 'voice',
      direction: json['direction']?.toString() ?? 'outgoing',
      status: json['status']?.toString() ?? 'completed',
      durationSeconds:
      (json['duration_seconds'] as num?)?.toInt() ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(
        json['started_at'].toString(),
      )
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(
        json['ended_at'].toString(),
      )
          : null,
      createdAt:
      DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ) ??
          DateTime.now(),

      // Additional fields
      otherUserId:
      json['other_user_id']?.toString() ??
          json['receiver_id']?.toString() ??
          '',
      otherUserName:
      json['other_user_name']?.toString() ??
          json['other_user_full_name']?.toString() ??
          json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Unknown User',
      otherUserAvatar:
      json['other_user_avatar']?.toString() ??
          json['avatar_url']?.toString(),
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

      // Additional fields
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
    };
  }

  // =========================================================
  // BASIC HELPERS
  // =========================================================

  bool get isVoiceCall => callType == 'voice';

  bool get isVideoCall => callType == 'video';

  bool get isMissedCall => status == 'missed';

  bool get isCompleted => status == 'completed';

  bool get isRejected => status == 'rejected';

  bool get isCancelled => status == 'cancelled';

  bool get hasDuration => durationSeconds > 0;

  Duration get durationObject =>
      Duration(seconds: durationSeconds);

  // =========================================================
  // HELPERS USED BY calls_screen.dart
  // =========================================================

  bool get isOutgoing =>
      direction.toLowerCase() == 'outgoing';

  bool get isIncoming =>
      direction.toLowerCase() == 'incoming';

  bool get isMissed =>
      status.toLowerCase() == 'missed';

  /// Integer duration in seconds (used by calls_screen.dart)
  int get duration => durationSeconds;

  // =========================================================
  // FORMATTED DURATION
  // =========================================================

  String get formattedDuration {
    if (durationSeconds <= 0) {
      return '0:00';
    }

    final hours = durationSeconds ~/ 3600;
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

  String description(String currentUserId) {
    final outgoing =
        callerId == currentUserId;

    final typeText =
    isVideoCall
        ? 'video call'
        : 'voice call';

    if (status == 'missed') {
      return 'Missed $typeText';
    }

    if (status == 'rejected') {
      return 'Rejected $typeText';
    }

    if (status == 'cancelled') {
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
      receiverId ??
          this.receiverId,
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