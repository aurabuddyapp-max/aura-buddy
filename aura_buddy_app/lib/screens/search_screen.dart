import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import 'user_profile_screen.dart';
import 'package:aura_buddy_app/screens/discover_screen.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  int _tabIndex = 0; // 0 = users, 1 = hashtags
  String _query = '';

  List<UserProfileModel> _userResults = [];
  List<Map<String, dynamic>> _hashtagResults = [];
  bool _isLoading = false;
  bool _isHashtagLoading = false;

  void _onSearchChanged(String v) {
    setState(() => _query = v);
    if (_tabIndex == 0) {
      if (v.length >= 2) _performSearch(v);
    } else {
      _performHashtagSearch(v);
    }
  }

  Future<void> _performSearch(String q) async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.searchUsers(q);
      setState(() {
        _userResults = results.map((u) => UserProfileModel.fromJson(u)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performHashtagSearch(String q) async {
    setState(() => _isHashtagLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.getHashtagSearch(q);
      setState(() {
        _hashtagResults = results.map((h) => {
          'tag': h['hashtag'],
          'posts': h['post_count'],
          'trending': (h['post_count'] as int) > 10, // Simple trending logic
        }).toList();
        _isHashtagLoading = false;
      });
    } catch (e) {
      debugPrint('Hashtag search error: $e');
      setState(() => _isHashtagLoading = false);
    }
  }

  void _navigateToProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(username: username),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Search',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white),
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search users or #hashtags...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tabs ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _SearchTab(
                  label: 'Users',
                  isActive: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 8),
                _SearchTab(
                  label: 'Hashtags',
                  isActive: _tabIndex == 1,
                  onTap: () {
                    setState(() => _tabIndex = 1);
                    _performHashtagSearch(_query);
                  },
                ),
              ],
            ),
          ),

          // ── Results ────────────────────────────────
          Expanded(
            child:
                _tabIndex == 0 ? _buildUserResults() : _buildHashtagResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = _userResults;
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 48,
              color: AuraBuddyTheme.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              _query.isEmpty ? 'Search for your friends' : 'No users found',
              style: GoogleFonts.inter(color: AuraBuddyTheme.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final user = users[i];
        return GestureDetector(
          onTap: () => _navigateToProfile(user.username),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AuraBuddyTheme.whiteCard(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AuraBuddyTheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(
                    user.username[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AuraBuddyTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '@${user.username}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AuraBuddyTheme.textDark,
                            ),
                          ),
                          if (user.isPremium) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AuraBuddyTheme.gold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⭐',
                                style: GoogleFonts.inter(fontSize: 8),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.bio != null)
                      Text(
                        user.bio!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AuraBuddyTheme.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user.auraPoints} ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AuraBuddyTheme.primary,
                        ),
                      ),
                      AuraBuddyTheme.auraIcon(size: 14),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHashtagResults() {
    if (_isHashtagLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tags = _hashtagResults;
    if (tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag_rounded, size: 48, color: AuraBuddyTheme.textLight),
            const SizedBox(height: 8),
            Text(
              'No hashtags found',
              style: GoogleFonts.inter(color: AuraBuddyTheme.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tags.length,
      itemBuilder: (ctx, i) {
        final tag = tags[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscoverScreen(initialHashtag: tag['tag']),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AuraBuddyTheme.whiteCard(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AuraBuddyTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tag_rounded,
                    color: AuraBuddyTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag['tag'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AuraBuddyTheme.primary,
                        ),
                      ),
                      Text(
                        '${tag['posts']} posts',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AuraBuddyTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tag['trending'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AuraBuddyTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔥 Trending',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AuraBuddyTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SearchTab({
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
                color: isActive ? AuraBuddyTheme.textOnPrimary : AuraBuddyTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

