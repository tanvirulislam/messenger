import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger/model/user.profile.model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserProfile(UserProfile userProfile) async {
    await _firestore
        .collection('users')
        .doc(userProfile.uid)
        .set(userProfile.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> isNickNameAvailable(String nickName) async {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('nickName', isEqualTo: nickName)
        .get();
    return query.docs.isEmpty;
  }
}
