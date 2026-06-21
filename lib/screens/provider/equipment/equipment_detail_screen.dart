// lib/screens/equipment_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/equipment_item.dart';
import '../../../theme/app_colors.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentItem item;
  const EquipmentDetailScreen({super.key, required this.item});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  int _days = 1;
  bool _isBooking = false;

  double get _total {
    final priceStr = widget.item.price.replaceAll(RegExp(r'[^\d.]'), '');
    return (double.tryParse(priceStr) ?? 0) * _days;
  }

  Future<void> _book() async {
    setState(() => _isBooking = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isBooking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('បានជួល ${widget.item.name} រយៈ $_days ថ្ងៃ!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero app bar with image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(imageAsset: item.imageAsset),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge + name
                  if (item.badge != EquipmentBadge.none)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.badge == EquipmentBadge.hot
                            ? AppColors.badgeHot : AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.badge == EquipmentBadge.hot ? 'HOT' : 'ថ្មី',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(item.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  // Location + rating row
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                      Text(item.location, style: const TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
                      const SizedBox(width: 2),
                      Text(item.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Days picker
                  Row(
                    children: [
                      const Text('ចំនួនថ្ងៃ:', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      _CounterButton(
                        icon: Icons.remove,
                        onPressed: _days > 1 ? () => setState(() => _days--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _CounterButton(
                        icon: Icons.add,
                        onPressed: () => setState(() => _days++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price summary card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('តម្លៃសរុប:', style: TextStyle(fontSize: 15)),
                        Text('${_total.toStringAsFixed(0)} រៀល',
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _book,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isBooking
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('ជួលឥឡូវ'),
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
}

class _HeroImage extends StatelessWidget {
  final String imageAsset;
  const _HeroImage({required this.imageAsset});

  static const Map<String, _Cfg> _cfgs = {
    'tractor':   _Cfg(Icons.agriculture,  Color(0xFFE8F5E9), Color(0xFF43A047)),
    'harvester': _Cfg(Icons.grass,         Color(0xFFFFF8E1), Color(0xFFF9A825)),
    'pump':      _Cfg(Icons.water_drop,    Color(0xFFE3F2FD), Color(0xFF1E88E5)),
  };

  @override
  Widget build(BuildContext context) {
    final c = _cfgs[imageAsset] ?? const _Cfg(Icons.build, Color(0xFFF5F5F5), Color(0xFF9E9E9E));
    return Container(
      color: c.bg,
      child: Center(child: Icon(c.icon, size: 100, color: c.fg)),
    );
  }
}

class _Cfg {
  final IconData icon; final Color bg; final Color fg;
  const _Cfg(this.icon, this.bg, this.fg);
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onPressed != null ? AppColors.primaryGreen : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
