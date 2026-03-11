import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Follow system — track who the user follows and who follows them
class FollowService extends ChangeNotifier {
  Set<String> _following = {};
  Set<String> _followers = {};

  Set<String> get following => _following;
  Set<String> get followers => _followers;
  
  int get followingCount => _following.length;
  int get followersCount => _followers.length;

  Future<void> init(ApiService apiService) async {
    try {
      final followingList = await apiService.getFollowing();
      final followersList = await apiService.getFollowers();
      
      _following = followingList.map((u) => u['username'] as String).toSet();
      _followers = followersList.map((u) => u['username'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('FollowService init error: $e');
    }
  }

  /// Check if current user follows a given username
  bool isFollowing(String username) {
    return _following.contains(username);
  }

  /// Follow a user
  Future<void> follow(ApiService apiService, String username) async {
    if (!_following.contains(username)) {
      try {
        await apiService.followUser(username);
        _following.add(username);
        notifyListeners();
      } catch (e) {
        debugPrint('Follow error: $e');
      }
    }
  }

  /// Unfollow a user
  Future<void> unfollow(ApiService apiService, String username) async {
    if (_following.contains(username)) {
      try {
        await apiService.unfollowUser(username);
        _following.remove(username);
        notifyListeners();
      } catch (e) {
        debugPrint('Unfollow error: $e');
      }
    }
  }

  /// Get follower count for a specific user (mock legacy)
  int getFollowerCount(String username) {
    // This is now handled by UserProfileModel from backend
    return 0; 
  }

  /// Get following count for a specific user (mock legacy)
  int getFollowingCount(String username) {
    // This is now handled by UserProfileModel from backend
    return 0;
  }
}


