import 'package:flutter/material.dart';
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Chat/group.dart';
import 'package:ridemate/Chat/system.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Personal extends StatefulWidget {
  const Personal({super.key});

  @override
  _PersonalState createState() => _PersonalState();
}

class _PersonalState extends State<Personal> with SingleTickerProviderStateMixin {
  late ChatController chatController;
  late TabController _tabController;

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
    return MasterScaffold(
      customBarTitle: "Notification",
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // TabBar
          Column(
            children: [
              TabBar(
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

              // content for each tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Personal Tab
                    ListView.builder(
                      itemCount: chatController.personalChatList.length,
                      itemBuilder: (context, index) {
                        final chat = chatController.personalChatList[index];

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
                              chatController.markAsRead(index);
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

                    // Group page content
                    const Group(),

                    // System page content
                    const System(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // Bottom navigation bar
      currentIndex: 3,
    );
  }
}
