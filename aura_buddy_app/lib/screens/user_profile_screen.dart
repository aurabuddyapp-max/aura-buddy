import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/follow_service.dart';
import '../services/moderation_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final followService = context.read<FollowService>();
      
      // Ensure follow service is synced
      await followService.init(apiService);

      final data = await apiService.getPublicProfile(widget.username);
      setState(() {
        _profile = UserProfileModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _reportUser() {
    if (_profile == null) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Report @${_profile!.username}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReportOption(
                  label: 'Spam or fake account',
                  onTap: () => _submitReport('spam', ctx),
                ),
                _ReportOption(
                  label: 'Harassment or bullying',
                  onTap: () => _submitReport('harassment', ctx),
                ),
                _ReportOption(
                  label: 'Inappropriate content',
                  onTap: () => _submitReport('inappropriate', ctx),
                ),
                _ReportOption(
                  label: 'Other',
                  onTap: () => _submitReport('other', ctx),
                ),
              ],
            ),
          ),
    );
  }

  void _submitReport(String reason, BuildContext ctx) {
    if (_profile == null) return;
    ModerationService.reportContent(
      contentId: _profile!.username,
      contentType: 'user',
      reason: reason,
    );
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚩 Report submitted. We\'ll review it.',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AuraBuddyTheme.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AuraBuddyTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AuraBuddyTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('User not found')),
      );
    }


    final followService = context.watch<FollowService>();
    final apiService = context.read<ApiService>();
    final isFollowing = followService.isFollowing(_profile!.username);
    final followerCount = _profile!.followersCount;
    final followingCount = _profile!.followingCount;
    
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Profile Header ─────────────────────────
          SliverToBoxAdapter(
            child: Container(
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    children: [
                      // Back button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Report button
                          GestureDetector(
                            onTap: _reportUser,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_profile!.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AuraBuddyTheme.gold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '⭐ PREMIUM',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _profile!.isPremium
                                    ? AuraBuddyTheme.gold
                                    : Colors.white,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage:
                              _profile!.avatarUrl != null
                                  ? NetworkImage(_profile!.avatarUrl!)
                                  : null,
                          child:
                              _profile!.avatarUrl == null
                                  ? Text(
                                    _profile!.username[0].toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        '@${_profile!.username}',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (_profile!.bio != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _profile!.bio!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Follow/Unfollow button
                      GestureDetector(
                        onTap: () {
                          if (isFollowing) {
                            followService.unfollow(apiService, _profile!.username);
                          } else {
                            followService.follow(apiService, _profile!.username);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isFollowing
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border:
                                isFollowing
                                    ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    )
                                    : null,
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isFollowing
                                      ? Colors.white
                                      : AuraBuddyTheme.textOnPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ProfileStat(
                              value: '$followerCount',
                              label: 'Followers',
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            _ProfileStat(
                              value: '$followingCount',
                              label: 'Following',
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            _ProfileStat(
                              value: '${_profile!.auraPoints}',
                              label: 'Aura',
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            _ProfileStat(
                              value: '${_profile!.postsCount}',
                              label: 'Posts',
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

          // ── Achievements ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children:
                          _profile!.achievements
                              .where((a) => a.isUnlocked)
                              .map(
                                (a) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AuraBuddyTheme.gold.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(a.emoji, style: const TextStyle(fontSize: 18)),
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
                                                color: AuraBuddyTheme.textDark,
                                              ),
                                            ),
                                            Text(
                                              a.subtitle ?? a.description,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AuraBuddyTheme.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AuraBuddyTheme.success,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tabs: Posts & Jury ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ProfileTabsView(profile: _profile!),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ProfileTabsView extends StatefulWidget {
  final UserProfileModel profile;
  const _ProfileTabsView({required this.profile});

  @override
  State<_ProfileTabsView> createState() => _ProfileTabsViewState();
}

class _ProfileTabsViewState extends State<_ProfileTabsView> {
  int _tabIndex = 0;

  String _missionEmoji(String type) {
    switch (type) {
      case 'FIT_CHECK':
        return '👗';
      case 'EAT_HEALTHY':
        return '🥗';
      case 'WORKOUT':
        return '💪';
      default:
        return '🎯';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Row(
          children: [
            _ProfileTab(
              label: 'Posts',
              isActive: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            const SizedBox(width: 8),
            _ProfileTab(
              label: 'Missions',
              isActive: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content
        if (_tabIndex == 0) ...[
          if (widget.profile.posts.isEmpty)
            _EmptyState(icon: Icons.feed_rounded, label: 'No posts yet')
          else
            ...widget.profile.posts.map((post) {
              final isPositive = post.auraScore >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: AuraBuddyTheme.whiteCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.caption,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AuraBuddyTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isPositive
                                    ? AuraBuddyTheme.primary
                                    : AuraBuddyTheme.danger)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}${post.auraScore} ',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isPositive
                                          ? AuraBuddyTheme.primary
                                          : AuraBuddyTheme.danger,
                                ),
                              ),
                              AuraBuddyTheme.auraIcon(size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (post.hashtags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            post.hashtags
                                .map(
                                  (t) => Text(
                                    t,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AuraBuddyTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ] else ...[
          if (widget.profile.missions.isEmpty)
            _EmptyState(icon: Icons.gavel_rounded, label: 'No missions yet')
          else
            ...widget.profile.missions.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: AuraBuddyTheme.whiteCard(),
                child: Row(
                  children: [
                    Text(
                      _missionEmoji(m.mission.type),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.mission.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AuraBuddyTheme.textDark,
                            ),
                          ),
                          Text(
                            m.mission.type.replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AuraBuddyTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (m.status == 'VALIDATED'
                                ? AuraBuddyTheme.success
                                : m.status == 'REJECTED'
                                ? AuraBuddyTheme.danger
                                : AuraBuddyTheme.warning)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              m.status == 'VALIDATED'
                                  ? AuraBuddyTheme.success
                                  : m.status == 'REJECTED'
                                  ? AuraBuddyTheme.danger
                                  : AuraBuddyTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive
                    ? AuraBuddyTheme.primary
                    : AuraBuddyTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? Colors.white : AuraBuddyTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AuraBuddyTheme.whiteCard(),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AuraBuddyTheme.textLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AuraBuddyTheme.textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ReportOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AuraBuddyTheme.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AuraBuddyTheme.textLight,
      ),
      onTap: onTap,
    );
  }
}

