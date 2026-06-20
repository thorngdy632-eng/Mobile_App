// lib/screens/provider/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../models/service_request.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../provider_map_screen.dart';
import '../../chat/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    final myServiceType =
        auth.currentUser?.serviceType ?? ServiceTypes.plowing;

    // ── Build notifications from real Firestore data ──

    final notifications = <_NotifItem>[];

    // 1. New pending requests matching my service type (new job alerts)
    final pending = app.pendingServiceRequestsForProvider(
      myServiceType,
      excludeDeclinedBy: myUid,
    );
    for (final r in pending) {
      final info = ServiceTypes.infoOf(r.serviceType);
      notifications.add(_NotifItem(
        icon: info['icon'] as IconData,
        iconColor: const Color(0xFFE53935),
        title: 'ការងារថ្មី — ${info['label']}',
        body:
            '${r.farmerName} ស្នើសេវា ${info['label']} នៅ ${r.currentAddress} (${r.offerPrice.toStringAsFixed(0)} រៀល)',
        time: _fmtTime(r.createdAt),
        type: _NotifType.newJob,
        request: r,
      ));
    }

    // 2. Requests I accepted (active jobs)
    final mine =
        app.acceptedServiceRequestsForProvider(myUid);
    for (final r in mine) {
      final info = ServiceTypes.infoOf(r.serviceType);
      notifications.add(_NotifItem(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF43A047),
        title: 'ការងារដែលបានទទួល — ${info['label']}',
        body:
            'អ្នកបានទទួលការងារ ${info['label']} ពី ${r.farmerName} នៅ ${r.currentAddress}',
        time: _fmtTime(r.createdAt),
        type: _NotifType.accepted,
        request: r,
      ));
    }

    // 3. Completed requests by me
    final completed = app.serviceRequests
        .where((r) => r.providerUid == myUid && r.status == 'completed')
        .toList();
    for (final r in completed) {
      final info = ServiceTypes.infoOf(r.serviceType);
      notifications.add(_NotifItem(
        icon: Icons.emoji_events_rounded,
        iconColor: AppTheme.providerOrange,
        title: 'ការងារបានបញ្ចប់ — ${info['label']}',
        body:
            'ការងារ ${info['label']} ជាមួយ ${r.farmerName} បានបញ្ចប់ដោយជោគជ័យ',
        time: _fmtTime(r.createdAt),
        type: _NotifType.completed,
        request: r,
      ));
    }

    // 4. Cancelled requests by farmer (for jobs I accepted)
    final cancelled = app.serviceRequests
        .where((r) => r.providerUid == myUid && r.status == 'cancelled')
        .toList();
    for (final r in cancelled) {
      final info = ServiceTypes.infoOf(r.serviceType);
      notifications.add(_NotifItem(
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFEF5350),
        title: 'ការងារបានបោះបង់ — ${info['label']}',
        body:
            '${r.farmerName} បានបោះបង់ការងារ ${info['label']} នៅ ${r.currentAddress}',
        time: _fmtTime(r.createdAt),
        type: _NotifType.cancelled,
        request: r,
      ));
    }

    // 5. New chat messages
    // We derive from accepted requests — if the farmer sent a message
    // we show it as a notification
    for (final r in mine) {
      final info = ServiceTypes.infoOf(r.serviceType);
      notifications.add(_NotifItem(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF1E88E5),
        title: 'សារថ្មីពី ${r.farmerName}',
        body: 'អ្នកមានសារថ្មីសម្រាប់ការងារ ${info['label']}',
        time: _fmtTime(r.createdAt),
        type: _NotifType.message,
        request: r,
      ));
    }

    // Sort: newest first
    notifications.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
        elevation: 0,
        title: const Text('ការជូនដំណឹង',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('គ្មានការជូនដំណឹង',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Text('ការជូនដំណឹងនឹងបង្ហាញនៅទីនេះ\nនៅពេលមានការងារថ្មី ឬសារថ្មី',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = notifications[i];
                return _NotifCard(item: n);
              },
            ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ឥឡូវនេះ';
    if (diff.inMinutes < 60) return '${diff.inMinutes} នាទីមុន';
    if (diff.inHours < 24) return '${diff.inHours} ម៉ោងមុន';
    if (diff.inDays < 7) return '${diff.inDays} ថ្ងៃមុន';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

enum _NotifType { newJob, accepted, completed, cancelled, message }

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final _NotifType type;
  final ServiceRequest request;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.request,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  const _NotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the request detail sheet for new jobs,
        // or open chat for messages
        if (item.type == _NotifType.message) {
          _openChat(context);
        } else {
          _openRequest(context);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: item.iconColor.withOpacity(0.12),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.body,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                item.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade400, size: 20),
        ),
      ),
    );
  }

  void _openRequest(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    showRequestDetailSheet(
      context: context,
      request: item.request,
      myUid: myUid,
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final myUid = auth.currentUser?.uid;
    if (myUid == null) return;

    final chatRoomId = await chat.ensureChatRoom(
        myUid: myUid, peerId: item.request.farmerUid);
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        chatRoomId: chatRoomId,
        peerId: item.request.farmerUid,
        peerName: item.request.farmerName,
      ),
    ));
  }
}
