import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class FloatingAuraOverlay extends StatefulWidget {
  const FloatingAuraOverlay({super.key});

  @override
  FloatingAuraOverlayState createState() => FloatingAuraOverlayState();
}

class FloatingAuraOverlayState extends State<FloatingAuraOverlay>
    with TickerProviderStateMixin {
  final List<_FloatingAura> _activeAnimations = [];

  void showAura(int amount, bool isPositive) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final entry = _FloatingAura(
      amount: amount,
      isPositive: isPositive,
      controller: controller,
    );

    setState(() => _activeAnimations.add(entry));

    controller.forward().then((_) {
      controller.dispose();
      if (mounted) {
        setState(() => _activeAnimations.remove(entry));
      }
    });
  }

  @override
  void dispose() {
    for (final a in _activeAnimations) {
      a.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children:
            _activeAnimations.map((a) {
              return AnimatedBuilder(
                animation: a.controller,
                builder: (context, child) {
                  final progress = a.controller.value;
                  final opacity = (1.0 - progress).clamp(0.0, 1.0);
                  final yOffset = -60.0 * progress;

                  return Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.4 + yOffset,
                    child: Center(
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          '${a.isPositive ? '+' : '-'}${a.amount}',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color:
                                a.isPositive
                                    ? AuraBuddyTheme.success
                                    : AuraBuddyTheme.danger,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}

class _FloatingAura {
  final int amount;
  final bool isPositive;
  final AnimationController controller;

  _FloatingAura({
    required this.amount,
    required this.isPositive,
    required this.controller,
  });
}

