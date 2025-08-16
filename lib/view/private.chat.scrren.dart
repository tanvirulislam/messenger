import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger/helper.method/auth.services.dart';
import 'package:messenger/helper.method/conversation.service.dart';
import 'package:messenger/model/private.message.dart';
import 'package:messenger/model/user.profile.model.dart';

class PrivateChatScreen extends StatefulWidget {
  final String conversationId;
  final UserProfile otherUser;

  const PrivateChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  PrivateChatScreenState createState() => PrivateChatScreenState();
}

class PrivateChatScreenState extends State<PrivateChatScreen> {
  final _messageController = TextEditingController();
  final ConversationService _conversationService = ConversationService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    _conversationService.markMessagesAsRead(widget.conversationId);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _conversationService.sendMessage(
        widget.conversationId,
        widget.otherUser.uid,
        _messageController.text.trim(),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                widget.otherUser.nickName.isNotEmpty
                    ? widget.otherUser.nickName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.nickName, style: TextStyle(fontSize: 16)),
                Text(
                  widget.otherUser.fullName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _conversationService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs
                    .map((doc) => PrivateMessage.fromFirestore(doc))
                    .toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start your conversation with ${widget.otherUser.nickName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe =
                        message.senderId == _authService.currentUser?.uid;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                message.senderNickName.isNotEmpty
                                    ? message.senderNickName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (!isMe) SizedBox(width: 8),

                          Column(
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.grey[300],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                    bottomLeft: isMe
                                        ? Radius.circular(12)
                                        : Radius.circular(2),
                                    bottomRight: isMe
                                        ? Radius.circular(2)
                                        : Radius.circular(12),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Text(
                              //   TimeFormatter.formatMessageTime(
                              //     message.createdAt,
                              //   ),
                              //   style: TextStyle(
                              //     fontSize: 10,
                              //     color: Colors.grey.shade500,
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
