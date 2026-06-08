// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Admin's list of all chat threads ─────────────────────────────────────
  List<ChatThread> _adminThreads = [];
  List<ChatThread> get adminThreads => _adminThreads;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Listen to all chat threads that involve a given UID ──────────────────
  // For admin: listens to all threads where admin is a participant.
  // For farmer/provider: same — only threads involving them.

  Stream<List<ChatThread>> threadsStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatThread.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Listen to messages inside a thread ───────────────────────────────────

  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Send a message (creates thread if needed) ─────────────────────────────

  Future<String?> sendMessage({
    required String myUid,
    required String myName,
    required String myRole,
    required String otherUid,
    required String otherName,
    required String otherRole,
    required String text,
  }) async {
    if (text.trim().isEmpty) return null;

    final chatId = ChatThread.buildId(myUid, otherUid);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    try {
      await _db.runTransaction((tx) async {
        final chatSnap = await tx.get(chatRef);

        final message = ChatMessage(
          id: msgRef.id,
          senderId: myUid,
          senderName: myName,
          text: text.trim(),
          createdAt: DateTime.now(),
          isRead: false,
        );

        // Write the message
        tx.set(msgRef, message.toMap());

        if (!chatSnap.exists) {
          // Create thread for the first time
          final thread = ChatThread(
            id: chatId,
            participants: [myUid, otherUid],
            participantNames: {myUid: myName, otherUid: otherName},
            participantRoles: {myUid: myRole, otherUid: otherRole},
            lastMessage: text.trim(),
            lastMessageAt: DateTime.now(),
            unreadCount: {myUid: 0, otherUid: 1},
            createdAt: DateTime.now(),
          );
          tx.set(chatRef, thread.toMap());
        } else {
          // Update existing thread
          final current =
              ChatThread.fromMap(chatSnap.data()!, chatSnap.id);
          final newUnread = Map<String, int>.from(current.unreadCount);
          newUnread[otherUid] = (newUnread[otherUid] ?? 0) + 1;
          newUnread[myUid] = 0; // sender's own unread = 0

          tx.update(chatRef, {
            'lastMessage': text.trim(),
            'lastMessageAt': Timestamp.fromDate(DateTime.now()),
            'unreadCount': newUnread,
          });
        }
      });
      return null;
    } catch (e) {
      return 'មានបញ្ហាក្នុងការផ្ញើ: $e';
    }
  }

  // ── Mark all messages from the other person as read ───────────────────────

  Future<void> markAsRead({
    required String chatId,
    required String myUid,
  }) async {
    try {
      // Reset my unread count to 0
      await _db.collection('chats').doc(chatId).update({
        'unreadCount.$myUid': 0,
      });

      // Mark unread messages as read
      final unreadMsgs = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: myUid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in unreadMsgs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  // ── Total unread count for a user (for badge display) ────────────────────

  Stream<int> totalUnreadStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final thread = ChatThread.fromMap(doc.data(), doc.id);
        total += thread.unreadFor(uid);
      }
      return total;
    });
  }

  // ── Admin: get all users for starting a chat ─────────────────────────────

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final snap = await _db.collection('users').get();
      return snap.docs
          .map((d) => UserModel.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('fetchAllUsers error: $e');
      return [];
    }
  }
}