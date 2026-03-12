import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import 'user_list_screen.dart';
import '../services/api_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isFollowing = false;
  int _followerCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final followService = context.read<FollowService>();
    final isFollowing = followService.isFollowing(widget.username);
    final followerCount = followService.getFollowerCount(widget.username);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _followerCount = followerCount + (isFollowing ? 1 : 0);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final apiService = context.read<ApiService>();
    if (_isFollowing) {
      await context.read<FollowService>().unfollow(apiService, widget.username);
      setState(() {
        _isFollowing = false;
        _followerCount--;
      });
    } else {
      await context.read<FollowService>().follow(apiService, widget.username);
      setState(() {
        _isFollowing = true;
        _followerCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                child: Column(
                  children: [
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
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Profile',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const Spacer(),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: Text(
                        widget.username[0].toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '@${widget.username}',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spreading positive vibes ✨',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SmallStat(label: 'Posts', value: '12'),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListScreen(
                                title: 'Followers',
                                usernames: ['aura_king', 'fit_guru', 'good_karma'],
                              ),
                            ),
                          ),
                          child: _SmallStat(label: 'Followers', value: '$_followerCount'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListScreen(
                                title: 'Following',
                                usernames: ['unknown_user', 'aura_buddy'], // Mock following for others
                              ),
                            ),
                          ),
                          child: _SmallStat(label: 'Following', value: '${context.read<FollowService>().getFollowingCount(widget.username)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!_isLoading)
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.white.withOpacity(0.1) : Colors.white,
                          foregroundColor: _isFollowing ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: _isFollowing ? const BorderSide(color: Colors.white24) : BorderSide.none,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isFollowing ? 'FOLLOWING' : 'FOLLOW',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800, 
                            fontSize: 13,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Activity Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Recent Activity',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          
          // Mock Posts Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: AuraBuddyTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage('https://picsum.photos/seed/${widget.username}_$index/300/300'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                childCount: 4,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}
