import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream all chat rooms where [uid] is a member, ordered by most recent.
  Stream<List<ChatRoom>> getChatRooms(String uid) {
    return _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatRoom.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream messages inside a chat room, ordered oldest → newest.
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .toList());
  }

  /// Send a message. Creates the chat room if it doesn't exist yet.
  Future<String?> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String messageText,
  }) async {
    if (messageText.trim().isEmpty) return null;

    final chatRef = _db.collection('chats').doc(chatRoomId);
    final msgRef = chatRef.collection('messages').doc();

    try {
      await _db.runTransaction((tx) async {
        final chatSnap = await tx.get(chatRef);

        final msg = ChatMessage(
          id: msgRef.id,
          senderId: senderId,
          receiverId: receiverId,
          message: messageText.trim(),
          timestamp: DateTime.now(),
        );

        tx.set(msgRef, msg.toMap());

        if (!chatSnap.exists) {
          tx.set(chatRef, {
            'members': [senderId, receiverId],
            'lastMessage': messageText.trim(),
            'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          });
        } else {
          tx.update(chatRef, {
            'lastMessage': messageText.trim(),
            'lastMessageTime': Timestamp.fromDate(DateTime.now()),
          });
        }
      });
      return null;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return 'មានបញ្ហាក្នុងការផ្ញើ: $e';
    }
  }

  /// Find existing chat room between [myUid] and [peerId], or create a new one.
  /// Returns the chat room ID.
  Future<String> createOrGetChatRoom({
    required String myUid,
    required String peerId,
  }) async {
    final existingId = ChatRoom.buildId(myUid, peerId);
    final existing = await _db.collection('chats').doc(existingId).get();

    if (existing.exists) return existingId;

    await _db.collection('chats').doc(existingId).set({
      'members': [myUid, peerId],
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });

    return existingId;
  }

  /// Total unread count for a user across all rooms.
  Stream<int> totalUnreadStream(String uid) {
    return _db
        .collection('chats')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Fetch a user's display name from the users collection.
  Future<String> getUserName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['fullName'] ?? 'អ្នកប្រើប្រាស់';
    } catch (e) {
      return 'អ្នកប្រើប្រាស់';
    }
  }

  /// Fetch a user's role from the users collection.
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
