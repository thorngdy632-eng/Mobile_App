import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatProv = context.read<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        centerTitle: false,
        title: const Text(
          'ការសន្ទនា',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: StreamBuilder<List<ChatRoom>>(
          stream: chatProv.getChatRooms(myUid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = snap.data ?? [];

            if (rooms.isEmpty) {
              return _buildEmpty();
            }

            return ListView.separated(
              padding: EdgeInsets.only(
                top: 4,
                bottom: kIsWeb ? 16 : MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 76,
                endIndent: 16,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (ctx, i) {
                final room = rooms[i];
                final otherUid = room.otherUid(myUid);

                return FutureBuilder<Map<String, String>>(
                  future: chatProv.getUserProfile(otherUid),
                  builder: (ctx2, profileSnap) {
                    final profileData = profileSnap.data ?? {'name': '...', 'avatar': ''};
                    final otherName = profileData['name'] ?? '...';
                    final avatarBase64 = profileData['avatar'] ?? '';

                    return _ChatTile(
                      room: room,
                      otherName: otherName,
                      avatarBase64: avatarBase64,
                      onDelete: () => _showDeleteDialog(context, chatProv, room.id, otherName), // 🔥 បន្ថែមមុខងារលុប
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: room.id,
                            peerId: otherUid,
                            peerName: otherName,
                            peerImageBase64: avatarBase64.isNotEmpty ? avatarBase64 : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 🛠️ ផ្ទាំងសួរបញ្ជាក់មុនពេលលុបការសន្ទនា
  void _showDeleteDialog(BuildContext context, ChatProvider chatProv, String roomId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('លុបការសន្ទនា?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text('តើអ្នកពិតជាចង់លុបការសន្ទនាជាមួយ « $name » មែនទេ? សារទាំងអស់នឹងត្រូវលុបបាត់រហូត។'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // បិទ Dialog
              
              // ហៅមុខងារលុបពី Provider
              bool success = await chatProv.deleteChatRoom(roomId);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'បានលុបការសន្ទនារួចរាល់ ✓' : 'ការលុបមានបញ្ហា ៖('),
                    backgroundColor: success ? Colors.red : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('លុបចេញ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 52,
              color: Color(0xFF90CAF9),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'មិនទាន់មានការសន្ទនា',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'ចូលទៅ "អ្នកប្រើប្រាស់" ហើយជ្រើសរើសម្នាក់ដើម្បីចាប់ផ្ដើមសន្ទនា',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat list tile ────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatRoom room;
  final String otherName;
  final String avatarBase64;
  final VoidCallback onTap;
  final VoidCallback onDelete; // 🔥 ទួលយក Callback សម្រាប់លុប

  const _ChatTile({
    required this.room,
    required this.otherName,
    required this.avatarBase64,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (avatarBase64.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {
        imageProvider = null;
      }
    }

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.lastMessage.isEmpty ? 'មិនទាន់មានសារ' : room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: room.lastMessage.isEmpty ? Colors.grey : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(room.lastMessageTime),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // 🔥 ប៊ូតុងចុចដើម្បីជម្រើស "លុប" (PopupMenuButton)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(maxWidth: 100),
                    icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete(); // ហៅមុខងារលុប
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        height: 38,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('លុប', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}