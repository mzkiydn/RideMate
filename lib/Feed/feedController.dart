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

  // Fetch post
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
            image: doc['Image'],
            likeCount: doc['Like Count'] ?? 0,
            commentCount: doc['Comment Count'] ?? 0,
          ),
        );
      }

      return posts;
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  // Add feed
  Future<void> addPost(Feed feed) async {
    try {
      await _firestore.collection('Feed').add({
        'Owner ID': feed.ownerId,
        'Owner': feed.username,
        'Date': Timestamp.now(),
        'Content': feed.contentText,
        'Image': feed.image,
        'Like Count': 0,
        'Comment Count': 0,
      });
    } catch (e) {
      throw Exception('Failed to submit post: $e');
    }
  }

  Future<void> deleteFeed(String feedId) async {
    final feedRef = _firestore.collection('Feed').doc(feedId);
    await feedRef.delete();
  }

  // add like
  Future<bool> like(String feedId, String userId) async {
    final likeRef = _firestore.collection('Feed').doc(feedId).collection('Like').doc(userId);
    final feedRef = _firestore.collection('Feed').doc(feedId);

    final snapshot = await likeRef.get();
    if (!snapshot.exists) {
      await likeRef.set({'Time': Timestamp.now()});
      await feedRef.update({'Like Count': FieldValue.increment(1)});
      return true;
    } else {
      await likeRef.delete();
      await feedRef.update({'Like Count': FieldValue.increment(-1)});
      return false;
    }
  }

  // add comment
  Future<void> addComment(String feedId, String userId, String text) async {
    final commentRef = _firestore.collection('Feed').doc(feedId).collection('Comment').doc();
    final feedRef = _firestore.collection('Feed').doc(feedId);
    String? username;

    final userDoc = await _firestore.collection('User').doc(userId).get();
    if (userDoc.exists) {
      username = userDoc['Username'] ?? 'Unknown';  // Return userType from Firestore, or empty string if not found
    }

    await commentRef.set({
      'id': commentRef.id,
      'Owner': userId,
      'Username': username,
      'Comment': text,
      'Time': Timestamp.now(),
    });

    await feedRef.update({'Comment Count': FieldValue.increment(1)});
  }

  // view comment
  Future<List<Map<String, dynamic>>> viewComments(String feedId) async {
    print('View comment');
    final snapshot = await _firestore
        .collection('Feed')
        .doc(feedId)
        .collection('Comment')
        .orderBy('Time', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // ✅ Add commentId for deletion
      return data;
    }).toList();
  }

  // remove comment
  Future<void> removeComment(String feedId, String commentId) async {
    final commentRef = _firestore.collection('Feed').doc(feedId).collection('Comment').doc(commentId);
    final feedRef = _firestore.collection('Feed').doc(feedId);

    await commentRef.delete();
    await feedRef.update({'Comment Count': FieldValue.increment(-1)});
  }

}
