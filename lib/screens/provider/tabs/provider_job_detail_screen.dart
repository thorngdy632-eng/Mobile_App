import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../chat/chat_screen.dart';

class ProviderJobDetailScreen extends StatelessWidget {
  final String jobId;
  final bool isTractor;

  const ProviderJobDetailScreen({
    super.key,
    required this.jobId,
    required this.isTractor,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.read<AuthProvider>();

    final String title;
    final String farmerUid;
    final String farmerName;
    final List<_DetailRow> rows;
    final String status;
    final String statusLabel;
    final Color statusColor;

    if (isTractor) {
      TractorJob? job;
      for (final j in app.tractorJobs) {
        if (j.id == jobId) {
          job = j;
          break;
        }
      }
      if (job == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('ព័ត៌មានការងារ')),
          body: const Center(child: Text('រកមិនឃើញការងារ')),
        );
      }
      title = 'ព័ត៌មានការងារត្រាក់ទ័រ';
      farmerUid = job.farmerUid;
      farmerName = job.farmerName;
      status = job.status;
      statusLabel = job.statusLabel;
      statusColor = job.statusColor;
      rows = [
        _DetailRow(Icons.build_rounded, 'ប្រភេទសេវា', job.serviceType),
        _DetailRow(Icons.location_on_rounded, 'ទីតាំង', job.location),
        _DetailRow(Icons.calendar_today_rounded, 'កាលបរិច្ឆេទ', job.scheduledDate),
        _DetailRow(Icons.access_time_rounded, 'ម៉ោង', job.scheduledTime),
        _DetailRow(Icons.crop_square_rounded, 'ផ្ទៃដី', '${job.areaHectares.toStringAsFixed(1)} ហេកតា'),
        if (job.notes != null && job.notes!.isNotEmpty)
          _DetailRow(Icons.note_alt_rounded, 'ចំណាំ', job.notes!),
      ];
    } else {
      DroneJob? job;
      for (final j in app.droneJobs) {
        if (j.id == jobId) {
          job = j;
          break;
        }
      }
      if (job == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('ព័ត៌មានការងារ')),
          body: const Center(child: Text('រកមិនឃើញការងារ')),
        );
      }
      title = 'ព័ត៌មានការងារដ្រូន';
      farmerUid = job.farmerUid;
      farmerName = job.farmerName;
      status = job.status;
      statusLabel = job.statusLabel;
      statusColor = job.statusColor;
      rows = [
        _DetailRow(Icons.grass_rounded, 'ប្រភេទដំណាំ', job.cropType),
        _DetailRow(Icons.science_rounded, 'ថ្នាំសម្លាប់សត្វ', job.pesticide),
        _DetailRow(Icons.location_on_rounded, 'ទីតាំង', job.location),
        _DetailRow(Icons.calendar_today_rounded, 'កាលបរិច្ឆេទ', job.scheduledDate),
        _DetailRow(Icons.access_time_rounded, 'ម៉ោង', job.scheduledTime),
        _DetailRow(Icons.crop_square_rounded, 'ផ្ទៃដី', '${job.areaHectares.toStringAsFixed(1)} ហេកតា'),
        if (job.notes != null && job.notes!.isNotEmpty)
          _DetailRow(Icons.note_alt_rounded, 'ចំណាំ', job.notes!),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    child: Text(
                      farmerName.isNotEmpty ? farmerName[0] : 'ក',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail rows
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: rows
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(r.icon, size: 20, color: const Color(0xFF2E7D32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3142),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons (only for pending/confirmed jobs)
            if (status == 'pending' || status == 'confirmed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final chatProv = context.read<ChatProvider>();
                        final currentUid = auth.currentUser?.uid ?? '';
                        final roomId = await chatProv.ensureChatRoom(myUid: currentUid, peerId: farmerUid);
                        if (context.mounted) {
                          nav.push(MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatRoomId: roomId,
                              peerId: farmerUid,
                              peerName: farmerName,
                            ),
                          ));
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('ផ្ញើសារ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (status == 'pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isTractor) {
                            await app.updateTractorJobStatus(jobId, 'confirmed');
                          } else {
                            await app.updateDroneJobStatus(jobId, 'confirmed');
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('បានបញ្ជាក់ការងារ')),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('បញ្ជាក់'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (status == 'confirmed')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isTractor) {
                            await app.updateTractorJobStatus(jobId, 'completed');
                          } else {
                            await app.updateDroneJobStatus(jobId, 'completed');
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('បានបញ្ចប់ការងារ')),
                            );
                          }
                        },
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('បញ្ចប់'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            if (status == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (isTractor) {
                        await app.updateTractorJobStatus(jobId, 'cancelled');
                      } else {
                        await app.updateDroneJobStatus(jobId, 'cancelled');
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('បានបោះបង់ការងារ')),
                        );
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('បោះបង់'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);
}
