import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/aura_history_service.dart';
import '../services/moderation_service.dart';
import '../screens/user_profile_screen.dart';
import '../screens/discover_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'aura_coin_icon.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final ValueChanged<int>? onAuraGiven;
  final Function(String)? onHashtagTap;

  const PostCard({
    super.key,
    required this.post,
    this.onAuraGiven,
    this.onHashtagTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _navigateToProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(username: username),
      ),
    );
  }

  void _showAuraPicker(bool isPositive) {
    if (widget.post.hasVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You already voted on this post',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AuraBuddyTheme.textMedium,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final isPremium = context.read<AuthService>().isPremium;
    final tiers =
        isPositive
            ? (isPremium ? [10, 50, 100, 200] : [10, 50, 100])
            : (isPremium ? [10, 25, 50, 100] : [10, 25, 50]);

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraBuddyTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPositive ? 'Give Aura ' : 'Hater Tax 🔥',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AuraBuddyTheme.textDark,
                      ),
                    ),
                    if (isPositive) const AuraCoinIcon(size: 24),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPositive
                      ? 'How much aura do you want to give?'
                      : 'Costs 2× the amount from your balance',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AuraBuddyTheme.textMedium,
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AuraBuddyTheme.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '⭐ Premium tiers unlocked',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AuraBuddyTheme.gold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      tiers.map((amount) {
                        final isPremiumTier =
                            (isPositive && amount == 200) ||
                            (!isPositive && amount == 100);
                        final color =
                            isPositive
                                ? AuraBuddyTheme.primary
                                : AuraBuddyTheme.danger;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _applyVote(isPositive, amount);
                          },
                          child: Container(
                            width:
                                (MediaQuery.of(ctx).size.width -
                                    48 -
                                    (tiers.length > 3 ? 30 : 20)) /
                                (tiers.length > 3 ? 4 : 3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color:
                                  isPremiumTier
                                      ? AuraBuddyTheme.gold.withValues(
                                        alpha: 0.08,
                                      )
                                      : color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isPremiumTier
                                        ? AuraBuddyTheme.gold.withValues(
                                          alpha: 0.3,
                                        )
                                        : color.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (isPremiumTier)
                                  Text(
                                    '⭐',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                Text(
                                  '${isPositive ? '+' : '-'}$amount',
                                  style: GoogleFonts.inter(
                                    fontSize: isPremiumTier ? 20 : 22,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isPremiumTier
                                            ? AuraBuddyTheme.gold
                                            : color,
                                  ),
                                ),
                                if (!isPositive)
                                  Text(
                                    'Cost: ${amount * 2}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AuraBuddyTheme.textLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _applyVote(bool isPositive, int amount) async {
    final apiService = context.read<ApiService>();
    final auth = context.read<AuthService>();

    try {
      if (isPositive) {
        await apiService.transferAura(widget.post.id, amount);
      } else {
        await apiService.haterTax(widget.post.id, amount);
      }
      
      setState(() {
        widget.post.hasVoted = true;
        if (isPositive) {
          widget.post.auraScore += amount;
        } else {
          widget.post.auraScore -= amount;
        }
      });

      // Sync user balance from backend
      await auth.loadUserFromBackend(apiService);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPositive
                ? 'Aura given to @${widget.post.authorUsername}'
                : 'Hater tax applied',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor:
              isPositive ? AuraBuddyTheme.success : AuraBuddyTheme.danger,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Action failed: $e',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AuraBuddyTheme.danger,
        ),
      );
    }
  }

  void _addComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (ModerationService.containsBadWords(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Please keep comments friendly and respectful.',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AuraBuddyTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      widget.post.comments.add(
        CommentModel(
          id: widget.post.comments.length + 1,
          username: 'you',
          content: ModerationService.censorText(content),
          createdAt: DateTime.now(),
        ),
      );
    });
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _reportContent(String id, String type) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AuraBuddyTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Report $type',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Spam'),
                  onTap: () => _submitReport(id, type, 'spam', ctx),
                ),
                ListTile(
                  title: const Text('Harassment'),
                  onTap: () => _submitReport(id, type, 'harassment', ctx),
                ),
                ListTile(
                  title: const Text('Inappropriate'),
                  onTap: () => _submitReport(id, type, 'inappropriate', ctx),
                ),
              ],
            ),
          ),
    );
  }

  void _submitReport(String id, String type, String reason, BuildContext ctx) {
    ModerationService.reportContent(
      contentId: id,
      contentType: type,
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

  void _showReplyInput(CommentModel comment) {
    final replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraBuddyTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(left: 140),
                  decoration: BoxDecoration(
                    color: AuraBuddyTheme.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reply to @${comment.username}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AuraBuddyTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        maxLength: 200,
                        autofocus: true,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AuraBuddyTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a reply...',
                          counterText: '',
                          hintStyle: GoogleFonts.inter(
                            color: AuraBuddyTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final content = replyController.text.trim();
                        if (content.isNotEmpty) {
                          if (ModerationService.containsBadWords(content)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '⚠️ Please keep replies respectful.',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: AuraBuddyTheme.warning,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            comment.replies.add(
                              CommentReply(
                                id: comment.replies.length + 1,
                                username: 'you',
                                content: ModerationService.censorText(content),
                                createdAt: DateTime.now(),
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AuraBuddyTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isPositive = post.auraScore >= 0;
    final auth = context.read<AuthService>();
    final isPremium = auth.isPremium;
    final isAuthor = post.authorUsername == auth.username;
    final daysElapsed = DateTime.now().difference(post.createdAt).inDays;
    final maxDays = isPremium ? 14 : 7;
    final daysLeft = (maxDays - daysElapsed).clamp(0, maxDays);

    return Container(
      decoration: AuraBuddyTheme.whiteCard(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author Row ──────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (post.authorUsername != null) {
                          _navigateToProfile(post.authorUsername!);
                        }
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AuraBuddyTheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: post.authorAvatarUrl != null
                            ? NetworkImage(post.authorAvatarUrl!)
                            : null,
                        child: post.authorAvatarUrl == null
                            ? Text(
                                (post.authorUsername ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: AuraBuddyTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (post.authorUsername != null) {
                                _navigateToProfile(post.authorUsername!);
                              }
                            },
                            child: Text(
                              '@${post.authorUsername ?? 'unknown'}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AuraBuddyTheme.textDark,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _timeAgo(post.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AuraBuddyTheme.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AuraBuddyTheme.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Expires in $daysLeft d',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AuraBuddyTheme.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive
                                ? AuraBuddyTheme.primary
                                : AuraBuddyTheme.danger)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isPositive ? '+' : ''}${post.auraScore}',
                            style: GoogleFonts.inter(
                              color:
                                  isPositive
                                      ? AuraBuddyTheme.primary
                                      : AuraBuddyTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const AuraCoinIcon(size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Content ──────────────────
                Text(
                  post.caption,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AuraBuddyTheme.textDark,
                    height: 1.5,
                  ),
                ),

                // ── Hashtags ─────────────────
                if (post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children:
                        post.hashtags
                            .map(
                              (t) => GestureDetector(
                                  onTap: () {
                                    if (widget.onHashtagTap != null) {
                                      widget.onHashtagTap!(t);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DiscoverScreen(initialHashtag: t),
                                        ),
                                      );
                                    }
                                  },
                                child: Text(
                                  t,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AuraBuddyTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Post Image ──────────────────
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierDismissible: true,
                    barrierColor: Colors.black.withOpacity(0.9),
                    pageBuilder: (BuildContext context, _, __) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Center(
                                child: Hero(
                                  tag: 'discover_${post.id}_${post.imageUrl}',
                                  child: Image.network(
                                    post.imageUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Hero(
                tag: 'discover_${post.id}_${post.imageUrl}',
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color: AuraBuddyTheme.surfaceVariant,
                  child: Image.network(
                    post.imageUrl!,
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
              ),
            ),

          // ── Action Row ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (!isAuthor) ...[
                  _PostAction(
                    icon: Icons.bolt_rounded,
                    label: '+Aura',
                    color:
                        post.hasVoted
                            ? AuraBuddyTheme.textLight
                            : AuraBuddyTheme.primary,
                    onTap: () => _showAuraPicker(true),
                  ),
                  const SizedBox(width: 8),
                  _PostAction(
                    icon: Icons.whatshot_rounded,
                    label: 'Hater',
                    color:
                        post.hasVoted
                            ? AuraBuddyTheme.textLight
                            : AuraBuddyTheme.danger,
                    onTap: () => _showAuraPicker(false),
                  ),
                  const SizedBox(width: 8),
                ],
                _PostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments.length}',
                  color: AuraBuddyTheme.textMedium,
                  onTap: () => setState(() => _showComments = !_showComments),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _reportContent(post.id.toString(), 'post'),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: AuraBuddyTheme.textLight,
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    final shareText = 'Check this post on Aura Buddy:\n\n'
                        '${post.caption}\n\n'
                        '${post.hashtags.join(' ')}\n\n'
                        '#aura #growth #aurabuddy';
                    Share.share(shareText);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📤 Sharing post...'),
                        backgroundColor: AuraBuddyTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: AuraBuddyTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // ── Comments Section ──────────
          if (_showComments) ...[
            Container(
              color: AuraBuddyTheme.surfaceVariant.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.comments.isNotEmpty) ...[
                    ...post.comments
                        .take(5)
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap:
                                          () => _navigateToProfile(c.username),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AuraBuddyTheme.primary
                                            .withOpacity(0.1),
                                        child: Text(
                                          c.username[0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: AuraBuddyTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap:
                                                () => _navigateToProfile(
                                                  c.username,
                                                ),
                                            child: Text(
                                              '@${c.username}',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: AuraBuddyTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.content,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AuraBuddyTheme.textMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showReplyInput(c),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                              right: 12,
                                            ),
                                            child: Text(
                                              'Reply',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AuraBuddyTheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap:
                                              () => _reportContent(
                                                c.id.toString(),
                                                'comment',
                                              ),
                                          child: Icon(
                                            Icons.flag_rounded,
                                            size: 12,
                                            color: AuraBuddyTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Replies
                                if (c.replies.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 32,
                                      top: 6,
                                    ),
                                    child: Column(
                                      children:
                                          c.replies
                                              .map(
                                                (r) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 6,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      GestureDetector(
                                                        onTap:
                                                            () =>
                                                                _navigateToProfile(
                                                                  r.username,
                                                                ),
                                                        child: CircleAvatar(
                                                          radius: 10,
                                                          backgroundColor:
                                                              AuraBuddyTheme
                                                                  .primaryLight
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                          child: Text(
                                                            r.username[0]
                                                                .toUpperCase(),
                                                            style: GoogleFonts.inter(
                                                              color:
                                                                  AuraBuddyTheme
                                                                      .primaryLight,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 9,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text:
                                                                    '@${r.username} ',
                                                                style: GoogleFonts.inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 11,
                                                                  color:
                                                                      AuraBuddyTheme
                                                                          .textDark,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text: r.content,
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 11,
                                                                  color:
                                                                      AuraBuddyTheme
                                                                          .textMedium,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
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
                    if (post.comments.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'View all ${post.comments.length} comments',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AuraBuddyTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  // Comment input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLength: 200,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AuraBuddyTheme.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AuraBuddyTheme.textLight,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addComment,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AuraBuddyTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

