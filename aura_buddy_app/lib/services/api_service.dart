import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// HTTP client for the Aura Buddy backend API.
class ApiService {
  static String get baseUrl => Config.apiBaseUrl;

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ─── Auth ───
  Future<Map<String, dynamic>> login() async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateProfile({String? username, String? avatarUrl, String? bio}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
      body: jsonEncode({
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
      }),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/profile/$username'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/search?q=$query'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<List<dynamic>> getHashtagSearch(String query) async {
    final res = await http.get(
      Uri.parse('$baseUrl/posts/search?hashtag=$query'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<List<dynamic>> getPostsByHashtag(String hashtag) async {
    final res = await http.get(
      Uri.parse('$baseUrl/posts/hashtag/$hashtag'),
      headers: _headers,
    );
    return _handleList(res);
  }

  // ─── Posts ───
  Future<List<dynamic>> getFeed({int limit = 20, int offset = 0}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/posts/feed?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<Map<String, dynamic>> createPost(
    String caption, {
    String? imageUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/posts/'),
      headers: _headers,
      body: jsonEncode({
        'caption': caption,
        if (imageUrl != null) 'image_url': imageUrl,
      }),
    );
    return _handle(res);
  }

  // ─── Aura ───
  Future<Map<String, dynamic>> transferAura(String postId, int amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/aura/transfer'),
      headers: _headers,
      body: jsonEncode({'post_id': postId, 'amount': amount}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> haterTax(String postId, int amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/aura/hater-tax'),
      headers: _headers,
      body: jsonEncode({'post_id': postId, 'amount': amount}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> claimAdReward() async {
    final res = await http.post(
      Uri.parse('$baseUrl/aura/claim-ad-reward'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> claimDailyStreakReward() async {
    final res = await http.post(
      Uri.parse('$baseUrl/aura/claim-daily-streak'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<String?> uploadProfilePicture(String userId, Uint8List bytes, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final path = '$userId/avatars/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return supabase.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> claimMoodReward() async {
    final res = await http.post(
      Uri.parse('$baseUrl/aura/claim-mood-reward'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> verifyIntegrity() async {
    final res = await http.get(
      Uri.parse('$baseUrl/aura/verify-integrity'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<List<dynamic>> getAuraHistory({int limit = 50, int offset = 0}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/aura/history?limit=$limit&offset=$offset'),
      headers: _headers,
    );
    return _handleList(res);
  }

  // ── LEADERBOARDS ───────────────────────────────────────
  Future<Map<String, dynamic>> getLeaderboards() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/aura/leaderboards'),
        headers: _headers,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Leaderboards fetch error: $e');
      return {};
    }
  }

  // ─── Missions ───
  Future<List<dynamic>> getDailyMissions() async {
    final res = await http.get(
      Uri.parse('$baseUrl/missions/daily'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<List<dynamic>> getWeeklyMissions() async {
    final res = await http.get(
      Uri.parse('$baseUrl/missions/weekly'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<List<dynamic>> getMilestones() async {
    final res = await http.get(
      Uri.parse('$baseUrl/missions/milestones'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<Map<String, dynamic>> completeMission(int userMissionId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/missions/complete/$userMissionId'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<List<dynamic>> getAchievements() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/achievements'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<Map<String, dynamic>> updateAchievementVisibility(String achievementId, bool isPublic) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/achievements/$achievementId'),
      headers: _headers,
      body: jsonEncode({'is_public': isPublic}),
    );
    return _handle(res);
  }

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;
      
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await supabase.storage.from('posts').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return supabase.storage.from('posts').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }

  // ─── Jury / Post Voting ───
  Future<Map<String, dynamic>> castVote(String postId, String voteType) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jury/vote'),
      headers: _headers,
      body: jsonEncode({'post_id': postId, 'vote_type': voteType}),
    );
    return _handle(res);
  }

  // ─── Followers ───
  Future<Map<String, dynamic>> followUser(String username) async {
    final res = await http.post(
      Uri.parse('$baseUrl/followers/follow/$username'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> unfollowUser(String username) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/followers/unfollow/$username'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<List<dynamic>> getFollowing() async {
    final res = await http.get(
      Uri.parse('$baseUrl/followers/following'),
      headers: _headers,
    );
    return _handleList(res);
  }

  Future<List<dynamic>> getFollowers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/followers/followers'),
      headers: _headers,
    );
    return _handleList(res);
  }

  // ─── Response Handling ───
  Map<String, dynamic> _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  List<dynamic> _handleList(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

