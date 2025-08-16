import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/helper.method/use.sevices.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<void> sendMessage(String message) async {
    final User? user = _auth.currentUser;
    final userProfile = await _userService.getUserProfile(user?.uid ?? '');
    if (user != null) {
      await _firestore.collection('messages').add({
        'text': message,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'userName': userProfile?.nickName ?? 'Unknown',
      });
    }
  }

  Stream<QuerySnapshot> getMessages() {
    return _firestore
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
