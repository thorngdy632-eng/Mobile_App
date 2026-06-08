// lib/models/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message inside a chat thread.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

/// A chat thread between two participants.
class ChatThread {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final DateTime createdAt;

  const ChatThread({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantRoles,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatThread.fromMap(Map<String, dynamic> map, String id) {
    return ChatThread(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? {}),
      participantRoles:
          Map<String, String>.from(map['participantRoles'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt:
          (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(
        (map['unreadCount'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// The other participant's UID.
  String otherUid(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  String otherName(String myUid) =>
      participantNames[otherUid(myUid)] ?? 'អ្នកប្រើប្រាស់';

  String otherRole(String myUid) =>
      participantRoles[otherUid(myUid)] ?? '';

  int unreadFor(String uid) => unreadCount[uid] ?? 0;

  /// Canonical chat ID: sort the two UIDs alphabetically.
  static String buildId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}