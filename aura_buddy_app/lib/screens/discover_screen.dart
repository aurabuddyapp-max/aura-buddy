import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/post_card.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class DiscoverScreen extends StatefulWidget {
  final String? initialHashtag;

  const DiscoverScreen({super.key, this.initialHashtag});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late TabController _tabController;
  
  String _searchQuery = '';
  List<PostModel> _allPosts = [];
  bool _isLoading = true;

  // Mock available hashtags for autocomplete
  final List<String> _popularHashtags = [
    '#motivation', '#motivationdaily', '#morning', '#fitness', '#health',
    '#breakfast', '#nature', '#peace', '#books', '#reading', '#gym',
    '#workout', '#dogs', '#volunteer', '#fashion', '#style', '#mealprep',
    '#story', '#growth'
  ];

  List<MapEntry<String, int>> get _dynamicPopularHashtagsWithCounts {
    final Map<String, int> counts = {};
    final Map<String, int> auraGains = {};
    final Map<String, int> recentWeight = {};
    
    final now = DateTime.now();
    
    for (var post in _allPosts) {
      for (var tag in post.hashtags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
        auraGains[tag] = (auraGains[tag] ?? 0) + post.auraScore;
        
        // Recent usage (last 24h)
        if (now.difference(post.createdAt).inHours < 24) {
          recentWeight[tag] = (recentWeight[tag] ?? 0) + 5; // Weight of 5 for recent
        }
      }
    }
    
    // hashtagScore = postCount * 3 + auraReceived * 2 + recentUsageWeight
    final scores = counts.keys.map((tag) {
      int score = (counts[tag]! * 3) + (auraGains[tag]! * 2) + (recentWeight[tag] ?? 0);
      return MapEntry(tag, score);
    }).toList();

    scores.sort((a, b) => b.value.compareTo(a.value));
    return scores;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialHashtag != null) {
      _searchController.text = widget.initialHashtag!;
      _searchQuery = widget.initialHashtag!;
      _tabController.index = 0; // Show filtered feed instead of hashtag tab
    }
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _loadDiscoverPosts();
  }

  void _loadDiscoverPosts() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final results = _searchQuery.isEmpty 
          ? await apiService.getFeed()
          : await apiService.getPostsByHashtag(_searchQuery.replaceAll('#', ''));
      
      setState(() {
        _allPosts = results.map((p) => PostModel.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading discover posts: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate trending score: (aura*3) + (comments*4) + (saves*2) - (hours*0.5)
  double _calculateTrendingScore(PostModel post) {
    int aura = post.auraScore;
    int comments = post.comments.length;
    int saves = 0; // Mock saved count
    double hoursSincePost = DateTime.now().difference(post.createdAt).inMinutes / 60.0;
    
    return (aura * 3) + (comments * 4) + (saves * 2) - (hoursSincePost * 0.5);
  }

  List<PostModel> get _trendingPosts {
    List<PostModel> list = _searchQuery.isEmpty 
      ? List<PostModel>.from(_allPosts)
      : _searchFilteredPosts;
    list.sort((a, b) => _calculateTrendingScore(b).compareTo(_calculateTrendingScore(a)));
    return list;
  }

  List<PostModel> get _latestPosts {
    List<PostModel> list = _searchQuery.isEmpty 
      ? List<PostModel>.from(_allPosts)
      : _searchFilteredPosts;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<PostModel> get _searchFilteredPosts {
    if (_searchQuery.isEmpty) return _allPosts;
    
    final query = _searchQuery.toLowerCase();
    return _allPosts.where((post) {
      final matchesHashtag = post.hashtags.any((tag) => tag.toLowerCase().contains(query));
      final matchesContent = post.caption.toLowerCase().contains(query);
      final matchesUser = (post.authorUsername ?? '').toLowerCase().contains(query);
      return matchesHashtag || matchesContent || matchesUser;
    }).toList();
  }

  void _showPostDialog(PostModel post) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.8),
        pageBuilder: (BuildContext context, _, __) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AuraBuddyTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    child: PostCard(
                      post: post,
                      onAuraGiven: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_searchQuery.isEmpty || !_searchQuery.startsWith('#')) return const SizedBox.shrink();
    
    final suggestions = _popularHashtags.where(
      (h) => h.toLowerCase().startsWith(_searchQuery.toLowerCase()) && h.toLowerCase() != _searchQuery.toLowerCase()
    ).take(5).toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AuraBuddyTheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestions.map((tag) => InkWell(
          onTap: () {
            _searchController.text = tag;
            _searchController.selection = TextSelection.fromPosition(TextPosition(offset: tag.length));
            _searchFocusNode.unfocus();
            _tabController.index = 0; // Move to feed to show results
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 18, color: AuraBuddyTheme.textMedium),
                const SizedBox(width: 12),
                Text(
                  tag,
                  style: GoogleFonts.inter(
                    color: AuraBuddyTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.north_west_rounded, size: 16, color: AuraBuddyTheme.textLight),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSplitCardFeed(List<PostModel> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: AuraBuddyTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No posts found for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AuraBuddyTheme.textMedium,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (posts == _trendingPosts) _buildTrendingTopicsBar(),
        Expanded(
          child: MasonryGridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildMasonryCard(post);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTopicsBar() {
    final topTags = _dynamicPopularHashtagsWithCounts.take(8).toList();
    if (topTags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: topTags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = topTags[index].key;
          return GestureDetector(
            onTap: () {
              _searchController.text = tag;
              _searchController.selection = TextSelection.fromPosition(TextPosition(offset: tag.length));
              _searchFocusNode.unfocus();
              setState(() => _searchQuery = tag);
              _tabController.index = 0;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: index == 0 
                    ? LinearGradient(colors: [AuraBuddyTheme.primary, AuraBuddyTheme.primary.withOpacity(0.8)])
                    : null,
                color: index != 0 ? AuraBuddyTheme.surfaceVariant : null,
                borderRadius: BorderRadius.circular(20),
                border: index == 0 ? null : Border.all(color: AuraBuddyTheme.textLight.withOpacity(0.2)),
              ),
              child: Center(
                child: Row(
                  children: [
                    if (index == 0) const Text('🔥 ', style: TextStyle(fontSize: 14)),
                    Text(
                      tag,
                      style: GoogleFonts.inter(
                        color: index == 0 ? Colors.white : AuraBuddyTheme.textDark,
                        fontWeight: index == 0 ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasonryCard(PostModel post) {
    return GestureDetector(
      onTap: () => _showPostDialog(post),
      child: Container(
        decoration: BoxDecoration(
          color: AuraBuddyTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.imageUrl != null)
                Hero(
                  tag: 'discover_${post.id}_${post.imageUrl}',
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.caption,
                      maxLines: post.imageUrl != null ? 3 : 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AuraBuddyTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: post.hashtags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            color: AuraBuddyTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AuraBuddyTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${post.auraScore} ',
                                style: GoogleFonts.inter(
                                  color: AuraBuddyTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              AuraBuddyTheme.auraIcon(size: 14),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chat_bubble_rounded, size: 12, color: AuraBuddyTheme.textMedium),
                        const SizedBox(width: 4),
                        Text(
                          '${post.comments.length}',
                          style: GoogleFonts.inter(
                            color: AuraBuddyTheme.textMedium,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      appBar: AppBar(
        backgroundColor: AuraBuddyTheme.surface,
        elevation: 0,
        titleSpacing: 8,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.inter(color: AuraBuddyTheme.textDark),
          decoration: InputDecoration(
            hintText: 'Search posts, people, hashtags...',
            hintStyle: GoogleFonts.inter(color: AuraBuddyTheme.textLight),
            prefixIcon: const Icon(Icons.search, color: AuraBuddyTheme.textMedium),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: AuraBuddyTheme.textMedium),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
            filled: true,
            fillColor: AuraBuddyTheme.background, // Match background so it stands out on surface
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AuraBuddyTheme.textDark,
          indicatorWeight: 3,
          labelColor: AuraBuddyTheme.textDark,
          unselectedLabelColor: AuraBuddyTheme.textLight,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Latest'),
            Tab(text: 'Hashtags'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AuraBuddyTheme.primary))
          : Column(
              children: [
                if (_searchFocusNode.hasFocus) _buildSuggestions(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _isLoading = true);
                      await Future.delayed(const Duration(milliseconds: 800));
                      _loadDiscoverPosts();
                    },
                    color: AuraBuddyTheme.primary,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSplitCardFeed(_trendingPosts),
                        _buildSplitCardFeed(_latestPosts),
                        _buildHashtagList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHashtagList() {
    final trendingHashtags = _dynamicPopularHashtagsWithCounts.take(15).toList();
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: trendingHashtags.length,
      separatorBuilder: (context, index) => Divider(
        color: AuraBuddyTheme.textLight.withOpacity(0.1),
        indent: 64,
      ),
      itemBuilder: (context, index) {
        final entry = trendingHashtags[index];
        final tag = entry.key;
        final count = entry.value;
        return InkWell(
          onTap: () {
            setState(() {
              _searchController.text = tag;
              _searchQuery = tag;
              _tabController.index = 0; // Show Trending posts for this tag
            });
            _searchFocusNode.unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AuraBuddyTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('#', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AuraBuddyTheme.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count posts',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.textMedium,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.trending_up_rounded,
                  color: AuraBuddyTheme.success,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
