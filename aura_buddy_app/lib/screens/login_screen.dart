import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showCredentialForm = false;
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn(Future<bool> Function() method) async {
    setState(() => _isLoading = true);
    await method();
    setState(() => _isLoading = false);
  }

  void _submitCredentials() async {
    final auth = context.read<AuthService>();
    if (_isRegisterMode) {
      if (_usernameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
    } else {
      if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your credentials')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await auth.register(
          _emailController.text.trim(),
          _passwordController.text,
          username: _usernameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please check your email for confirmation.'),
              backgroundColor: AuraBuddyTheme.success,
            ),
          );
        }
      } else {
        // In Supabase, if they enter an email in the "username" field, it works
        await auth.signInWithPassword(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'An error occurred';
        if (e.toString().contains('Invalid login credentials')) {
          message = 'Invalid email or password';
        } else if (e.toString().contains('User already registered')) {
          message = 'This email is already registered';
        } else if (e.toString().contains('Password should be at least 6 characters')) {
          message = 'Password must be at least 6 characters';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AuraBuddyTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Purple Header ────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 48),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/aura-app-logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aura Buddy',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Your social aura, gamified ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          AuraBuddyTheme.auraIcon(size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Login Content ────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Welcome!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AuraBuddyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AuraBuddyTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (!_showCredentialForm) ...[
                    // Social login buttons
                    _LoginButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continue with Google',
                      color: AuraBuddyTheme.primary,
                      isLoading: _isLoading,
                      onTap:
                          () => _signIn(
                            context.read<AuthService>().signInWithGoogle,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _LoginButton(
                      icon: Icons.apple_rounded,
                      label: 'Continue with Apple',
                      color: AuraBuddyTheme.textDark,
                      isLoading: _isLoading,
                      onTap:
                          () => _signIn(
                            context.read<AuthService>().signInWithApple,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AuraBuddyTheme.textLight.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: GoogleFonts.inter(
                              color: AuraBuddyTheme.textLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AuraBuddyTheme.textLight.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _LoginButton(
                      icon: Icons.person_rounded,
                      label: 'Login with Username',
                      color: AuraBuddyTheme.primary,
                      outlined: true,
                      isLoading: false,
                      onTap: () => setState(() => _showCredentialForm = true),
                    ),
                  ] else ...[
                    // Username/Password form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AuraBuddyTheme.whiteCard(),
                      child: Column(
                        children: [
                          // Toggle Login/Register
                          Row(
                            children: [
                              _TabButton(
                                label: 'Login',
                                isActive: !_isRegisterMode,
                                onTap:
                                    () =>
                                        setState(() => _isRegisterMode = false),
                              ),
                              const SizedBox(width: 8),
                              _TabButton(
                                label: 'Register',
                                isActive: _isRegisterMode,
                                onTap:
                                    () =>
                                        setState(() => _isRegisterMode = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _usernameController,
                            style: GoogleFonts.inter(
                              color: AuraBuddyTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  _isRegisterMode
                                      ? 'Username'
                                      : 'Username or Email',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AuraBuddyTheme.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(
                                color: AuraBuddyTheme.textDark,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AuraBuddyTheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(
                              color: AuraBuddyTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AuraBuddyTheme.primary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AuraBuddyTheme.textLight,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                            ),
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'One account per email only',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AuraBuddyTheme.textLight,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitCredentials,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AuraBuddyTheme.textOnPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        _isRegisterMode
                                            ? 'CREATE ACCOUNT'
                                            : 'LOGIN',
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => setState(() => _showCredentialForm = false),
                      child: Text(
                        '← Back to social login',
                        style: GoogleFonts.inter(
                          color: AuraBuddyTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final bool isLoading;
  final VoidCallback onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.color,
    this.outlined = false,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child:
          outlined
              ? OutlinedButton.icon(
                onPressed: isLoading ? null : onTap,
                icon: Icon(icon, size: 22),
                label: Text(
                  label,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              )
              : ElevatedButton.icon(
                onPressed: isLoading ? null : onTap,
                icon: Icon(icon, size: 22, color: AuraBuddyTheme.textOnPrimary),
                label: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AuraBuddyTheme.textOnPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive
                    ? AuraBuddyTheme.primary
                    : AuraBuddyTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? Colors.white : AuraBuddyTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

