import 'package:intl/intl.dart';

class DateTimeFormatter {
  // Private constructor to prevent creating instances
  DateTimeFormatter._();

  // =========================================================
  // CONVERT SUPABASE TIMESTAMP TO LOCAL TIME
  // =========================================================
  static DateTime toLocal(DateTime dateTime) {
    // If timestamp is already UTC, convert directly
    if (dateTime.isUtc) {
      return dateTime.toLocal();
    }

    // Some Supabase timestamps may not be marked as UTC.
    // Rebuild as UTC and then convert to local timezone.
    return DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    ).toLocal();
  }

  // =========================================================
  // FORMAT CHAT TIME
  //
  // Today        -> 8:06 PM
  // Yesterday    -> Yesterday, 8:06 PM
  // Same Year    -> 14 May, 8:06 PM
  // Different Yr -> 14 May 2025, 8:06 PM
  // =========================================================
  static String formatChatTime(DateTime dateTime) {
    final localTime = toLocal(dateTime);
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final messageDate = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
    );

    // Message sent today
    if (messageDate == today) {
      return DateFormat('h:mm a').format(localTime);
    }

    // Message sent yesterday
    if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(localTime)}';
    }

    // Message sent this year
    if (localTime.year == now.year) {
      return DateFormat('d MMM, h:mm a').format(localTime);
    }

    // Message sent in a different year
    return DateFormat('d MMM yyyy, h:mm a').format(localTime);
  }

  // =========================================================
  // FORMAT DATE HEADER
  //
  // Today
  // Yesterday
  // 14 May 2026
  // =========================================================
  static String formatDateHeader(DateTime dateTime) {
    final localTime = toLocal(dateTime);
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final targetDate = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
    );

    if (targetDate == today) {
      return 'Today';
    }

    if (targetDate == yesterday) {
      return 'Yesterday';
    }

    return DateFormat('dd MMMM yyyy').format(localTime);
  }

  // =========================================================
  // FORMAT LAST SEEN
  //
  // Last seen 8:06 PM
  // Offline
  // =========================================================
  static String formatLastSeen(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Offline';
    }

    final localTime = toLocal(dateTime);
    return 'Last seen ${DateFormat('h:mm a').format(localTime)}';
  }

  // =========================================================
  // FORMAT TIME ONLY
  //
  // 8:06 PM
  // =========================================================
  static String formatTimeOnly(DateTime dateTime) {
    final localTime = toLocal(dateTime);
    return DateFormat('h:mm a').format(localTime);
  }

  // =========================================================
  // FORMAT FULL DATE AND TIME
  //
  // 14 May 2026, 8:06 PM
  // =========================================================
  static String formatFull(DateTime dateTime) {
    final localTime = toLocal(dateTime);
    return DateFormat('d MMM yyyy, h:mm a').format(localTime);
  }

  // =========================================================
  // FORMAT CALL DURATION
  //
  // 45 seconds   -> 00:45
  // 3m 12s       -> 03:12
  // 1h 5m 23s    -> 01:05:23
  // =========================================================
  static String formatDuration(int seconds) {
    if (seconds <= 0) {
      return '';
    }

    final duration = Duration(seconds: seconds);

    // Less than one hour: MM:SS
    if (duration.inHours == 0) {
      final minutes = duration.inMinutes
          .toString()
          .padLeft(2, '0');

      final remainingSeconds = (duration.inSeconds % 60)
          .toString()
          .padLeft(2, '0');

      return '$minutes:$remainingSeconds';
    }

    // One hour or more: HH:MM:SS
    final hours = duration.inHours
        .toString()
        .padLeft(2, '0');

    final minutes = (duration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final remainingSeconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$remainingSeconds';
  }
}