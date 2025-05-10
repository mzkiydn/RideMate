import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ChatController _chatController = ChatController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _chats = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await _loadChats();
    }
  }

  Future<void> _loadChats() async {
    if (_currentUserId == null) return;
    final chats = await _chatController.getChats(_currentUserId!);
    setState(() => _chats = chats);
  }

  // Helper to extract pure UID from string
  String extractUid(dynamic id) {
    final raw = id.toString();
    final prefixes = ['User.', 'Workshop.'];

    for (final prefix in prefixes) {
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length);
      }
    }

    return raw;
  }

  // Function to handle search
  Future<void> _searchUserOrWorkshop() async {
    final TextEditingController _searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Search User or Workshop"),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: "Enter username or workshop name"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  // Perform search (either for users or workshops)
                  final results = await _chatController.searchUsersAndWorkshops(query);
                  print("Search Results: $results"); // Print all search results

                  Navigator.pop(context); // Close the dialog

                  // Show results and navigate to the selected chat
                  _showSearchResults(results);
                } else {
                  Navigator.pop(context); // Close the dialog if query is empty
                }
              },
              child: Text("Search"),
            ),
          ],
        );
      },
    );
  }

  // Show search results and allow navigation to ChatDetail
  void _showSearchResults(List<Map<String, dynamic>> results) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Search Results"),
          content: Container(
            height: 300,
            width: 300,
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final otherId = extractUid(result['id']);

                // Print each result for debugging
                print("Result $index: $result");
                print("otherId: $otherId");

                return ListTile(
                  title: Text(result['Title'] ?? "No Name"),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat/detail',
                      arguments: {'otherUserId': otherId},
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return MasterScaffold(
        customBarTitle: "Chat",
        rightCustomBarAction: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _searchUserOrWorkshop,
        ),
        body: Center(child: CircularProgressIndicator()),
        currentIndex: 3,
      );
    }

    return MasterScaffold(
      customBarTitle: "Chat",
      rightCustomBarAction: IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: _searchUserOrWorkshop,
      ),
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final rawOtherId = (chat['Participants'] as List)
              .firstWhere((id) => id != _currentUserId);
          final otherId = extractUid(rawOtherId);

          return FutureBuilder<Map<String, String>>(
            future: _chatController.getDisplayInfo(otherId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListTile(
                  title: Text("Loading..."),
                  subtitle: Text("Fetching user..."),
                );
              }

              final info = snapshot.data!;
              final lastMsg = chat['Last Sender'] == _currentUserId
                  ? "You: ${chat['Last Message']}"
                  : chat['Last Message'];

              return ListTile(
                title: Text(info['Name'] ?? "Unknown"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("@${info['Username'] ?? ""}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chat/detail',
                    arguments: {'otherUserId': otherId},
                  );
                },
              );
            },
          );
        },
      ),
      currentIndex: 3,
    );
  }
}
