import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class DailyLoginDialog extends StatefulWidget {
  final VoidCallback? onRewardClaimed;

  const DailyLoginDialog({super.key, this.onRewardClaimed});

  /// Check and show daily login dialog if reward not yet claimed today
  static Future<void> checkAndShow(BuildContext context) async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;

    final lastClaim = auth.lastStreakClaimedAt;
    final today = DateTime.now();
    
    bool alreadyClaimed = false;
    if (lastClaim != null) {
      if (lastClaim.year == today.year && 
          lastClaim.month == today.month && 
          lastClaim.day == today.day) {
        alreadyClaimed = true;
      }
    }

    if (alreadyClaimed) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DailyLoginDialog(),
    );
  }

  @override
  State<DailyLoginDialog> createState() => _DailyLoginDialogState();
}

class _DailyLoginDialogState extends State<DailyLoginDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  int _currentStreak = 0;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final auth = context.read<AuthService>();
    setState(() {
      _currentStreak = auth.currentStreak;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_claimed) return;
    
    final apiService = context.read<ApiService>();
    final auth = context.read<AuthService>();

    try {
      setState(() => _claimed = true);
      await apiService.claimDailyStreakReward();
      await auth.loadUserFromBackend(apiService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 +${DailyLoginReward.rewards[_currentStreak.clamp(0, 6)]} Aura earned from daily login!',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: AuraBuddyTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _claimed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: AuraBuddyTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewards = DailyLoginReward.rewards;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF5F0FF)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📅', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    'Daily Login Reward!',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${_currentStreak + 1} streak',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AuraBuddyTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Day reward grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: 7,
                    itemBuilder: (ctx, i) {
                      final isPast = i < _currentStreak;
                      final isToday = i == _currentStreak;
                      final isFuture = i > _currentStreak;
                      final isDay7 = i == 6;

                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isPast
                                  ? AuraBuddyTheme.success.withValues(
                                    alpha: 0.1,
                                  )
                                  : isToday
                                  ? AuraBuddyTheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                  : AuraBuddyTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isToday
                                  ? Border.all(
                                    color: AuraBuddyTheme.primary,
                                    width: 2,
                                  )
                                  : isDay7 && isFuture
                                  ? Border.all(
                                    color: AuraBuddyTheme.gold.withValues(
                                      alpha: 0.3,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Day ${i + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isPast
                                        ? AuraBuddyTheme.success
                                        : isToday
                                        ? AuraBuddyTheme.primary
                                        : AuraBuddyTheme.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isPast)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AuraBuddyTheme.success,
                                size: 18,
                              )
                            else
                              Text(
                                '+${rewards[i]}',
                                style: GoogleFonts.inter(
                                  fontSize: isDay7 ? 16 : 14,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isToday
                                          ? AuraBuddyTheme.primary
                                          : isDay7
                                          ? AuraBuddyTheme.gold
                                          : AuraBuddyTheme.textMedium,
                                ),
                              ),
                            if (isDay7 && !isPast)
                              Text(
                                '🔥 Bonus',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AuraBuddyTheme.gold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _currentStreak == 6
                        ? '🔥 Streak bonus! Day 7!'
                        : 'Come back tomorrow for +${rewards[(_currentStreak + 1).clamp(0, 6)]} aura!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AuraBuddyTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _claimed ? null : _claimReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _claimed
                                ? AuraBuddyTheme.success
                                : AuraBuddyTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _claimed
                            ? '✅ Claimed!'
                            : 'CLAIM +${rewards[_currentStreak.clamp(0, 6)]} AURA',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

