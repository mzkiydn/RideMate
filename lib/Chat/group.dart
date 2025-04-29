import 'package:flutter/material.dart';
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Chat/personal.dart';
import 'package:ridemate/Chat/system.dart';

class Group extends StatefulWidget {
  const Group({super.key});

  @override
  _GroupState createState() => _GroupState();
}

class _GroupState extends State<Group> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatController chatController;

  @override
  void initState() {
    super.initState();
    chatController = ChatController(); // Instantiate the controller
    _tabController = TabController(length: 3, vsync: this); // Initialize the TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose the TabController when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Chat"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Personal"),
            Tab(text: "Group"),
            Tab(text: "System"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Personal page content
                const Personal(),

                // Group page content
                ListView.builder(
                  itemCount: chatController.groupChatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatController.groupChatList[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(chat["name"]![0]), // First letter of the name
                      ),
                      title: Text(
                        chat["name"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(chat["message"]!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chat["time"]!,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(width: 8), // Space between time and icon
                          // Icon for read/unread status
                          chat["isRead"]
                              ? SizedBox.shrink() // Read
                              : const Icon(Icons.circle, color: Colors.red, size: 16), // Unread
                        ],
                      ),
                      onTap: () {
                        // Mark as read when tapped
                        setState(() {
                          chatController.markAsRead(index, isGroup: true);
                        });

                        // Navigate to ChatDetail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetail(name: chat["name"]!),
                          ),
                        );
                      },
                    );
                  },
                ),

                // System page content
                const System(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
