import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/model/user.profile.model.dart';
import 'package:messenger/use.sevices.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String nickName,
    required String phone,
    required String address,
    required DateTime dateOfBirth,
  }) async {
    try {
      // Check if nickname is available
      bool isNickNameAvailable = await _userService.isNickNameAvailable(
        nickName,
      );
      if (!isNickNameAvailable) {
        return 'Nickname is already taken. Please choose another one.';
      }

      // Create Firebase Auth user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      UserProfile userProfile = UserProfile(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        nickName: nickName,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
      );

      await _userService.createUserProfile(userProfile);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred during registration. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
