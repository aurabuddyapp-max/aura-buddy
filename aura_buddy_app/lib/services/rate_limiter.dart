import 'package:shared_preferences/shared_preferences.dart';

/// Anti-spam rate limiter
/// Enforces: 20 comments/hour, 50 aura transfers/day, 24h min account age for aura
class RateLimiter {
  static const int maxCommentsPerHour = 20;
  static const int maxAuraTransfersPerDay = 50;
  static const int minAccountAgeHours = 24;

  // ── Comment Rate Limiting ──────────────────
  static Future<bool> canComment() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final hourAgo = now - (60 * 60 * 1000);

    List<String> timestamps = prefs.getStringList('comment_timestamps') ?? [];

    // Remove timestamps older than 1 hour
    timestamps = timestamps.where((t) => int.parse(t) > hourAgo).toList();

    if (timestamps.length >= maxCommentsPerHour) {
      return false;
    }

    timestamps.add(now.toString());
    await prefs.setStringList('comment_timestamps', timestamps);
    return true;
  }

  static Future<int> commentsRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final hourAgo = now - (60 * 60 * 1000);

    List<String> timestamps = prefs.getStringList('comment_timestamps') ?? [];

    timestamps = timestamps.where((t) => int.parse(t) > hourAgo).toList();

    return maxCommentsPerHour - timestamps.length;
  }

  // ── Aura Transfer Rate Limiting ────────────
  static Future<bool> canTransferAura() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final savedDay = prefs.getString('aura_transfer_day');
    int count = prefs.getInt('aura_transfer_count') ?? 0;

    if (savedDay != todayStr) {
      // Reset for new day
      count = 0;
      await prefs.setString('aura_transfer_day', todayStr);
    }

    if (count >= maxAuraTransfersPerDay) {
      return false;
    }

    count++;
    await prefs.setInt('aura_transfer_count', count);
    return true;
  }

  static Future<int> auraTransfersRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final savedDay = prefs.getString('aura_transfer_day');
    int count = prefs.getInt('aura_transfer_count') ?? 0;

    if (savedDay != todayStr) {
      return maxAuraTransfersPerDay;
    }

    return maxAuraTransfersPerDay - count;
  }

  // ── Account Age Check ──────────────────────
  static Future<bool> isAccountOldEnough() async {
    final prefs = await SharedPreferences.getInstance();
    final createdStr = prefs.getString('account_created_at');

    if (createdStr == null) {
      // First time — store now
      await prefs.setString(
        'account_created_at',
        DateTime.now().toIso8601String(),
      );
      return false; // New account
    }

    final created = DateTime.parse(createdStr);
    final age = DateTime.now().difference(created).inHours;
    return age >= minAccountAgeHours;
  }

  static Future<int> hoursUntilCanTransfer() async {
    final prefs = await SharedPreferences.getInstance();
    final createdStr = prefs.getString('account_created_at');

    if (createdStr == null) return minAccountAgeHours;

    final created = DateTime.parse(createdStr);
    final age = DateTime.now().difference(created).inHours;
    return (minAccountAgeHours - age).clamp(0, minAccountAgeHours);
  }
}

