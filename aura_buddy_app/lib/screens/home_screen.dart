import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/post_card.dart';
import '../widgets/daily_streak_card.dart';
import '../widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'leaderboard_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PostModel> _posts = [];
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = true;
  String? _activeHashtag;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final postsJson = await apiService.getFeed();
      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(postsJson.map((j) => PostModel.fromJson(j)));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feed: $e')),
        );
      }
    }
  }

  List<PostModel> get _rankedPosts {
    // Backend returns sorted by newest, but we can still apply local ranking if desired
    return _posts;
  }

  void _showNewPostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => _NewPostSheet(
            controller: _postController,
            onPost: (caption, imageUrl, hashtags) async {
              try {
                final apiService = Provider.of<ApiService>(context, listen: false);
                await apiService.createPost(caption, imageUrl: imageUrl);
                Navigator.pop(ctx);
                _loadFeed(); // Refresh
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to post: $e')),
                );
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final notificationService = context.watch<NotificationService>();
    final greetingName = auth.username; // Use null if no username
    final unreadNotifCount = notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                              'Hi, there ${auth.username ?? 'Aura User'} 👋',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Aura Feed',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Header greeting is now standalone or followed by other icons
                    const SizedBox(width: 8),
                    // Leaderboard button
                    _HeaderIcon(
                      icon: Icons.emoji_events_rounded,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(width: 8),
                    // Notifications button
                    Stack(
                      children: [
                        _HeaderIcon(
                          icon: Icons.notifications_rounded,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              ),
                        ),
                        // Unread badge
                        if (unreadNotifCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AuraBuddyTheme.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AuraBuddyTheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$unreadNotifCount',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Post Feed ──────────────────────────────
          if (_activeHashtag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AuraBuddyTheme.primary.withOpacity(0.05),
              child: Row(
                children: [
                  Text(
                    'Filtering by: ',
                    style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium),
                  ),
                  Text(
                    _activeHashtag!,
                    style: GoogleFonts.inter(
                      color: AuraBuddyTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _activeHashtag = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AuraBuddyTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child:
                _isLoading
                    ? const FeedSkeleton(count: 3)
                    : _rankedPosts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.feed_rounded,
                            size: 56,
                            color: AuraBuddyTheme.textLight,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No posts yet\nBe the first to share your aura ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AuraBuddyTheme.textMedium,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              AuraBuddyTheme.auraIcon(size: 18),
                            ],
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      color: AuraBuddyTheme.primary,
                      onRefresh: _loadFeed,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount:
                            _rankedPosts.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: DailyStreakCard(),
                            );
                          }
                          final postIndex = i - 1;
                          final activePosts =
                              _rankedPosts;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PostCard(
                              post: activePosts[postIndex],
                              onHashtagTap:
                                  (tag) => setState(() => _activeHashtag = tag),
                              onAuraGiven: (amount) {},
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPostSheet,
        backgroundColor: AuraBuddyTheme.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28, color: AuraBuddyTheme.textOnPrimary),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}

// ── Header Icon Button ──────────────────────
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── New Post Bottom Sheet ────────────────────────
class _NewPostSheet extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String content, String? imageUrl, List<String> hashtags)
  onPost;

  const _NewPostSheet({required this.controller, required this.onPost});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  String? _selectedImageUrl;
  bool _isLoadingImage = false;
  final _hashtagController = TextEditingController();
  final List<String> _hashtags = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (image != null) {
      setState(() {
        _isLoadingImage = true;
      });
      
      try {
        final apiService = context.read<ApiService>();
        final bytes = await image.readAsBytes();
        final url = await apiService.uploadImage(bytes, image.name);
        
        if (mounted) {
          setState(() {
            _selectedImageUrl = url;
            _isLoadingImage = false;
          });
          
          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📷 Photo added!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: AuraBuddyTheme.primary,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      }
    }
  }

  void _addHashtag() {
    final tag = _hashtagController.text.trim();
    if (tag.isEmpty || _hashtags.length >= 3) return;
    setState(() {
      _hashtags.add(tag.startsWith('#') ? tag : '#$tag');
    });
    _hashtagController.clear();
  }

  @override
  void dispose() {
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
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
            'New Post',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AuraBuddyTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            maxLines: 4,
            maxLength: 1000,
            style: GoogleFonts.inter(color: AuraBuddyTheme.textDark),
            decoration: InputDecoration(
              hintText: 'Share your moment...',
              hintStyle: GoogleFonts.inter(color: AuraBuddyTheme.textLight),
              filled: true,
              fillColor: AuraBuddyTheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Image preview
          if (_isLoadingImage)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AuraBuddyTheme.primary)),
            )
          else if (_selectedImageUrl != null)
            Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AuraBuddyTheme.surfaceVariant,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _selectedImageUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 40,
                              color: AuraBuddyTheme.textLight,
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImageUrl = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Hashtags
          if (_hashtags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              children:
                  _hashtags
                      .map(
                        (t) => Chip(
                          label: Text(
                            t,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AuraBuddyTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _hashtags.remove(t)),
                          backgroundColor: AuraBuddyTheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Hashtag input
          if (_hashtags.length < 3)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hashtagController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AuraBuddyTheme.textDark,
                    ),
                    onSubmitted: (_) => _addHashtag(),
                    decoration: InputDecoration(
                      hintText: 'Add hashtag (max 3)...',
                      hintStyle: GoogleFonts.inter(
                        color: AuraBuddyTheme.textLight,
                        fontSize: 13,
                      ),
                      prefixText: '# ',
                      prefixStyle: GoogleFonts.inter(
                        color: AuraBuddyTheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AuraBuddyTheme.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _addHashtag,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AuraBuddyTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: AuraBuddyTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AuraBuddyTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_camera_rounded,
                        size: 18,
                        color: AuraBuddyTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Photo',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.controller.text.trim().isNotEmpty) {
                      widget.onPost(
                        widget.controller.text.trim(),
                        _selectedImageUrl,
                        _hashtags,
                      );
                      widget.controller.clear();
                    }
                  },
                  child: const Text('POST'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

