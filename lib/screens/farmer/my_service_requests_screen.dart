// lib/screens/farmer/my_service_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';

const _kGreen = Color(0xFF2E7D32);
const _kSurface = Color(0xFFF7F9F7);
const _kCard = Colors.white;

class _ImgCfg {
  final String imagePath;
  const _ImgCfg(this.imagePath);
}

const Map<String, _ImgCfg> _serviceImgCfgs = {
  'plowing':     _ImgCfg('assets/images/1.png'),
  'harvesting':  _ImgCfg('assets/images/2.png'),
  'drone_spray': _ImgCfg('assets/images/5.png'),
  'transport':   _ImgCfg('assets/images/3.png'),
  'irrigation':  _ImgCfg('assets/images/4.png'),
};

class MyServiceRequestsScreen extends StatelessWidget {
  const MyServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUser?.uid ?? '';
    final requests = context
        .watch<AppProvider>()
        .serviceRequestsForFarmer(uid)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('សំណើសេវារបស់ខ្ញុំ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: requests.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _RequestCard(r: requests[index]),
            ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.list_alt_rounded,
                size: 42, color: _kGreen.withOpacity(0.35)),
          ),
          const SizedBox(height: 16),
          const Text('មិនទាន់មានសំណើ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF424242))),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ចុចលើប្រភេទសេវានៅទំព័រដើម\nដើម្បីដាក់ការស្នើសុំថ្មី',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ServiceRequest r;
  const _RequestCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final info = ServiceTypes.infoOf(r.serviceType);
    final Color color = info['color'] as Color;
    final app = context.read<AppProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // ── Top strip ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      _serviceImgCfgs[r.serviceType]?.imagePath ??
                          'assets/images/app_icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          info['icon'] as IconData,
                          color: color,
                          size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(info['label'] as String,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                _StatusChip(label: r.statusLabel, color: r.statusColor),
              ],
            ),
          ),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                _DetailRow(
                    icon: Icons.location_on_outlined,
                    text: r.currentAddress),
                _DetailRow(
                    icon: Icons.crop_square_rounded,
                    text: r.landLabel),
                _DetailRow(
                    icon: Icons.attach_money_rounded,
                    text: 'ផ្តល់តម្លៃ: ${r.offerPrice.toStringAsFixed(0)} រៀល'),
                if (r.providerName != null)
                  _DetailRow(
                      icon: Icons.engineering_rounded,
                      text: 'អ្នកផ្តល់សេវា: ${r.providerName}',
                      highlight: true),
              ],
            ),
          ),

          // ── Action buttons ──
          if (r.status == 'accepted' && r.providerUid != null) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('ទាក់ទងអ្នកផ្តល់សេវា'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _openChat(context,
                      peerId: r.providerUid!,
                      peerName: r.providerName ?? ''),
                ),
              ),
            ),
          ],

          if (r.status == 'pending') ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text('រង់ចាំការឆ្លើយតប',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined,
                        color: Color(0xFFEF5350), size: 16),
                    label: const Text('បោះបង់',
                        style: TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => _confirmCancel(context, app),
                  ),
                ],
              ),
            ),
          ],

          if (r.status == 'declined' || r.status == 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFFEF5350)),
                    const SizedBox(width: 6),
                    Text(
                      r.status == 'declined'
                          ? 'សំណើនេះត្រូវបានបដិសេធ'
                          : 'សំណើនេះត្រូវបានបោះបង់',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFEF5350)),
                    ),
                  ],
                ),
              ),
            ),

          if (r.status == 'completed')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF43A047)),
                    SizedBox(width: 6),
                    Text('សេវាបានបញ្ចប់ដោយជោគជ័យ',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF43A047))),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, AppProvider app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('បោះបង់សំណើ?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('តើអ្នកប្រាកដក្នុងការបោះបង់សំណើនេះ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ទេ')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('បោះបង់')),
        ],
      ),
    );
    if (confirmed == true) {
      await app.cancelServiceRequest(r.id);
    }
  }

  Future<void> _openChat(BuildContext context,
      {required String peerId, String peerName = ''}) async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final myUid = auth.currentUser?.uid;
    if (myUid == null) return;

    final chatRoomId =
        await chat.ensureChatRoom(myUid: myUid, peerId: peerId);
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen(
          chatRoomId: chatRoomId, peerId: peerId, peerName: peerName),
    ));
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;

  const _DetailRow({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 15,
              color: highlight ? _kGreen : const Color(0xFF9E9E9E)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13,
                  color: highlight
                      ? _kGreen
                      : const Color(0xFF424242),
                  fontWeight: highlight
                      ? FontWeight.w600
                      : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}