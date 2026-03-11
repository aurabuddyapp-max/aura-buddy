import 'package:flutter/material.dart';

class AuraCoinIcon extends StatelessWidget {
  final double size;
  
  const AuraCoinIcon({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/aura-coins-logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
