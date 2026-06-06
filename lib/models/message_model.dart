// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE MODEL  —  Used by chat system (admin ↔ farmer / admin ↔ provider)
//
// Firestore structure:
//   chats/{chatId}/
//     participants: [uid1, uid2]
//     participantNames: {uid: name}
//     participantRoles: {uid: role}
//     lastMessage: String
//     lastMessageAt: Timestamp
//     lastSenderUid: String
//     unreadCount_{uid}: int
//
//   chats/{chatId}/messages/{messageId}/
//     senderUid: String
//     senderName: String
//     text: String
//     createdAt: Timestamp
//     isRead: bool
// ─────────────────────────────────────────────────────────────────────────────

class MessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT CONVERSATION  —  represents a chat thread in the chats collection
// ─────────────────────────────────────────────────────────────────────────────

class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderUid;

  const ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantRoles,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderUid,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    final names = Map<String, String>.from(
        (map['participantNames'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            {});
    final roles = Map<String, String>.from(
        (map['participantRoles'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            {});
    return ChatConversation(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: names,
      participantRoles: roles,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt:
          (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSenderUid: map['lastSenderUid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        'participantNames': participantNames,
        'participantRoles': participantRoles,
        'lastMessage': lastMessage,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'lastSenderUid': lastSenderUid,
      };

  /// Returns the display name of the other participant (not currentUid)
  String otherName(String currentUid) {
    final otherUid =
        participants.firstWhere((p) => p != currentUid, orElse: () => '');
    return participantNames[otherUid] ?? 'អ្នកប្រើប្រាស់';
  }

  /// Returns the role of the other participant
  String otherRole(String currentUid) {
    final otherUid =
        participants.firstWhere((p) => p != currentUid, orElse: () => '');
    return participantRoles[otherUid] ?? '';
  }

  /// Returns the uid of the other participant
  String otherUid(String currentUid) {
    return participants.firstWhere((p) => p != currentUid, orElse: () => '');
  }
}