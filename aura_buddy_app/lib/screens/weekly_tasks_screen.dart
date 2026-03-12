import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/task_service.dart';
import '../models/models.dart';

class WeeklyTasksScreen extends StatefulWidget {
  final VoidCallback? onAuraEarned;

  const WeeklyTasksScreen({super.key, this.onAuraEarned});

  @override
  State<WeeklyTasksScreen> createState() => _WeeklyTasksScreenState();
}

class _WeeklyTasksScreenState extends State<WeeklyTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiService = context.read<ApiService>();
      context.read<TaskService>().refreshMissions(apiService);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _timeRemainingWeekly(List<UserMissionModel> tasks) {
    if (tasks.isEmpty) return 'Refreshing...';
    // Simplified: Reset happens Sunday midnight
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final resetDate = DateTime(nextSunday.year, nextSunday.month, nextSunday.day);
    final remaining = resetDate.difference(now);
    if (remaining.isNegative) return 'Expiring soon';
    final d = remaining.inDays;
    final h = remaining.inHours % 24;
    return '${d}d ${h}h till reset';
  }

  Future<void> _claimReward(UserMissionModel um) async {
    final apiService = context.read<ApiService>();
    final auth = context.read<AuthService>();
    final tasksService = context.read<TaskService>();

    try {
      await tasksService.completeMission(apiService, um.id);
      await auth.loadUserFromBackend(apiService);
      
      widget.onAuraEarned?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 +${um.mission.auraReward} Aura earned!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: AuraBuddyTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to claim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksService = context.watch<TaskService>();
    final daily = tasksService.dailyTasks;
    final weekly = tasksService.weeklyTasks;
    final milestones = tasksService.milestones;

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
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
                        const SizedBox(width: 12),
                        Text(
                          'Missions & Tasks',
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Daily'),
                      Tab(text: 'Weekly'),
                      Tab(text: 'Milestones'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Content ──────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(daily, isMilestone: false, isLoading: tasksService.isLoading),
                _buildTaskList(weekly, isMilestone: false, header: _buildWeeklyHeader(weekly), isLoading: tasksService.isLoading),
                _buildTaskList(milestones, isMilestone: true, isLoading: tasksService.isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHeader(List<UserMissionModel> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AuraBuddyTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _timeRemainingWeekly(tasks),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AuraBuddyTheme.textDark),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<UserMissionModel> userMissions, {required bool isMilestone, Widget? header, bool isLoading = false}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (userMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_rounded, size: 56, color: AuraBuddyTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No missions available right now',
              style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TaskService>().refreshMissions(context.read<ApiService>()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userMissions.length + (header != null ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (header != null && i == 0) return header;
          
          final taskIndex = header != null ? i - 1 : i;
          final um = userMissions[taskIndex];
          final isCompleted = um.status == 'COMPLETED';
          final mission = um.mission;
          
          // Emojis based on type or name (simple mapping)
          Widget emojiIcon;
          if (mission.title.toLowerCase().contains('vote')) {
            emojiIcon = const Text('⚖️', style: TextStyle(fontSize: 22));
          } else if (mission.title.toLowerCase().contains('aura')) {
            emojiIcon = AuraBuddyTheme.auraIcon(size: 22);
          } else if (mission.title.toLowerCase().contains('post')) {
            emojiIcon = const Text('📝', style: TextStyle(fontSize: 22));
          } else if (mission.type == 'MILESTONE') {
            emojiIcon = const Text('👑', style: TextStyle(fontSize: 22));
          } else {
            emojiIcon = const Text('🎯', style: TextStyle(fontSize: 22));
          }
  
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: AuraBuddyTheme.whiteCard(),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AuraBuddyTheme.success.withOpacity(0.1)
                            : AuraBuddyTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: emojiIcon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AuraBuddyTheme.textDark),
                          ),
                          Text(
                            mission.description,
                            style: GoogleFonts.inter(fontSize: 12, color: AuraBuddyTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AuraBuddyTheme.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${mission.auraReward}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AuraBuddyTheme.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isCompleted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AuraBuddyTheme.textLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '✓ Completed',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AuraBuddyTheme.textMedium),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _claimReward(um),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraBuddyTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Complete Mission', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
