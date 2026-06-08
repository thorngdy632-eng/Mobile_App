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

    return StreamBuilder<List<ChatThread>>(
      stream: context.read<ChatProvider>().threadsStream(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final threads = snap.data ?? [];

        if (threads.isEmpty) {
          return _buildEmpty(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(
              height: 1, indent: 72, color: Color(0xFFF0F0F0)),
          itemBuilder: (ctx, i) {
            final thread = threads[i];
            final unread = thread.unreadFor(myUid);
            final otherUid = thread.otherUid(myUid);
            final otherName = thread.otherName(myUid);
            final otherRole = thread.otherRole(myUid);

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        _roleColor(otherRole).withOpacity(0.15),
                    child: Text(
                      otherName.isNotEmpty
                          ? otherName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _roleColor(otherRole)),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                otherName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      unread > 0 ? FontWeight.w700 : FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    _roleLabel(otherRole),
                    style: TextStyle(
                      fontSize: 11,
                      color: _roleColor(otherRole),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: unread > 0
                          ? AppTheme.textPrimary
                          : AppColors.textMuted,
                      fontWeight: unread > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(thread.lastMessageAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: unread > 0
                          ? AppTheme.adminBlue
                          : AppColors.textMuted,
                      fontWeight: unread > 0
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUid: otherUid,
                    otherName: otherName,
                    otherRole: otherRole,
                  ),
                ),
              ),
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

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.adminBlue;
      case 'farmer':
        return AppTheme.farmerGreen;
      case 'serviceProvider':
        return AppTheme.providerOrange;
      default:
        return AppColors.textMuted;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'អ្នកគ្រប់គ្រង';
      case 'farmer':
        return 'កសិករ';
      case 'serviceProvider':
        return 'អ្នកផ្តល់សេវា';
      default:
        return role;
    }
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