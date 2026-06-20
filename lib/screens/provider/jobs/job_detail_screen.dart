// lib/screens/job_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../models/scheduled_job.dart';
import '../../../theme/app_colors.dart';

// No import of android_nav_bar or android_status_bar — both files are deleted.

class JobDetailScreen extends StatelessWidget {
  final ScheduledJob job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = job.status == JobStatus.confirmed;

    // Standard Scaffold + AppBar. Flutter's Material framework automatically
    // respects the native system status bar (via edgeToEdge in main.dart).
    // No nested Scaffolds, no black wrapper, no mock nav bar needed.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ព័ត៌មានការងារ'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status chip ──────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? AppColors.statusConfirmed
                    : AppColors.statusPending,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                job.status.label,
                style: TextStyle(
                  color: isConfirmed
                      ? AppColors.statusConfirmedText
                      : AppColors.statusPendingText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Detail card ──────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'ប្រភេទសេវា',   value: job.service),
                    const Divider(height: 24),
                    _DetailRow(label: 'កាលបរិច្ឆេទ',  value: job.date),
                    const Divider(height: 24),
                    _DetailRow(label: 'ម៉ោង',          value: job.time),
                    const Divider(height: 24),
                    _DetailRow(label: 'ទីតាំង',        value: job.location),
                    const Divider(height: 24),
                    _DetailRow(label: 'រយៈចម្ងាយ',    value: job.distance),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Confirm button (pending jobs only) ───────────────────────────
            if (!isConfirmed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ការងារត្រូវបានបញ្ជាក់!'),
                        backgroundColor: AppColors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('បញ្ជាក់ការងារ'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Cancel button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('បោះបង់ការងារ?'),
                      content:
                          const Text('តើអ្នកប្រាកដថាចង់បោះបង់ការងារនេះ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ទេ'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            Navigator.pop(context); // back to home
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('ការងារត្រូវបានបោះបង់')),
                            );
                          },
                          child: const Text('បាទ បោះបង់'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('បោះបង់ការងារ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
