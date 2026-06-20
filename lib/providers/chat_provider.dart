import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart'; 

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream user's chat rooms, sorted safely on client side
  Stream<List<ChatRoom>> getChatRooms(String uid) {
    return _db.collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
          final rooms = snap.docs
              .map((d) => ChatRoom.fromMap(d.data(), d.id))
              .toList()
              .cast<ChatRoom>();

          rooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return rooms;
        });
  }

  /// លុបបន្ទប់សន្ទនា (Chat Room) ចេញពី Firestore ទាំងស្រុង
  Future<bool> deleteChatRoom(String chatRoomId) async {
    try {
      final messagesSnapshot = await _db.collection('chats').doc(chatRoomId).collection('messages').get();
      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      final roomRef = _db.collection('chats').doc(chatRoomId);
      batch.delete(roomRef);
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting chat room: $e');
      return false;
    }
  }

  /// Stream messages inside a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _db.collection('chats').doc(chatRoomId).collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList().cast<ChatMessage>());
  }

  /// Ensure a chat room exists
  Future<String> ensureChatRoom({required String myUid, required String peerId}) async {
    final existing = await _db.collection('chats').where('participants', arrayContains: myUid).get();
    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(peerId)) return doc.id;
    }
    final chatRoomId = ChatRoom.buildId(myUid, peerId);
    final ref = _db.collection('chats').doc(chatRoomId);
    await ref.set({
      'participants': [myUid, peerId],
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });
    return chatRoomId;
  }

  /// Send a message
  Future<String?> sendMessage({required String chatRoomId, required String senderId, required String receiverId, required String messageText}) async {
    if (messageText.trim().isEmpty) return null;
    try {
      final batch = _db.batch();
      final msgRef = _db.collection('chats').doc(chatRoomId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': senderId, 'receiverId': receiverId, 'message': messageText.trim(), 'timestamp': Timestamp.now()
      });
      batch.set(_db.collection('chats').doc(chatRoomId), {
        'participants': [senderId, receiverId], 'lastMessage': messageText.trim(), 'lastMessageTime': Timestamp.now()
      }, SetOptions(merge: true));
      await batch.commit();
      return null;
    } catch (e) {
      return 'មានបញ្ហាក្នុងការផ្ញើ: $e';
    }
  }

  /// ទាញយកឈ្មោះ និងទិន្នន័យរូបភាព (សម្អាតការជាន់គ្នា)
  Future<Map<String, String>> getUserProfile(String uid) async {
    try {
      debugPrint("កំពុងទាញយក Profile សម្រាប់ UID: $uid");
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return {'name': 'អ្នកប្រើប្រាស់', 'avatar': ''};

      final data = doc.data()!;
      return {
        'name': data['fullName'] ?? data['name'] ?? 'អ្នកប្រើប្រាស់',
        'avatar': data['profileImageUrl'] ?? ''
      };
    } catch (e) {
      debugPrint("Error ពេលទាញយក Profile: $e");
      return {'name': 'អ្នកប្រើប្រាស់', 'avatar': ''};
    }
  }

  Future<String> getUserName(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['fullName'] ?? doc.data()?['name'] ?? 'អ្នកប្រើប្រាស់';
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? '';
  }

  Stream<int> totalUnreadStream(String uid) {
    return _db.collection('chats').where('participants', arrayContains: uid).snapshots().map((snap) => snap.docs.length);
  }
}