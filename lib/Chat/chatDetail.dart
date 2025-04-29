import 'package:flutter/material.dart';
import 'package:ridemate/Chat/chatController.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'dart:io'; // Required for File
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ridemate/Template/masterScaffold.dart'; // Import provider

class ChatDetail extends StatefulWidget {
  final String name; // Name of the person you're chatting with

  const ChatDetail({super.key, required this.name});

  @override
  _ChatDetailState createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final TextEditingController _controller = TextEditingController();
  XFile? _image; // Variable to hold the selected image
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    // Get the ChatController using Provider
    final chatController = Provider.of<ChatController>(context, listen: false);

    Future<void> _pickImage() async {
      // Allow user to pick an image from the gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = pickedFile; // Store the selected image
      });

      // Add the selected image to the chat
      if (_image != null) {
        String time = TimeOfDay.now().format(context);
        chatController.addImageMessage(widget.name, _image!.path, time, 'sent');
      }
    }

    void _sendMessage() {
      if (_controller.text.isNotEmpty) {
        String time = TimeOfDay.now().format(context);
        chatController.addNewPersonalMessage(widget.name, _controller.text, time, 'text');
        _controller.clear();
      }
    }


    // Get the messages for this chat
    List<Map<String, dynamic>> messages = chatController.getMessages(widget.name);

    return MasterScaffold(
      customBarTitle: widget.name,
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                // Ensure type and message exist before accessing them
                final isSent = message['type'] != null && message['type'] == 'sent';

                return Align(
                  alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.blue.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Check if the message is an image
                        if (message['type'] == 'image') // Check if the type is image
                          Image.file(
                            File(message['message']!), // Fixed field name from 'text' to 'message'
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else
                          Text(
                            message['message'] ?? '', // Provide a fallback for message field
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'] ?? '', // Provide a fallback for time field
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Image icon
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: IconButton(
                    icon: const Icon(Icons.image, size: 30),
                    onPressed: _pickImage,
                    tooltip: 'Add Image',
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      currentIndex: 3, // Set this based on the desired initial tab
      // showBottomNavigationBar: false,
    );
  }
}
