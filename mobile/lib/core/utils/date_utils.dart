import 'package:intl/intl.dart';

/// Date/time formatting helpers for CivicConnect.
abstract final class AppDateUtils {
  static final _dateFormatter    = DateFormat('dd MMM yyyy');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormatter    = DateFormat('hh:mm a');
  static final _apiFormatter     = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// Formats a [DateTime] as `15 Jul 2026`.
  static String formatDate(DateTime dt) => _dateFormatter.format(dt);

  /// Formats a [DateTime] as `15 Jul 2026, 03:45 PM`.
  static String formatDateTime(DateTime dt) => _dateTimeFormatter.format(dt);

  /// Formats a [DateTime] as `03:45 PM`.
  static String formatTime(DateTime dt) => _timeFormatter.format(dt);

  /// Returns a human-readable relative time string,
  /// e.g. `just now`, `5m ago`, `2h ago`, `3 days ago`.
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());

    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    if (diff.inDays < 30)     return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365)    return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Parses an ISO-8601 string from the backend.
  static DateTime parseIso(String raw) => DateTime.parse(raw).toLocal();

  /// Formats a DateTime to the API-expected format.
  static String toApiString(DateTime dt) => _apiFormatter.format(dt.toUtc());

  /// Returns true if [dt] is today.
  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Returns true if a deadline [dt] has passed.
  static bool isOverdue(DateTime dt) => DateTime.now().isAfter(dt);
}
