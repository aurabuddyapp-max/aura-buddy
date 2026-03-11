import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class DailyStreakCard extends StatelessWidget {
  const DailyStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final apiService = context.read<ApiService>();
    
    final lastClaimed = auth.lastStreakClaimedAt;
    final isClaimedToday = lastClaimed != null && 
        lastClaimed.year == DateTime.now().year &&
        lastClaimed.month == DateTime.now().month &&
        lastClaimed.day == DateTime.now().day;

    final streak = auth.currentStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraBuddyTheme.primary,
            const Color(0xFF6C63FF).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AuraBuddyTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Streak: $streak Days',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isClaimedToday ? 'Come back tomorrow!' : 'Claim your daily reward!',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Streak map (7 dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isTarget = index < streak;
              final isToday = index == streak && !isClaimedToday;
              
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isTarget 
                          ? Colors.white 
                          : isToday 
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: Center(
                      child: Icon(
                        isTarget ? Icons.check_rounded : Icons.star_rounded,
                        size: 16,
                        color: isTarget ? AuraBuddyTheme.primary : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'D${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          if (!isClaimedToday)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await auth.claimDailyStreak(apiService);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              AuraBuddyTheme.auraIcon(size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Daily reward claimed!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to claim: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AuraBuddyTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'CLAIM AURA',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
