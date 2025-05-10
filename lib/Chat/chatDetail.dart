import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class ChatDetail extends StatefulWidget {
  final String otherUserId;

  const ChatDetail({
    required this.otherUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final ChatController _chatController = ChatController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserId;
  String? _chatId;
  String? _displayName;
  String? _username;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _currentUserId = user.uid;
    _chatId = _chatController.generateChatId(_currentUserId!, widget.otherUserId);

    print(widget.otherUserId);

    // 🔍 Fetch display name (from workshops or users)
    final workshopSnapshot = await FirebaseFirestore.instance
        .collection('Workshop')
        .where('Owner', isEqualTo: widget.otherUserId)
        .limit(1)
        .get();

    if (workshopSnapshot.docs.isNotEmpty) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(widget.otherUserId)
          .get();

      final data = workshopSnapshot.docs.first.data();
      final user = userSnapshot.data()!;

      _displayName = data['Name'];
      _username = user['Username'];

    } else {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(widget.otherUserId)
          .get();

      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        _displayName = data['Name'];
        _username = data['Username'];
      }
    }


    setState(() {});
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null || _currentUserId == null) return;

    await _chatController.sendMessage(
      chatId: _chatId!,
      senderId: _currentUserId!,
      message: text,
      participants: [_currentUserId!, widget.otherUserId],
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null || _currentUserId == null || _displayName == null) {
      return MasterScaffold(
        customBarTitle: "Loading...",
        body: Center(child: CircularProgressIndicator()), currentIndex: 3,
      );
    }

    return MasterScaffold(
      customBarTitle: '$_displayName\n@$_username',
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatController.getMessages(_chatId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['Sender'] == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg['Message']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ), currentIndex: 3,
    );
  }
}
