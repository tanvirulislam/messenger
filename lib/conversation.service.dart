import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/use.sevices.dart';

class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Create or get existing conversation between two users
  Future<String> getOrCreateConversation(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    // Create conversation ID (always same order for consistency)
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String conversationId = ids.join('_');

    DocumentSnapshot doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) {
      // Create new conversation
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageSender': '',
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  // Send a private message
  Future<void> sendMessage(
    String conversationId,
    String receiverId,
    String message,
  ) async {
    final currentUser = _auth.currentUser!;
    final userProfile = await _userService.getUserProfile(currentUser.uid);

    // Add message to messages subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
          'text': message,
          'senderId': currentUser.uid,
          'senderNickName': userProfile?.nickName ?? 'Unknown',
          'receiverId': receiverId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

    // Update conversation with last message info
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'lastMessageSender': currentUser.uid,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });
  }

  // Get messages for a conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get user's conversations
  Stream<QuerySnapshot> getUserConversations() {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUserId = _auth.currentUser!.uid;

    // Reset unread count for current user
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$currentUserId': 0,
    });

    // Mark individual messages as read
    QuerySnapshot unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (QueryDocumentSnapshot doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
