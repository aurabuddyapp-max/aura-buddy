import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/aura_history_service.dart';
import '../models/models.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  String? _todayMood;
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '🤩', 'label': 'Excited', 'color': const Color(0xFFFFD700)},
    {'emoji': '😊', 'label': 'Happy', 'color': const Color(0xFF10B981)},
    {'emoji': '😌', 'label': 'Calm', 'color': const Color(0xFF8B5CF6)},
    {'emoji': '😴', 'label': 'Tired', 'color': const Color(0xFF6B7280)},
    {'emoji': '😔', 'label': 'Sad', 'color': const Color(0xFF3B82F6)},
    {'emoji': '😡', 'label': 'Angry', 'color': const Color(0xFFEF4444)},
    {'emoji': '🤢', 'label': 'Sick', 'color': const Color(0xFF059669)},
  ];

  DateTime? _lastClaimTime;

  // Real mood history (last 7 days)
  final List<Map<String, String>> _moodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> _loadMoodData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load last claim time
    final lastClaim = prefs.getString('last_mood_claim');
    if (lastClaim != null) {
      _lastClaimTime = DateTime.parse(lastClaim);
    }

    // Load today's mood
    final today = DateTime.now();
    final savedToday = prefs.getString('mood_${_dateKey(today)}');

    // Load last 7 days history
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find the date for the Monday of this week
    final todayWeekday = today.weekday; // 1 = Mon, 7 = Sun
    final monday = today.subtract(Duration(days: todayWeekday - 1));

    _moodHistory.clear();
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final emoji = prefs.getString('mood_${_dateKey(d)}') ?? '';
      _moodHistory.add({
        'day': dayNames[i],
        'emoji': emoji,
        'isToday':
            (d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day)
                ? 'true'
                : 'false',
      });
    }

    if (mounted) {
      setState(() {
        _todayMood = savedToday;
      });
    }
  }

  Future<void> _selectMood(String emoji, String label) async {
    final now = DateTime.now();

    if (_lastClaimTime != null) {
      final hoursSinceLastClaim = now.difference(_lastClaimTime!).inHours;
      if (hoursSinceLastClaim < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⏳ Selection locked. You can update your mood again in ${12 - hoursSinceLastClaim}h.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AuraBuddyTheme.warning,
          ),
        );
        return;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AuraBuddyTheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Check In?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AuraBuddyTheme.textDark,
              ),
            ),
            content: Text(
              'Do you want to check in as $emoji and claim +10 Aura? This will lock your selection for 12 hours.',
              style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraBuddyTheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Confirm +10 '),
                    AuraBuddyTheme.auraIcon(size: 16),
                  ],
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final apiService = context.read<ApiService>();
      final auth = context.read<AuthService>();

      try {
        await apiService.claimMoodReward();
        await auth.loadUserFromBackend(apiService);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_mood_claim', now.toIso8601String());
        await prefs.setString('mood_${_dateKey(now)}', emoji);

        setState(() {
          _lastClaimTime = now;
          _todayMood = emoji;
          final todayWeekday = now.weekday - 1;
          if (todayWeekday >= 0 && todayWeekday < _moodHistory.length) {
            _moodHistory[todayWeekday]['emoji'] = emoji;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(
                    '$emoji Mood set! Selection locked for 12h. +10 Aura ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  AuraBuddyTheme.auraIcon(size: 16),
                ],
              ),
              backgroundColor: AuraBuddyTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selection locked or error: $e',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AuraBuddyTheme.warning,
            ),
          );
        }
      }
    }
  }

  // Count streak
  int get _moodStreak {
    int streak = 0;
    for (int i = _moodHistory.length - 1; i >= 0; i--) {
      if (_moodHistory[i]['emoji']!.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                          'Mood Tracker',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (_moodStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🔥 $_moodStreak day streak',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastClaimTime != null)
                      Text(
                        'Next claim available in: ${12 - DateTime.now().difference(_lastClaimTime!).inHours > 0 ? '${12 - DateTime.now().difference(_lastClaimTime!).inHours}h' : 'Ready to claim!'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _todayMood != null
                          ? 'Today you feel $_todayMood'
                          : 'How are you feeling today?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mood Picker ──────────────────
                  Text(
                    _todayMood != null
                        ? 'Change your mood'
                        : 'Select your mood',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _moods.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final mood = _moods[index];
                        final isSelected = _todayMood == mood['emoji'];
                        final isLocked = _lastClaimTime != null && 
                                        DateTime.now().difference(_lastClaimTime!).inHours < 12;

                        return GestureDetector(
                          onTap: isLocked && !isSelected ? null : () => _selectMood(mood['emoji'], mood['label']),
                          child: Opacity(
                            opacity: (isLocked && !isSelected) ? 0.5 : 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 72,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (mood['color'] as Color).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: isSelected
                                    ? Border.all(color: mood['color'] as Color, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    mood['emoji'],
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mood['label'],
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? mood['color'] as Color : AuraBuddyTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Weekly Mood Calendar ─────────
                  Text(
                    'This Week',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AuraBuddyTheme.whiteCard(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _moodHistory.map((day) {
                            final hasEmoji = day['emoji']!.isNotEmpty;
                            double heightMultiplier = 0.2;
                            Color barColor = AuraBuddyTheme.surfaceVariant;
                            
                            if (hasEmoji) {
                              final moodData = _moods.firstWhere(
                                (m) => m['emoji'] == day['emoji'],
                                orElse: () => _moods[1],
                              );
                              barColor = moodData['color'];
                              // Assign arbitrary height for "chart" feel
                              switch (day['emoji']) {
                                case '🤩': heightMultiplier = 1.0; break;
                                case '😊': heightMultiplier = 0.8; break;
                                case '😌': heightMultiplier = 0.7; break;
                                case '😴': heightMultiplier = 0.4; break;
                                case '😔': heightMultiplier = 0.3; break;
                                case '😡': heightMultiplier = 0.5; break;
                                case '🤢': heightMultiplier = 0.2; break;
                              }
                            }

                            final isToday = day['isToday'] == 'true';

                            return Column(
                              children: [
                                Container(
                                  width: 30,
                                  height: 100 * heightMultiplier,
                                  decoration: BoxDecoration(
                                    color: barColor.withValues(alpha: isToday ? 1.0 : 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: hasEmoji ? Center(
                                    child: Text(day['emoji']!, style: const TextStyle(fontSize: 14)),
                                  ) : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  day['day']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                    color: isToday ? AuraBuddyTheme.primary : AuraBuddyTheme.textLight,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Mood Insights Card ──────────
                  Text(
                    'Insights',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AuraBuddyTheme.whiteCard(),
                    child: Column(
                      children: [
                        _InsightRow(
                          icon: const Text('😊', style: TextStyle(fontSize: 20)),
                          label: 'Most frequent mood',
                          value: 'Happy',
                        ),
                        const Divider(height: 20),
                        _InsightRow(
                          icon: const Text('🔥', style: TextStyle(fontSize: 20)),
                          label: 'Longest streak',
                          value: '5 days',
                        ),
                        const Divider(height: 20),
                        _InsightRow(
                          icon: const Text('📊', style: TextStyle(fontSize: 20)),
                          label: 'Moods tracked',
                          value: '23 total',
                        ),
                        const Divider(height: 20),
                        _InsightRow(
                          icon: AuraBuddyTheme.auraIcon(size: 20),
                          label: 'Aura earned',
                          value: '+115 from moods',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AuraBuddyTheme.textMedium,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AuraBuddyTheme.textDark,
          ),
        ),
      ],
    );
  }
}

