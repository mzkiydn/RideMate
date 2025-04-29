import 'package:flutter/material.dart';
import 'package:ridemate/Domain/Feed.dart';
import 'package:ridemate/Feed/feedController.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:ridemate/Template/masterScaffold.dart';

// need to add comment like section and function

class FeedList extends StatelessWidget {
  const FeedList({super.key});

  @override
  Widget build(BuildContext context) {
    final feedController = FeedController();

    return MasterScaffold(
      // Custom bar
      customBarTitle: "Feed",
      rightCustomBarAction: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/addFeed');
        },
      ),

      // Body content
      body: FutureBuilder<List<Feed>>(
        future: feedController.fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No posts available."));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                return PostingCard(
                  username: post.username,
                  date: post.date,
                  // avatarUrl: post.avatarUrl ?? '', // Use avatar URL or fallback // waiting for profile module
                  contentText: post.contentText,
                  contentImageUrl: post.mediaUrl, // Display content image
                );
              },
            );
          }
        },
      ),

      // Bottom navigation bar
      currentIndex: 0,
    );
  }
}

class PostingCard extends StatelessWidget {
  const PostingCard({
    required this.username,
    required this.date,
    // required this.avatarUrl,
    required this.contentText,
    this.contentImageUrl,
    Key? key,
  }) : super(key: key);

  final String username;
  final String date;
  // final String avatarUrl;
  final String contentText;
  final String? contentImageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Username and Date (inline with username on the right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between username and date
              children: [
                // Username
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Date (aligned to the right)
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey, // Optional: Makes the date text a bit lighter
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Content Text
            Text(
              contentText,
              style: const TextStyle(fontSize: 14),
            ),
            // Content Image (optional)
            if (contentImageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    contentImageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

