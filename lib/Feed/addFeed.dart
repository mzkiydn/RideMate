import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridemate/Domain/Feed.dart';
import 'package:ridemate/Feed/feedController.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ridemate/Template/masterScaffold.dart';

class AddFeed extends StatefulWidget {
  const AddFeed({super.key});

  @override
  _AddFeedState createState() => _AddFeedState();
}

class _AddFeedState extends State<AddFeed> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _mediaFile;
  String mediaType = 'None'; // Default to no media
  final FeedController _feedController = FeedController();
  String? userId;
  String? username;

  // Session
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }
  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid; // user ID
      });
      try {
        final userDoc = await FirebaseFirestore.instance.collection('User').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            username = userDoc['Username'] ?? 'Unknown'; // username
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching username: $e')),
        );
      }
    }
  }

  // Pick from gallery
  Future<void> _pickMedia() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = pickedFile;
        mediaType = 'Image';
      });
    }
  }

  // Add feed
  Future<void> _submitPost() async {
    // Validation input
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty')),
      );
      return;
    }
    // Validation session
    if (userId == null || username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to retrieve user information.')),
      );
      return;
    }
    // Set mediaUrl to null if no media is selected
    final mediaUrl = _mediaFile != null ? _mediaFile!.path : null;
    final newFeed = Feed(
      id: '',
      ownerId: userId!,
      username: username!,
      date: DateTime.now().toString(),
      contentText: _contentController.text,
      mediaUrl: mediaUrl, // Path for selected media
      mediaType: mediaType, // Either "None" or "Image"
    );

    try {
      await _feedController.addPost(newFeed);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post submitted successfully!')),
      );
      Navigator.pushNamed(context, '/feed');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Add Feed",
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/feed');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Display img
                    if (_mediaFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Image.file(
                          File(_mediaFile!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Add img button
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: IconButton(
                        icon: const Icon(Icons.image, size: 30),
                        onPressed: _pickMedia,
                        tooltip: 'Add Image',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Post button
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.cyan,
                    textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  child: const Text('Post'),
                ),
              ),
            ),
          ],
        ),
      ),
      currentIndex: 0,
    );
  }
}
