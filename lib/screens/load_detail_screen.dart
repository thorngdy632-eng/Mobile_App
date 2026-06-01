// lib/screens/load_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/backhaul_load.dart';
import '../theme/app_theme.dart';

class LoadDetailScreen extends StatefulWidget {
  final BackhaulLoad load;

  const LoadDetailScreen({super.key, required this.load});

  @override
  State<LoadDetailScreen> createState() => _LoadDetailScreenState();
}

class _LoadDetailScreenState extends State<LoadDetailScreen> {
  bool _isAccepting = false;

  Future<void> _acceptLoad() async {
    setState(() => _isAccepting = true);
    // Simulate network call
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isAccepting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ការបម្រើសេវាកម្មទទួល បានជោគជ័យ!'),
        backgroundColor: AppColors.green,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final load = widget.load;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('បម្រើសេវាកម្ម'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero icon block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: load.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(load.icon, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    load.cargo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    load.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Route card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Route row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoutePoint(label: load.from, isOrigin: true),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.arrow_forward,
                                color: AppColors.textMuted,
                              ),
                              Container(
                                height: 1,
                                color: AppColors.textMuted,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                        ),
                        _RoutePoint(label: load.to, isOrigin: false),
                      ],
                    ),
                    const Divider(height: 24),
                    _DetailRow(label: 'ទម្ងន់', value: load.weight),
                    const Divider(height: 24),
                    _DetailRow(label: 'តម្លៃ', value: load.price),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAccepting ? null : _acceptLoad,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ទទួលយក', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ត្រឡប់'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final bool isOrigin;
  const _RoutePoint({required this.label, required this.isOrigin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          isOrigin ? Icons.trip_origin : Icons.location_on,
          color: isOrigin ? AppColors.textSecondary : AppColors.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: isOrigin ? FontWeight.normal : FontWeight.w600,
            color: isOrigin ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
