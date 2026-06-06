// lib/widgets/backhaul_card.dart
import 'package:flutter/material.dart';
import '../models/backhaul_load.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

/// Card displaying a single backhaul load opportunity
class BackhaulCard extends StatelessWidget {
  final BackhaulLoad load;
  final VoidCallback? onViewPressed;

  const BackhaulCard({super.key, required this.load, this.onViewPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Cargo icon
          Container(
            color: load.color,
            padding: const EdgeInsets.all(16),
            child: Icon(load.icon, color: Colors.white, size: 28),
          ),
          // Cargo details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    load.cargo,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        load.from,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        load.to,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ទម្ងន់: ${load.weight}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Price + button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  load.price,
                  style: const TextStyle(
                    color: AppColors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: onViewPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('ពិនិត្យមើល'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
