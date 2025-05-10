import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get list of chat documents where the current user/workshop is a participant
  Future<List<Map<String, dynamic>>> getChats(String currentId) async {
    try {
      final snapshot = await _firestore
          .collection('Chat')
          .where('Participants', arrayContains: currentId)
          .orderBy('Last Timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  /// Search users and workshops by name
  Future<List<Map<String, dynamic>>> searchUsersAndWorkshops(String query) async {
    List<Map<String, dynamic>> results = [];
    final user = _auth.currentUser;
    String? currentUserId = user!.uid;

    // Search users by unique Username
    final userSnapshot = await _firestore
        .collection('User')
        .where('Username', isGreaterThanOrEqualTo: query)
        .where('Username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    for (var doc in userSnapshot.docs) {
      final data = doc.data();
      if (doc.id == currentUserId) continue; // exclude self
      data['Type'] = 'User';
      data['Title'] = data['Name'];
      data['id'] = 'User.${doc.id}';
      results.add(data);
    }

    final workshopSnapshot = await _firestore
        .collection('Workshop')
        .where('Name', isGreaterThanOrEqualTo: query)
        .where('Name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    for (var doc in workshopSnapshot.docs) {
      final data = doc.data();
      if (data['Owner'] == currentUserId) continue; // exclude self
      results.add({
        'Type': 'Workshop',
        'Title': data['Name'],
        'id': 'Workshop.${data['Owner']}'
      });
    }

    return results;
  }

  /// Get messages for a specific chat ID
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('Messages')
        .orderBy('Timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // fetch other user data
  Future<Map<String, String>> getDisplayInfo(String userId) async {
    final workshopSnap = await FirebaseFirestore.instance
        .collection('Workshop')
        .where('Owner', isEqualTo: userId)
        .limit(1)
        .get();

    if (workshopSnap.docs.isNotEmpty) {
      final userSnap = await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .get();
      final user = userSnap.data()!;

      final data = workshopSnap.docs.first.data();
      return {
        'Name': data['Name'],
        'Username': user['Username'], // optional: static label
      };
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('User')
        .doc(userId)
        .get();

    if (userSnap.exists) {
      final data = userSnap.data()!;
      return {
        'Name': data['Name'],
        'Username': data['Username'],
      };
    }

    return {
      'Name': 'Unknown',
      'Username': '',
    };
  }

  /// Send a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    required List<String> participants,
  }) async {
    final now = Timestamp.now();

    await _firestore.collection('Chat').doc(chatId).set({
      'Participants': participants,
      'Last Message': message,
      'Last Timestamp': now,
      'Last Sender': senderId,
    }, SetOptions(merge: true));

    await _firestore
        .collection('Chat')
        .doc(chatId)
        .collection('Messages')
        .add({
      'Sender': senderId,
      'Message': message,
      'Timestamp': now,
      'Seen': [senderId],
    });
  }

  /// Generate a consistent chat ID using two user/workshop IDs
  String generateChatId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}|${sorted[1]}';
  }
}
