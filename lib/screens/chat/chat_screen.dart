import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String peerId;
  final String peerName;
  final String? peerImageBase64;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.peerId,
    required this.peerName,
    this.peerImageBase64,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final me = auth.currentUser;
    if (me == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
    HapticFeedback.lightImpact();

    // 🛠️ ដំណោះស្រាយ៖ បើសិនជា chatRoomId មកពីបញ្ជីឆាតមានតម្លៃ ឱ្យយកទៅប្រើផ្ទាល់ភ្លាម
    String resolvedRoomId = widget.chatRoomId;
    if (resolvedRoomId.isEmpty) {
      // ករណីបើកឆាតដំបូងបង្អស់ចេញពីទំព័រ User Profile ៖ ផ្គុំ UID ដោយយក Farmer UID ដាក់មុនជានិច្ច
      final bool isMeAdmin = widget.peerName.toLowerCase().contains('farmer') || widget.peerName.contains('កសិករ');
      resolvedRoomId = isMeAdmin ? "${widget.peerId}${me.uid}" : "${me.uid}${widget.peerId}";
    }

    final err = await chat.sendMessage(
      chatRoomId: resolvedRoomId,
      senderId: me.uid,
      receiverId: widget.peerId,
      messageText: text,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (err != null) {
        debugPrint("❌ Failed to send message: $err");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
        );
      } else {
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? '';
    
    final bool isPeerAdmin = widget.peerName.toLowerCase().contains('admin');
    final Color primaryColor = isPeerAdmin ? const Color(0xFF2E7D32) : const Color(0xFF0F1E36);

    // 🛠️ ដំណោះស្រាយ៖ កំណត់លំដាប់ទាញ Stream ID បន្ទប់ឆាតឱ្យដូចគ្នាទៅនឹង Logic ផ្ញើសារខាងលើ
    String resolvedRoomId = widget.chatRoomId;
    if (resolvedRoomId.isEmpty) {
      final bool isMeAdmin = widget.peerName.toLowerCase().contains('farmer') || widget.peerName.contains('កសិករ');
      resolvedRoomId = isMeAdmin ? "${widget.peerId}${myUid}" : "${myUid}${widget.peerId}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7), 
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage: widget.peerImageBase64 != null &&
                      widget.peerImageBase64!.isNotEmpty
                  ? MemoryImage(base64Decode(widget.peerImageBase64!))
                  : null,
              child: widget.peerImageBase64 == null ||
                      widget.peerImageBase64!.isEmpty
                  ? Text(
                      widget.peerName.isNotEmpty
                          ? widget.peerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.peerName.isNotEmpty ? widget.peerName : 'អ្នកប្រើប្រាស់',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isPeerAdmin ? 'គណនីគ្រប់គ្រង (Admin)' : 'គណនីអ្នកប្រើប្រាស់',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: context.read<ChatProvider>().getMessages(resolvedRoomId),
                builder: (context, snap) {
                  if (snap.hasError) {
                    debugPrint("❌ Firestore Stream Error: ${snap.error}");
                    return Center(child: Text("មានបញ្ហាក្នុងការទាញទិន្នន័យ: ${snap.error}"));
                  }
                  
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final messages = snap.data ?? [];
                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == myUid;
                      final showDate = i == 0 || !_sameDay(messages[i - 1].timestamp, msg.timestamp);
                      
                      return Column(
                        key: ValueKey(msg.timestamp.toString()),
                        children: [
                          if (showDate) _buildDateDivider(msg.timestamp),
                          _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            activeColor: primaryColor,
                            peerName: widget.peerName,
                            peerImageBase64: widget.peerImageBase64,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat_bubble_outline, size: 44, color: Colors.grey.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              const Text(
                'មិនទាន់មានការសន្ទនា',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'ផ្ញើសារដំបូងទៅកាន់ ${widget.peerName}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String label = _sameDay(date, now) 
        ? 'ថ្ងៃនេះ' 
        : _sameDay(date, now.subtract(const Duration(days: 1))) ? 'ម្សិលមិញ' : '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color activeColor) {
    final double bottomPadding = kIsWeb ? 0.0 : MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'វាយសារនៅទីនេះ...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _sending ? activeColor.withOpacity(0.4) : activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: activeColor.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Color activeColor;
  final String peerName;
  final String? peerImageBase64;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.activeColor,
    required this.peerName,
    this.peerImageBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: activeColor.withOpacity(0.12),
              backgroundImage: peerImageBase64 != null && peerImageBase64!.isNotEmpty
                  ? MemoryImage(base64Decode(peerImageBase64!))
                  : null,
              child: peerImageBase64 == null || peerImageBase64!.isEmpty
                  ? Text(
                      peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: activeColor),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isMe ? activeColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(fontSize: 14, color: isMe ? Colors.white : Colors.black87, height: 1.35),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}