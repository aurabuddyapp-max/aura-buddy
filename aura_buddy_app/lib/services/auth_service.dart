import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Auth service using Supabase Auth for production-ready authentication.
class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;

  Future<void> loadUserFromBackend(dynamic apiService) async {
    if (!_isLoggedIn) return;
    try {
      final json = await apiService.getMe();
      final user = UserModel.fromJson(json);
      _username = user.username;
      _email = user.email;
      _avatarUrl = user.avatarUrl;
      _bio = user.bio;
      _auraPoints = user.auraPoints;
      _level = user.level;
      _currentStreak = user.currentStreak;
      _isPremium = user.isPremium;
      _postsCount = user.postsCount;
      _followersCount = user.followersCount;
      _followingCount = user.followingCount;
      _lastStreakClaimedAt = user.lastStreakClaimedAt;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading backend profile: $e');
    }
  }

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _avatarUrl;
  String? _bio;
  int _auraPoints = 0;
  int _level = 1;
  int _currentStreak = 0;
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  DateTime? _lastStreakClaimedAt;
  DateTime? _lastUsernameChange;
  bool _isPremium = false;

  AuthService() {
    _init();
  }

  void _init() {
    _currentUser = _supabase.auth.currentUser;
    _isLoggedIn = _currentUser != null;
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      _currentUser = session?.user;
      final wasLoggedIn = _isLoggedIn;
      _isLoggedIn = _currentUser != null;
      
      if (_isLoggedIn && !wasLoggedIn) {
        // Just logged in
      } else if (!_isLoggedIn) {
        _clearLocalData();
      }
      notifyListeners();
    });
  }

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String? get userId => _currentUser?.id;
  String? get email => _email ?? _currentUser?.email;
  String? get username => _username;
  String? get avatarUrl => _avatarUrl;
  int get auraBalance => _auraPoints;
  int get level => _level;
  int get currentStreak => _currentStreak;
  int get postsCount => _postsCount;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  DateTime? get lastStreakClaimedAt => _lastStreakClaimedAt;
  bool get isPremium => _isPremium;
  String? get bio => _bio;

  /// Sign in with Email and Password
  Future<void> signInWithPassword(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up with Email and Password
  Future<void> register(String email, String password, {String? username}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
  }

  /// Sign in with Google (using Supabase Auth)
  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.aurabuddy://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  /// Sign in with Apple (using Supabase Auth)
  Future<bool> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.aurabuddy://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _clearLocalData();
    notifyListeners();
  }

  void _clearLocalData() {
    _username = null;
    _email = null;
    _avatarUrl = null;
    _auraPoints = 0;
    _level = 1;
    _currentStreak = 0;
    _postsCount = 0;
    _followersCount = 0;
    _followingCount = 0;
    _lastStreakClaimedAt = null;
    _lastUsernameChange = null;
    _isPremium = false;
    _bio = null;
  }

  Future<String?> uploadAvatar(Uint8List bytes, String fileName) async {
    if (!_isLoggedIn) return null;
    try {
      final path = 'avatars/${_currentUser!.id}/$fileName';
      await _supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      _avatarUrl = url;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  Future<bool> setUsername(String newUsername, dynamic apiService) async {
    try {
      await apiService.updateProfile(username: newUsername);
      _username = newUsername;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting username: $e');
      return false;
    }
  }

  Future<void> setBio(String newBio, dynamic apiService) async {
    try {
      await apiService.updateProfile(bio: newBio);
      _bio = newBio;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting bio: $e');
    }
  }

  bool get canChangeUsername => true; // Simple for now
  int get daysUntilUsernameChange => 0;

  int get auraToNextLevel {
    if (_auraBalance < 500) return 500 - _auraBalance;
    if (_auraBalance < 2000) return 2000 - _auraBalance;
    return 0;
  }

  String get nextLevelTitle {
    if (_auraBalance < 500) return '🌟 Level 2: Rising Star';
    if (_auraBalance < 2000) return '👑 Level 3: Positive Voice';
    return 'Max Level Reached';
  }
}

