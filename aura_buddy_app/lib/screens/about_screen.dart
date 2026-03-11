import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                      'About Aura Buddy',
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

          // ── Content ────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/aura-app-logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built with ❤️ by the Aura Team',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AuraBuddyTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildAboutSection(
                    title: 'Our Mission',
                    content: 'Aura Buddy is a gamified social platform designed to encourage positivity and meaningful interactions. We believe that every positive action deserves recognition, and we\'ve built a system that turns social proof into a fun, rewarding experience.',
                  ),
                  const SizedBox(height: 24),
                  _buildAboutSection(
                    title: 'How it Works',
                    content: 'Users post photos of their positive actions, which are then voted on by the community "Jury". Earn Aura for being a good person, and use that Aura to climb the leaderboards and unlock exclusive rewards.',
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '© 2026 Aura Buddy Inc.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AuraBuddyTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AuraBuddyTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: AuraBuddyTheme.textDark,
          ),
        ),
      ],
    );
  }
}
