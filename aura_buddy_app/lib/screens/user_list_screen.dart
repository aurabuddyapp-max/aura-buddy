import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/follow_service.dart';
import 'package:provider/provider.dart';
import 'public_profile_screen.dart';

class UserListScreen extends StatefulWidget {
  final String title;
  final List<String> usernames;

  const UserListScreen({
    super.key,
    required this.title,
    required this.usernames,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  Widget build(BuildContext context) {
    final followService = context.watch<FollowService>();

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      appBar: AppBar(
        backgroundColor: AuraBuddyTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AuraBuddyTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: AuraBuddyTheme.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: widget.usernames.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.usernames.length,
                  itemBuilder: (context, index) {
                    final username = widget.usernames[index];
                    final isFollowing = followService.isFollowing(username);
                    
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PublicProfileScreen(username: username)),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AuraBuddyTheme.primary.withOpacity(0.1),
                        child: Text(
                          username[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AuraBuddyTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Aura User',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.textMedium,
                          fontSize: 12,
                        ),
                      ),
                      trailing: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isFollowing) {
                              followService.unfollow(username);
                            } else {
                              followService.follow(username);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? AuraBuddyTheme.surfaceVariant : AuraBuddyTheme.textDark,
                            foregroundColor: isFollowing ? AuraBuddyTheme.textDark : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AuraBuddyTheme.textLight),
          const SizedBox(height: 16),
          Text(
            'No users here yet.',
            style: GoogleFonts.inter(
              color: AuraBuddyTheme.textMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
