import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Decorative brand mascot shared by the top-level Nexora menus.
/// It never intercepts touches and remains intentionally subtle.
class NexoraMascotOverlay extends StatelessWidget {
  const NexoraMascotOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.16,
        child: SvgPicture.asset(
          'assets/mascot/nexora_mascot_master.svg',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
