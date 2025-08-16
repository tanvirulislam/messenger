import 'package:cloud_firestore/cloud_firestore.dart';

class PrivateMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderNickName;
  final String receiverId;
  final DateTime createdAt;
  final bool isRead;

  PrivateMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderNickName,
    required this.receiverId,
    required this.createdAt,
    required this.isRead,
  });

  factory PrivateMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PrivateMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderNickName: data['senderNickName'] ?? 'Unknown',
      receiverId: data['receiverId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderNickName': senderNickName,
      'receiverId': receiverId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
