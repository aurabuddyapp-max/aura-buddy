import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'user_profile_screen.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _globalAura = [];
  List<Map<String, dynamic>> _weeklyAura = [];
  List<Map<String, dynamic>> _topJury = [];
  List<Map<String, dynamic>> _topCreators = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLeaderboards();
    });
  }

  void _fetchLeaderboards() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final data = await apiService.getLeaderboards();
      
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        
        final weekly = List<dynamic>.from(data['weeklyAura'] ?? []);
        _weeklyAura = weekly.map((item) => {
          'username': item['username'] ?? 'User',
          'aura': item['aura'] ?? 0,
          'premium': item['premium'] ?? false,
          'id': item['id'],
        }).toList();

        final global = List<dynamic>.from(data['globalAura'] ?? []);
        _globalAura = global.map((item) => {
          'username': item['username'] ?? 'User',
          'aura': item['aura'] ?? 0,
          'premium': item['premium'] ?? false,
          'id': item['id'],
        }).toList();

        final jury = List<dynamic>.from(data['topJury'] ?? []);
        _topJury = jury.map((item) => {
          'username': item['username'] ?? 'User',
          'value': item['value'] ?? 0,
          'label': 'votes',
          'id': item['id'],
        }).toList();

        final creators = List<dynamic>.from(data['topCreators'] ?? []);
        _topCreators = creators.map((item) => {
          'username': item['username'] ?? 'User',
          'value': item['value'] ?? 0,
          'label': 'posts',
          'id': item['id'],
        }).toList();

        _assignRanks(_weeklyAura);
        _assignRanks(_globalAura);
        _assignRanks(_topJury);
        _assignRanks(_topCreators);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leaderboards: $e')),
        );
      }
    }
  }

  void _assignRanks(List<Map<String, dynamic>> list) {
    for (int i = 0; i < list.length; i++) {
      list[i]['rank'] = i + 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Leaderboard',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Text('🏆', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: '🌍 Global'),
                        Tab(text: '📅 Weekly'),
                        Tab(text: '⚖️ Jury'),
                        Tab(text: '📝 Creators'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab Content ────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRankedList(_globalAura, isAura: true),
                _buildRankedList(_weeklyAura, isAura: true),
                _buildRankedList(_topJury, isAura: false),
                _buildRankedList(_topCreators, isAura: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankedList(
    List<Map<String, dynamic>> data, {
    required bool isAura,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_rounded, size: 56, color: AuraBuddyTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No rankings yet\nCheck back later for updates',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AuraBuddyTheme.textMedium,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Podium (Top 3) ──────────────
        if (data.length >= 3)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
            decoration: AuraBuddyTheme.whiteCard(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                Expanded(
                  child: _PodiumItem(
                    data: data[1],
                    medal: '🥈',
                    height: 80,
                    isAura: isAura,
                    onTap: () => _openProfile(data[1]['username']),
                  ),
                ),
                const SizedBox(width: 8),
                // 1st place
                Expanded(
                  child: _PodiumItem(
                    data: data[0],
                    medal: '🥇',
                    height: 110,
                    isAura: isAura,
                    onTap: () => _openProfile(data[0]['username']),
                  ),
                ),
                const SizedBox(width: 8),
                // 3rd place
                Expanded(
                  child: _PodiumItem(
                    data: data[2],
                    medal: '🥉',
                    height: 60,
                    isAura: isAura,
                    onTap: () => _openProfile(data[2]['username']),
                  ),
                ),
              ],
            ),
          ),

        // ── Rest of Rankings ────────────
        ...data.skip(3).map((entry) {
          final isYou = entry['username'] == 'you';
          return GestureDetector(
            onTap: () => _openProfile(entry['username']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isYou
                        ? AuraBuddyTheme.primary.withOpacity(0.08)
                        : AuraBuddyTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border:
                    isYou
                        ? Border.all(
                          color: AuraBuddyTheme.primary.withOpacity(0.2),
                        )
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${entry['rank']}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AuraBuddyTheme.textMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AuraBuddyTheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      entry['username'][0].toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AuraBuddyTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isYou ? '@you ← You' : '@${entry['username']}',
                      style: GoogleFonts.inter(
                        fontWeight: isYou ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                        color:
                            isYou
                                ? AuraBuddyTheme.primary
                                : AuraBuddyTheme.textDark,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAura ? '${entry['aura']} ' : '${entry['value']} ${entry['label']}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AuraBuddyTheme.primary,
                        ),
                      ),
                      if (isAura) AuraBuddyTheme.auraIcon(size: 14),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openProfile(String username) {
    if (username == 'you') return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(username: username),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String medal;
  final double height;
  final bool isAura;
  final VoidCallback onTap;

  const _PodiumItem({
    required this.data,
    required this.medal,
    required this.height,
    required this.isAura,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isYou = data['username'] == 'you';
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: 22,
            backgroundColor: AuraBuddyTheme.primary.withOpacity(0.1),
            child: Text(
              data['username'][0].toUpperCase(),
              style: GoogleFonts.inter(
                color: AuraBuddyTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isYou ? 'You' : '@${data['username']}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isYou ? AuraBuddyTheme.primary : AuraBuddyTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AuraBuddyTheme.primary.withOpacity(0.15),
                  AuraBuddyTheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                isAura ? '${data['aura']}' : '${data['value']}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AuraBuddyTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

