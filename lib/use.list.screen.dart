import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/auth.services.dart';
import 'package:messenger/conversation.service.dart';
import 'package:messenger/model/user.profile.model.dart';
import 'package:messenger/private.chat.scrren.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  UsersListScreenState createState() => UsersListScreenState();
}

class UsersListScreenState extends State<UsersListScreen> {
  final ConversationService _conversationService = ConversationService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messanger'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .map(
                      (doc) => UserProfile.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (user) =>
                          user.uid !=
                              FirebaseAuth
                                  .instance
                                  .currentUser!
                                  .uid && // Exclude current user
                          (_searchQuery.isEmpty ||
                              user.nickName.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              user.fullName.toLowerCase().contains(
                                _searchQuery,
                              )),
                    )
                    .toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No users found'
                          : 'No users match your search',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            user.nickName.isNotEmpty
                                ? user.nickName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.nickName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user.fullName),
                        // trailing: Icon(Icons.chat),
                        onTap: () async {
                          // Create or get conversation and navigate to chat
                          String conversationId = await _conversationService
                              .getOrCreateConversation(user.uid);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatScreen(
                                conversationId: conversationId,
                                otherUser: user,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
