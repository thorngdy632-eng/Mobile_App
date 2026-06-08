// lib/screens/provider/provider_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

import '../chat/chat_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'home_screen.dart';

/// Provider home now wraps HomeScreen and adds a bottom nav tab
/// for Chat and Profile, keeping all existing HomeScreen functionality.
class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: the existing HomeScreen (all original provider UI)
          const HomeScreen(),
          // Tab 1: Chat list
          _buildChatTab(myUid),
          // Tab 2: Profile
          _buildProfileTab(user, auth),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: context.read<ChatProvider>().totalUnreadStream(myUid),
        builder: (context, snap) {
          final unread = snap.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: AppTheme.providerOrange,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'ទំព័រដើម',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.chat_bubble),
                label: 'ការសន្ទនា',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'គណនី',
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Chat tab ───────────────────────────────────────────────────────────────

  Widget _buildChatTab(String myUid) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('ការសន្ទនា'),
        backgroundColor: AppTheme.providerOrange,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: context.read<ChatProvider>().getChatRooms(myUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snap.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.providerOrange.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.forum_outlined,
                        size: 56,
                        color:
                            AppTheme.providerOrange.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'មិនទាន់មានការសន្ទនា',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'រង់ចាំការផ្ញើសារពីអ្នកគ្រប់គ្រង',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            );
          }

          final chatProv = context.read<ChatProvider>();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, indent: 72, color: Color(0xFFF0F0F0)),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              final otherUid = room.otherUid(myUid);
              return FutureBuilder<String>(
                future: chatProv.getUserName(otherUid),
                builder: (ctx2, nameSnap) {
                  final otherName = nameSnap.data ?? '...';
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUid)
                        .get(),
                    builder: (ctx3, userSnap) {
                      final peerData =
                          userSnap.data?.data() as Map<String, dynamic>?;
                      final peerImage =
                          peerData?['profileImageUrl'] as String?;
                      ImageProvider? peerAvatar;
                      if (peerImage != null && peerImage.isNotEmpty) {
                        try {
                          peerAvatar = MemoryImage(base64Decode(peerImage));
                        } catch (_) {}
                      }
                      return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          AppTheme.adminBlue.withOpacity(0.15),
                      backgroundImage: peerAvatar,
                      child: peerAvatar == null
                          ? Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.adminBlue),
                      )
                          : null,
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    trailing: Text(
                      _formatDate(room.lastMessageTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatRoomId: room.id,
                          peerId: otherUid,
                          peerName: otherName,
                          peerImageBase64: peerImage,
                        ),
                      ),
                    ),
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

  // ── Profile tab ────────────────────────────────────────────────────────────

  Widget _buildProfileTab(dynamic user, AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('គណនី'),
        backgroundColor: AppTheme.providerOrange,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.providerOrange.withOpacity(0.15),
          backgroundImage: user?.profileImageUrl != null &&
                  user!.profileImageUrl!.isNotEmpty
              ? MemoryImage(base64Decode(user.profileImageUrl!))
              : null,
          child: user?.profileImageUrl == null ||
                  user!.profileImageUrl!.isEmpty
              ? Text(
                  user?.fullName?.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : '🚜',
                  style: TextStyle(
                      fontSize:
                          user?.fullName?.isNotEmpty == true ? 36 : 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.providerOrange),
                )
              : null,
        ),
            const SizedBox(height: 12),
            Text(
              user?.fullName ?? '',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.providerOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.providerOrange.withOpacity(0.3)),
              ),
              child: Text(
                user?.roleDisplayName ?? 'អ្នកផ្តល់សេវា',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.providerOrange),
              ),
            ),
            const SizedBox(height: 28),

            // Info card
            _profileCard([
              _profileRow(Icons.email_outlined, 'អ៊ីមែល',
                  user?.email ?? ''),
              _profileRow(Icons.phone_outlined, 'ទូរស័ព្ទ',
                  user?.phoneNumber ?? ''),
              if (user?.serviceType != null)
                _profileRow(Icons.work_outline, 'ប្រភេទសេវា',
                    user!.serviceType!),
              if (user?.address != null && user!.address!.isNotEmpty)
                _profileRow(Icons.location_on_outlined, 'អាសយដ្ឋាន',
                    user.address!),
            ]),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white),
                label: const Text('កែប្រែព័ត៌មាន',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.providerOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                ).then((_) {
                  context.read<AuthProvider>().refreshProfile();
                }),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout,
                    color: AppTheme.errorRed),
                label: const Text('ចេញពីគណនី',
                    style: TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}