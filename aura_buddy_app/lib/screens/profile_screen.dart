import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/aura_history_service.dart';
import 'settings_screen.dart';
import 'weekly_tasks_screen.dart';
import 'aura_history_screen.dart';
import 'leaderboard_screen.dart';
import 'mood_screen.dart';
import 'user_profile_screen.dart';
import 'user_list_screen.dart';
import '../services/follow_service.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/daily_login_dialog.dart';
import '../services/task_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _adWatchCount = 0;
  DateTime? _cooldownStart;
  static const _maxAds = 2;
  static const _cooldownHours = 12;

  final List<AchievementModel> _achievements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiService = context.read<ApiService>();
      context.read<AuthService>().loadUserFromBackend(apiService);
      _fetchAchievements();
    });
  }

  Future<void> _fetchAchievements() async {
    final apiService = context.read<ApiService>();
    try {
      final data = await apiService.getAchievements();
      if (!mounted) return;
      setState(() {
        _achievements.clear();
        _achievements.addAll(data.map((json) => AchievementModel.fromJson(json)));
      });
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
    }
  }

  bool get _canWatchAd => _adWatchCount < _maxAds;

  String get _cooldownRemaining {
    if (_cooldownStart == null) return '';
    final elapsed = DateTime.now().difference(_cooldownStart!);
    final remaining = Duration(hours: _cooldownHours) - elapsed;
    if (remaining.isNegative) return '';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }

  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final auth = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      final bytes = await image.readAsBytes();
      final imageUrl = await apiService.uploadProfilePicture(
        auth.userId!,
        bytes,
        image.name,
      );

      // Update local profile pic
      await auth.loadUserFromBackend(apiService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: AuraBuddyTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AuraBuddyTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _claimAdReward() async {
    final apiService = context.read<ApiService>();
    final auth = context.read<AuthService>();

    try {
      await apiService.claimAdReward();
      await auth.loadUserFromBackend(apiService);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 +100 Aura earned from ad!',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AuraBuddyTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limit reached or error: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AuraBuddyTheme.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final username = auth.username ?? 'buddy';
    final bio = auth.bio ?? 'Aura enthusiast';
    final profilePic = auth.avatarUrl;
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final apiService = context.read<ApiService>();
          await auth.loadUserFromBackend(apiService);
        },
        color: AuraBuddyTheme.primary,
        child: CustomScrollView(
          slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Profile',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage:
                                    profilePic != null
                                        ? NetworkImage(profilePic)
                                        : null,
                                child:
                                    profilePic == null
                                        ? Text(
                                          username[0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        )
                                        : null,
                              ),
                              if (_isUploading)
                                const Positioned.fill(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AuraBuddyTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: AuraBuddyTheme.textOnPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Aura Reputation Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AuraBuddyTheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🌱 Level ${auth.level}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AuraBuddyTheme.primary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.level > 1 ? 'Rising Star' : 'Newcomer',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile Stats Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Main Aura Balance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('${auth.auraBalance}', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(width: 6),
                                 Text(' Aura', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8))),
                                 const SizedBox(width: 4),
                                 AuraBuddyTheme.auraIcon(size: 20),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Secondary Stats Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  label: 'Posts',
                                  value: '${auth.postsCount}',
                                  onTap: () {},
                                ),
                                _StatItem(
                                  label: 'Followers',
                                  value: '${auth.followersCount}',
                                  onTap: () {},
                                ),
                                _StatItem(
                                  label: 'Following',
                                  value: '${auth.followingCount}',
                                  onTap: () {},
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Colors.white.withOpacity(0.15)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(label: 'Given', value: '850', color: AuraBuddyTheme.primary),
                                _StatItem(label: 'Received', value: '1,420', color: AuraBuddyTheme.success),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Action Cards ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.play_circle_fill_rounded,
                      label: 'Watch Ad\n+100 Aura',
                      badge: 'Daily Rewards',
                      color: AuraBuddyTheme.primary,
                      onTap: _claimAdReward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.star_rounded,
                      label: 'Go\nPremium',
                      badge: 'Unlock more',
                      color: AuraBuddyTheme.gold,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '⭐ Premium — Coming soon!',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AuraBuddyTheme.gold,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Weekly Tasks Link ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyTasksScreen(),
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AuraBuddyTheme.whiteCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🎯', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Tasks',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AuraBuddyTheme.textDark,
                              ),
                            ),
                            Text(
                              'Complete tasks to earn bonus aura',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AuraBuddyTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Aura History Link ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuraHistoryScreen(),
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AuraBuddyTheme.whiteCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('📊', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aura History',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AuraBuddyTheme.textDark,
                              ),
                            ),
                            Text(
                              'View all your aura transactions',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AuraBuddyTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Leaderboard Link ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AuraBuddyTheme.whiteCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leaderboard',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AuraBuddyTheme.textDark,
                              ),
                            ),
                            Text(
                              'See where you rank globally',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AuraBuddyTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Mood Tracker Link ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodScreen()),
                    ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AuraBuddyTheme.whiteCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('😊', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mood Tracker',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AuraBuddyTheme.textDark,
                              ),
                            ),
                            Text(
                              'Log how you feel and earn aura',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AuraBuddyTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Stats',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          value: '${auth.postsCount}',
                          label: 'Posts',
                        ),
                        _StatItem(
                          value: '-',
                          label: 'Jury Votes',
                        ),
                        _StatItem(
                          value: '-',
                          label: 'Aura Given',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Aura Streaks ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '🔥 Aura Streaks',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuraBuddyTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Earn bonuses!',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AuraBuddyTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StreakCard(
                    emoji: '🔥',
                    title: 'Daily Login',
                    description: 'Log in daily to keep your streak',
                    currentDays: auth.currentStreak,
                    targetDays: 7,
                    bonus: 50 * (auth.currentStreak + 1),
                    completed: auth.lastStreakClaimedAt?.day != DateTime.now().day,
                    onClaim: auth.lastStreakClaimedAt?.day != DateTime.now().day ? () => DailyLoginDialog.checkAndShow(context) : null,
                  ),
                  const SizedBox(height: 8),
                  _StreakCard(
                    emoji: '⚖️',
                    title: 'Jury Veteran',
                    description: 'Vote on jury 7 days in a row',
                    currentDays: 5,
                    targetDays: 7,
                    bonus: 300,
                  ),
                  const SizedBox(height: 8),
                  _StreakCard(
                    emoji: '📝',
                    title: 'Poster',
                    description: 'Post 3 days in a row',
                    currentDays: 3,
                    targetDays: 3,
                    bonus: 100,
                    completed: true,
                  ),
                ],
              ),
            ),
          ),

          // ── Achievements ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Achievements',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuraBuddyTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showVisibilitySettings,
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 16,
                              color: AuraBuddyTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Manage visibility',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AuraBuddyTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children:
                          _achievements.map((a) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          a.isUnlocked
                                              ? AuraBuddyTheme.gold.withValues(
                                                alpha: 0.1,
                                              )
                                              : AuraBuddyTheme.textLight
                                                  .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        a.emoji,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color:
                                              a.isUnlocked
                                                  ? null
                                                  : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.title,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color:
                                                a.isUnlocked
                                                    ? AuraBuddyTheme.textDark
                                                    : AuraBuddyTheme.textLight,
                                          ),
                                        ),
                                          Text(
                                            a.subtitle ?? '',
                                            style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AuraBuddyTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (a.isUnlocked)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (a.isPublic)
                                          Icon(
                                            Icons.visibility_rounded,
                                            size: 14,
                                            color: AuraBuddyTheme.primary
                                                .withOpacity(0.5),
                                          ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AuraBuddyTheme.success,
                                          size: 18,
                                        ),
                                      ],
                                    )
                                  else
                                    Icon(
                                      Icons.lock_rounded,
                                      color: AuraBuddyTheme.textLight,
                                      size: 18,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    ),
  );
}

  void _showVisibilitySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) {
              final unlocked =
                  _achievements.where((a) => a.isUnlocked).toList();
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AuraBuddyTheme.textLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Achievement Visibility',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AuraBuddyTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose which achievements others can see',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AuraBuddyTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...unlocked.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(a.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                a.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AuraBuddyTheme.textDark,
                                ),
                              ),
                            ),
                            Switch(
                              value: a.isPublic,
                              onChanged: (v) async {
                                final apiService = context.read<ApiService>();
                                try {
                                  await apiService.updateAchievementVisibility(a.id, v);
                                  setModalState(() => a.isPublic = v);
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update visibility: $e')),
                                  );
                                }
                              },
                              activeThumbColor: AuraBuddyTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AuraBuddyTheme.whiteCard(),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AuraBuddyTheme.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AuraBuddyTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: (color ?? Colors.white).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final int currentDays;
  final int targetDays;
  final int bonus;
  final bool completed;
  final VoidCallback? onClaim;

  const _StreakCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.currentDays,
    required this.targetDays,
    required this.bonus,
    this.completed = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentDays / targetDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AuraBuddyTheme.whiteCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AuraBuddyTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AuraBuddyTheme.textDark,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (!completed && onClaim != null)
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraBuddyTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Claim',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        completed
                            ? AuraBuddyTheme.success.withValues(alpha: 0.1)
                            : AuraBuddyTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    completed ? '✅ +$bonus' : '+$bonus',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          completed
                              ? AuraBuddyTheme.success
                              : AuraBuddyTheme.gold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AuraBuddyTheme.primary.withOpacity(
                      0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed
                          ? AuraBuddyTheme.success
                          : AuraBuddyTheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$currentDays/$targetDays days',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuraBuddyTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
