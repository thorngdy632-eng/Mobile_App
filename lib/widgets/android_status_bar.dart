// lib/widgets/android_status_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Simulates an Android status bar (time + icons)
class AndroidStatusBar extends StatelessWidget {
  const AndroidStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.androidBar,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '08:20',
            style: TextStyle(
              color: AppColors.androidBarText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: const [
              Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Icon(Icons.wifi, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Icon(Icons.battery_full, color: Colors.white, size: 16),
              SizedBox(width: 2),
              Text(
                '95%',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
