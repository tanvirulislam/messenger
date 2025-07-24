import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String userId;
  final String userEmail;
  final DateTime createdAt;
  final String? nickName;

  Message({
    required this.id,
    required this.text,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
    this.nickName,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nickName: data['nickName'] ?? 'Unknown',
    );
  }
}
