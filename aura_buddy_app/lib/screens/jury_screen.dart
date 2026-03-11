import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/aura_history_service.dart';
import 'discover_screen.dart';
import 'package:provider/provider.dart';

class JuryScreen extends StatefulWidget {
  const JuryScreen({super.key});

  @override
  State<JuryScreen> createState() => _JuryScreenState();
}

class _JuryScreenState extends State<JuryScreen> {
  List<PostModel> _juryPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJuryPosts();
  }

  void _loadJuryPosts() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.getFeed(); 
      setState(() {
        _juryPosts = results.map((p) => PostModel.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading jury posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _vote(int index, bool isValid) async {
    final post = _juryPosts[index];
    if (post.hasVoted) return;

    final apiService = context.read<ApiService>();
    final auth = context.read<AuthService>();

    try {
      final voteType = isValid ? 'aura' : 'hate';
      await apiService.castVote(post.id, voteType);
      
      setState(() {
        post.hasVoted = true;
        if (isValid) {
          post.auraScore += 1;
        } else {
          post.auraScore -= 1;
        }
      });

      // Refresh user balance as they earn 5 aura for voting
      await auth.loadUserFromBackend(apiService);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isValid ? '✅ Voted VALID — +5 Aura earned!' : '❌ Voted NOT VALID — +5 Aura earned!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: isValid ? AuraBuddyTheme.success : AuraBuddyTheme.danger,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    }
  }

  void _showAuraPicker(int index) {
    _vote(index, true); 
  }

  void _loadJuryPosts() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.getFeed(); // In future, use /jury/queue
      setState(() {
        _juryPosts = results.map((p) => PostModel.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading jury posts: $e');
      setState(() => _isLoading = false);
    }
  }
w  void _showAuraPicker(int index) {
    // Legacy aura picker for investing in missions. 
    // For now, simple voting rewards/taxes are handled in backend.
    _vote(index, true); 
  }
 );
  }

  String _missionEmoji(String type) {
    switch (type) {
      case 'FIT_CHECK':
        return '👗';
      case 'EAT_HEALTHY':
        return '🥗';
      case 'WORKOUT':
        return '💪';
      case 'STUDY_SESSION':
        return '📚';
      case 'RANDOM_ACT':
        return '✨';
      default:
        return '🎯';
    }
  }

  String _missionLabel(String type) {
    switch (type) {
      case 'FIT_CHECK':
        return 'Fit Check';
      case 'EAT_HEALTHY':
        return 'Eat Healthy';
      case 'WORKOUT':
        return 'Workout';
      case 'STUDY_SESSION':
        return 'Study Session';
      case 'RANDOM_ACT':
        return 'Random Act';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _juryPosts.where((p) => !p.hasVoted).length;

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Purple Gradient Header ─────────────────
          Container(
            width: double.infinity,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Jury Queue',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$pendingCount pending',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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

          // ── Mission Cards ──────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: AuraBuddyTheme.primary,
            child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _juryPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 56,
                            color: AuraBuddyTheme.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All caught up!',
                            style: GoogleFonts.inter(
                              color: AuraBuddyTheme.textLight,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _juryPosts.length,
                      itemBuilder: (ctx, i) {
                        final post = _juryPosts[i];
                        final isResolved = post.hasVoted;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: AuraBuddyTheme.whiteCard(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo placeholder
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      AuraBuddyTheme.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      AuraBuddyTheme.surfaceVariant,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                  child: post.imageUrl != null 
                                    ? Image.network(post.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                                    : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AuraBuddyTheme.auraIcon(size: 40),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Proof Photo',
                                            style: GoogleFonts.inter(
                                              color: AuraBuddyTheme.textLight,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Type badge + submitter
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AuraBuddyTheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'MISSION PROOF',
                                            style: GoogleFonts.inter(
                                              color: AuraBuddyTheme.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '@${post.authorUsername ?? 'unknown'}',
                                          style: GoogleFonts.inter(
                                            color: AuraBuddyTheme.textMedium,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Hashtags
                                    if (post.hashtags.isNotEmpty)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children:
                                            post.hashtags
                                                .map(
                                                  (tag) => GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => DiscoverScreen(initialHashtag: tag),
                                                        ),
                                                      );
                                                    },
                                                    child: Text(
                                                      tag,
                                                      style: GoogleFonts.inter(
                                                        color: AuraBuddyTheme.primary,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    if (post.hashtags.isNotEmpty)
                                      const SizedBox(height: 10),

                                    // Vote counts + Aura pool
                                    Row(
                                      children: [
                                        _VoteCount(
                                          label: 'Score',
                                          count: post.auraScore,
                                          color: post.auraScore >= 0 ? AuraBuddyTheme.success : AuraBuddyTheme.danger,
                                          icon: Icons.auto_awesome_rounded,
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Vote to earn Aura',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AuraBuddyTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Progress bar removed as it relied on mission specific vote counts
                                    const SizedBox(height: 14),

                                    // Status or vote buttons
                                    if (isResolved)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AuraBuddyTheme.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'VOTE CAST',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AuraBuddyTheme.success,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (post.hasVoted)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AuraBuddyTheme.textLight
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 16, color: AuraBuddyTheme.textMedium),
                                              const SizedBox(width: 8),
                                              Text(
                                                'ALREADY RESPONDED',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  letterSpacing: 1.1,
                                                  color: AuraBuddyTheme.textMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 46,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showAuraPicker(i),
                                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                                label: const Text('Valid'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AuraBuddyTheme.success,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  textStyle: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: SizedBox(
                                              height: 46,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _vote(i, false),
                                                icon: const Icon(Icons.cancel_rounded, size: 18),
                                                label: const Text('Cap'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AuraBuddyTheme.danger,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  textStyle: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
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
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _VoteCount({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.inter(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

