// lib/screens/chat/admin_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';

    final chatProv = context.read<ChatProvider>();

    return StreamBuilder<List<ChatRoom>>(
      stream: chatProv.getChatRooms(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snap.data ?? [];

        if (rooms.isEmpty) {
          return _buildEmpty(context);
        }

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
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.adminBlue.withValues(alpha: 0.15),
                    child: Text(
                      otherName.isNotEmpty
                          ? otherName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.adminBlue),
                    ),
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
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.adminBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined,
                size: 56, color: AppTheme.adminBlue.withOpacity(0.4)),
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
              'ចូលទៅ "អ្នកប្រើប្រាស់" ហើយជ្រើសរើសម្នាក់ដើម្បីចាប់ផ្ដើមសន្ទនា',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
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