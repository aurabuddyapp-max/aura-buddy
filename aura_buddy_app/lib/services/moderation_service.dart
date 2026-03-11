import 'package:shared_preferences/shared_preferences.dart';

/// Content moderation — bad word filter + report system
class ModerationService {
  // Common bad words list (basic filter)
  static const List<String> _badWords = [
    'damn',
    'hell',
    'crap',
    'stupid',
    'idiot',
    'dumb',
    'ugly',
    'hate',
    'kill',
    'die',
    'loser',
    'trash',
    'suck',
    'wtf',
    'stfu',
    'lmao',
    'ass',
    'dick',
    'shit',
    'fuck',
    'bitch',
    'bastard',
    'asshole',
  ];

  /// Check if text contains bad words
  static bool containsBadWords(String text) {
    final lower = text.toLowerCase();
    for (final word in _badWords) {
      // Match whole words only
      final pattern = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }

  /// Censor bad words in text (replace with ****)
  static String censorText(String text) {
    String result = text;
    for (final word in _badWords) {
      final pattern = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      result = result.replaceAllMapped(
        pattern,
        (m) => '*' * m.group(0)!.length,
      );
    }
    return result;
  }

  /// Report a post/comment
  static Future<void> reportContent({
    required String contentId,
    required String contentType, // 'post', 'comment', 'user'
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('reported_content') ?? [];
    reports.add(
      '$contentType:$contentId:$reason:${DateTime.now().toIso8601String()}',
    );
    await prefs.setStringList('reported_content', reports);
  }

  /// Check if content has already been reported by this user
  static Future<bool> hasReported(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList('reported_content') ?? [];
    return reports.any((r) => r.contains(contentId));
  }
}

