import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridemate/Domain/Feed.dart';
import 'package:intl/intl.dart';

class FeedController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the userType from Firestore
  Future<String> fetchUserType(String userId) async {
    try {
      final userDoc = await _firestore.collection('User').doc(userId).get();
      if (userDoc.exists) {
        return userDoc['Type'] ?? '';  // Return userType from Firestore, or empty string if not found
      } else {
        return '';  // If user document doesn't exist, return an empty string
      }
    } catch (e) {
      throw Exception('Error fetching user type: $e');
    }
  }

  // Fetch
  Future<List<Feed>> fetchPosts() async {
    try {
      // Fetch posts sorted by 'Date' in descending order (latest first)
      final snapshot = await _firestore
          .collection('Feed')
          .orderBy('Date', descending: true)
          .get();

      // Get username for each post
      List<Feed> posts = [];
      for (var doc in snapshot.docs) {
        String ownerId = doc['Owner ID'];
        final userDoc = await _firestore.collection('User').doc(ownerId).get();
        String username = userDoc.exists ? userDoc['Username'] ?? 'Unknown' : 'Unknown';

        // Change the date format
        Timestamp rawDate = doc['Date'];
        DateTime dateTime = rawDate.toDate();
        String formattedDate = DateFormat('dd MMM yy HH:mm').format(dateTime); // Format the date

        // Add the post to the list
        posts.add(
          Feed(
            id: doc.id,
            ownerId: ownerId,
            username: username,
            date: formattedDate,
            contentText: doc['Content'],
            mediaUrl: doc['URL'],
          ),
        );
      }

      return posts;
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  // Add
  Future<void> addPost(Feed feed) async {
    try {
      await _firestore.collection('Feed').add({
        'Owner ID': feed.ownerId,
        'Owner': feed.username,
        'Date': Timestamp.now(),
        'Content': feed.contentText,
        'URL': feed.mediaUrl,
        'Media Type': feed.mediaType,
      });
    } catch (e) {
      throw Exception('Failed to submit post: $e');
    }
  }
}
