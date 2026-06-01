// lib/widgets/android_nav_bar.dart
import 'package:flutter/material.dart';

/// Simulates an Android 3-button navigation bar
class AndroidNavBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final VoidCallback? onRecents;

  const AndroidNavBar({
    super.key,
    this.onBack,
    this.onHome,
    this.onRecents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Back — chevron left
          _NavButton(
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
          ),
          // Home — circle
          _NavButton(
            onTap: onHome,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Recents — rounded square
          _NavButton(
            onTap: onRecents,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _NavButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}
