import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _auraAlerts = true;
  bool _juryAlerts = true;

  Future<void> _launchEmail(String subject) async {
    final String encodedSubject = Uri.encodeComponent('Aura Buddy App: $subject');
    final Uri emailUri = Uri.parse('mailto:aurabuddy.app@gmail.com?subject=$encodedSubject');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  void _showEditProfile() {
    final auth = context.read<AuthService>();
    final usernameController = TextEditingController(text: auth.username ?? '');
    final bioController = TextEditingController(text: auth.bio ?? '');

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
                  'Edit Profile',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AuraBuddyTheme.textDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile picture
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      maxHeight: 512,
                    );
                    
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final url = await auth.uploadAvatar(bytes, image.name);
                      
                      if (url != null) {
                        final apiService = context.read<ApiService>();
                        await apiService.updateProfile(avatarUrl: url);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '📷 Profile picture updated!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AuraBuddyTheme.success,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AuraBuddyTheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage:
                                auth.avatarUrl != null
                                    ? NetworkImage(auth.avatarUrl!)
                                    : null,
                            child:
                                auth.avatarUrl == null
                                    ? Icon(
                                      Icons.person_rounded,
                                      size: 36,
                                      color: AuraBuddyTheme.primary,
                                    )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AuraBuddyTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AuraBuddyTheme.background, width: 2),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: AuraBuddyTheme.textOnPrimary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Edit Photo',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AuraBuddyTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Username field
                TextField(
                  controller: usernameController,
                  style: GoogleFonts.inter(color: AuraBuddyTheme.textDark),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: AuraBuddyTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bio field
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  maxLength: 150,
                  style: GoogleFonts.inter(color: AuraBuddyTheme.textDark),
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell people about yourself...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.edit_rounded,
                        color: AuraBuddyTheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final apiService = context.read<ApiService>();
                      final newUsername = usernameController.text.trim();
                      if (newUsername.isNotEmpty && newUsername != auth.username) {
                        await auth.setUsername(newUsername, apiService);
                      }
                      
                      final newBio = bioController.text.trim();
                      if (newBio != auth.bio) {
                        await auth.setBio(newBio, apiService);
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('SAVE CHANGES'),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
    );
  }

  void _showSignOutConfirm() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AuraBuddyTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AuraBuddyTheme.textDark,
              ),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AuraBuddyTheme.textMedium),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<AuthService>().logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraBuddyTheme.danger,
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
    );
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Settings Content ───────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account
                  _SectionTitle(title: 'Account'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.person_rounded,
                          title: 'Edit Profile',
                          subtitle: 'Username, avatar, bio',
                          onTap: _showEditProfile,
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.shield_rounded,
                          title: 'Privacy',
                          subtitle: 'Who can see your activity',
                          badge: 'Soon',
                          onTap: () {},
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.lock_rounded,
                          title: 'Security',
                          subtitle: 'Password, two-factor auth',
                          badge: 'Soon',
                          onTap: () {},
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.redeem_rounded,
                          title: 'Redeem Aura',
                          subtitle: 'Convert aura to rewards',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: AuraBuddyTheme.background,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (ctx) => Padding(
                                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
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
                                    const SizedBox(height: 24),
                                    const Text('🎁', style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aura Marketplace',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AuraBuddyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Aura redemption is coming soon! You will be able to trade your aura for premium features, profile badges, and real-world perks.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AuraBuddyTheme.textMedium,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('EXCITED!'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications
                  _SectionTitle(title: 'Notifications'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SettingsToggle(
                          icon: Icons.notifications_rounded,
                          title: 'Push Notifications',
                          value: _pushNotifications,
                          onChanged:
                              (v) => setState(() => _pushNotifications = v),
                        ),
                        _divider(),
                        _SettingsToggle(
                          icon: Icons.bolt_rounded,
                          title: 'Aura Alerts',
                          subtitle: 'When someone gives you aura',
                          value: _auraAlerts,
                          onChanged: (v) => setState(() => _auraAlerts = v),
                        ),
                        _divider(),
                        _SettingsToggle(
                          icon: Icons.gavel_rounded,
                          title: 'Jury Alerts',
                          subtitle: 'When your mission gets votes',
                          value: _juryAlerts,
                          onChanged: (v) => setState(() => _juryAlerts = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Appearance
                  _SectionTitle(title: 'Appearance'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    clipBehavior: Clip.antiAlias,
                    child: _SettingsToggle(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Coming soon',
                      value: false,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Support & Feedback
                  _SectionTitle(title: 'Support & Feedback'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.bug_report_rounded,
                          title: 'Report Bug',
                          subtitle: 'Help us squash errors',
                          onTap: () => _launchEmail('Bug Report'),
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Suggest Feature',
                          subtitle: 'Have a cool idea?',
                          onTap: () => _launchEmail('Feature Suggestion'),
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.feedback_rounded,
                          title: 'Send Feedback',
                          subtitle: 'Tell us how we\'re doing',
                          onTap: () => _launchEmail('General Feedback'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About
                  _SectionTitle(title: 'About'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AuraBuddyTheme.whiteCard(),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _divider(),
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Version',
                          subtitle: '1.0.0 (Build 1)',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showSignOutConfirm,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'SIGN OUT',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraBuddyTheme.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
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

  Widget _divider() => Divider(
    height: 1,
    color: AuraBuddyTheme.textLight.withOpacity(0.15),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuraBuddyTheme.textMedium,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AuraBuddyTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AuraBuddyTheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AuraBuddyTheme.textDark,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AuraBuddyTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AuraBuddyTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AuraBuddyTheme.textLight,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: AuraBuddyTheme.textLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuraBuddyTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AuraBuddyTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AuraBuddyTheme.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AuraBuddyTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AuraBuddyTheme.primary,
          ),
        ],
      ),
    );
  }
}

