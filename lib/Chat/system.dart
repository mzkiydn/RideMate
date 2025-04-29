import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Ensure provider is imported
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Chat/group.dart';
import 'package:ridemate/Chat/personal.dart';

class System extends StatelessWidget {
  const System({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, chatController, child) {
        return Scaffold(
          body: Column(
            children: [
              // TabBarView to show the corresponding content for each tab
              Expanded(
                child: TabBarView(
                  children: [

                    // Personal page content
                    const Personal(),

                    // Group page content
                    const Group(),

                    // System page content (chat list)
                    ListView.builder(
                      itemCount: chatController.systemChatList.length,
                      itemBuilder: (context, index) {
                        final chat = chatController.systemChatList[index];

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
                            chatController.markAsRead(index, isGroup: false);

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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
