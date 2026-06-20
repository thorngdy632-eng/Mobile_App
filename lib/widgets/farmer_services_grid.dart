// lib/widgets/farmer_services_grid.dart
import 'package:flutter/material.dart';

import '../models/service_request.dart';
import '../theme/app_colors.dart';
import '../screens/farmer/service_request_map_screen.dart';

class _ImgCfg {
  final String imagePath;
  final Color bg;
  final Color fg;
  const _ImgCfg(this.imagePath, this.bg, this.fg);
}

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png', Color(0xFFFFF3E0), Color(0xFFFF9800)),
  'harvesting':  _ImgCfg('assets/images/2.png', Color(0xFFFFF8E1), Color(0xFFF9A825)),
  'drone_spray': _ImgCfg('assets/images/5.png', Color(0xFFFFEBEE), Color(0xFFEF5350)),
  'transport':   _ImgCfg('assets/images/3.png', Color(0xFFE8F5E9), Color(0xFF43A047)),
  'irrigation':  _ImgCfg('assets/images/4.png', Color(0xFFE3F2FD), Color(0xFF1E88E5)),
};

/// Compact horizontal-scroll service strip for the Farmer home screen.
///
/// Each tile shows a small image + label. Tap opens [ServiceRequestMapScreen].
class FarmerServicesGrid extends StatelessWidget {
  const FarmerServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'សេវាកម្មសម្រាប់កសិករ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'មើលទាំងអស់ ›',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal scroll strip ─────────────────────────────────────
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: ServiceTypes.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final service = ServiceTypes.all[index];
              return _ServiceTile(service: service);
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> service;

  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final String id = service['id'] as String;
    final Color color = service['color'] as Color;
    final cfg = _serviceImgCfgs[id];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceRequestMapScreen(serviceType: id),
          ),
        );
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image container ───────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cfg?.bg ?? color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: cfg != null
                    ? Image.asset(
                        cfg.imagePath,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(service['icon'] as IconData, color: cfg.fg, size: 22),
                      )
                    : Icon(service['icon'] as IconData, color: color, size: 22),
              ),
            ),

            const SizedBox(height: 8),

            // ── Label ────────────────────────────────────────────────
            Text(
              service['label'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
