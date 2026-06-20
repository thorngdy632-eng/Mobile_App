
// lib/screens/provider/provider_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/service_request.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../models/chat_message.dart';
import '../chat/chat_screen.dart';
import 'tabs/provider_dashboard_tab.dart';
import 'tabs/provider_jobs_screen.dart';
import 'tabs/profile_tab.dart';
import 'provider_map_screen.dart';

/// ProviderHome: 5-tab bottom nav
/// Tab 0: Dashboard (job alerts, stats, categories)
/// Tab 1: Jobs (list of all incoming service requests)
/// Tab 2: Map (customer locations, live tracking)
/// Tab 3: Chat (conversations with farmers)
/// Tab 4: Profile (edit info, logout)
class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'ផ្ទាំងគ្រប់គ្រង'),
    _NavItem(Icons.work_outline, Icons.work, 'ការងារ'),
    _NavItem(Icons.map_outlined, Icons.map, 'ផែនទី'),
    _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'ការសន្ទនា'),
    _NavItem(Icons.person_outline, Icons.person, 'គណនី'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ProviderDashboard(),
          const ProviderJobsScreen(),
          const ProviderMapScreen(),
          _buildChatTab(myUid),
          const ProviderProfileTab(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: context.read<ChatProvider>().totalUnreadStream(myUid),
        builder: (ctx, snap) {
          final unread = snap.data ?? 0;
          final app = context.watch<AppProvider>();
          final myServiceType = user?.serviceType ?? ServiceTypes.plowing;
          final pendingJobs = app
              .pendingServiceRequestsForProvider(myServiceType, excludeDeclinedBy: myUid)
              .length;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4))
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isActive = _currentIndex == i;
                    int badge = 0;
                    if (i == 1) badge = pendingJobs;
                    if (i == 3) badge = unread;

                    return _NavButton(
                      item: item,
                      isActive: isActive,
                      badge: badge,
                      onTap: () => setState(() => _currentIndex = i),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Chat Tab ───────────────────────────────────────────────────────────────
  Widget _buildChatTab(String myUid) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar('ការសន្ទនា', Icons.chat_bubble_rounded),
      body: StreamBuilder<List<ChatRoom>>(
        stream: context.read<ChatProvider>().getChatRooms(myUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) return _buildEmptyChat();
          final chatProv = context.read<ChatProvider>();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              final otherUid = room.otherUid(myUid);
              return FutureBuilder<String>(
                future: chatProv.getUserName(otherUid),
                builder: (_, nameSnap) {
                  final name = nameSnap.data ?? '...';
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                    builder: (_, userSnap) {
                      final data = userSnap.data?.data() as Map<String, dynamic>?;
                      final imgBase64 = data?['profileImageUrl'] as String?;
                      ImageProvider? avatar;
                      if (imgBase64 != null && imgBase64.isNotEmpty) {
                        try { avatar = MemoryImage(base64Decode(imgBase64)); } catch (_) {}
                      }
                      return _ChatRoomCard(
                        name: name,
                        lastMessage: room.lastMessage,
                        time: _fmtDate(room.lastMessageTime),
                        avatar: avatar,
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ChatScreen(
                            chatRoomId: room.id,
                            peerId: otherUid,
                            peerName: name,
                            peerImageBase64: imgBase64,
                          ))),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyChat() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.providerOrange.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.forum_rounded, size: 60, color: AppTheme.providerOrange.withOpacity(0.3)),
      ),
      const SizedBox(height: 20),
      const Text('មិនទាន់មានការសន្ទនា',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2D3142))),
      const SizedBox(height: 8),
      const Text('ការសន្ទនាពីអតិថិជននឹងបង្ហាញនៅទីនេះ',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
    ]),
  );

  AppBar _buildAppBar(String title, IconData icon) => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.black12,
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.providerOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.providerOrange, size: 20),
      ),
    ),
    title: Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
    automaticallyImplyLeading: false,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: const Color(0xFFEEEEEE)),
    ),
  );

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

// ── Navigation button widget ──────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.isActive, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.providerOrange.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? AppTheme.providerOrange : const Color(0xFF9E9E9E),
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    top: -6, right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppTheme.providerOrange : const Color(0xFF9E9E9E),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Chat Room Card ─────────────────────────────────────────────────────────────
class _ChatRoomCard extends StatelessWidget {
  final String name, lastMessage, time;
  final ImageProvider? avatar;
  final VoidCallback onTap;
  const _ChatRoomCard({required this.name, required this.lastMessage,
      required this.time, this.avatar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.providerOrange.withOpacity(0.12),
            backgroundImage: avatar,
            child: avatar == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.providerOrange)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2D3142))),
            const SizedBox(height: 3),
            Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}