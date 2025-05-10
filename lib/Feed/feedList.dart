import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridemate/Domain/Feed.dart';
import 'package:ridemate/Feed/feedController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class FeedList extends StatefulWidget {
  const FeedList({super.key});

  @override
  _FeedListState createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  final FeedController feedController = FeedController();
  String? userId;
  String? username;
  Map<String, bool> expandedComments = {}; // To track the state of comment sections

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
        userId = user.uid; // Set user ID
      });

      try {
        final userDoc = await FirebaseFirestore.instance.collection('User').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            username = userDoc['Username'] ?? 'Unknown'; // Set username
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching username: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Feed",
      rightCustomBarAction: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/addFeed');
        },
      ),
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
                  contentText: post.contentText,
                  contentImageUrl: post.mediaUrl,
                  likeCount: post.likeCount,
                  commentCount: post.commentCount,
                  feedId: post.id,
                  userId: userId ?? 'Unknown',  // Pass the current user ID
                  ownerId: post.ownerId,  // Pass the current user ID
                  onCommentToggle: (bool isExpanded) {
                    setState(() {
                      expandedComments[post.id] = isExpanded;
                    });
                  },
                  isCommentExpanded: expandedComments[post.id] ?? false, // pass the current state
                );
              },
            );
          }
        },
      ),
      currentIndex: 0,
    );
  }
}

class PostingCard extends StatefulWidget {
  const PostingCard({
    required this.username,
    required this.date,
    required this.contentText,
    this.contentImageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.feedId,
    required this.userId,
    required this.ownerId,
    required this.onCommentToggle,
    required this.isCommentExpanded, // add this
    Key? key,
  }) : super(key: key);

  final String username;
  final String date;
  final String contentText;
  final String? contentImageUrl;
  final int likeCount;
  final int commentCount;
  final String feedId;
  final String userId;
  final String ownerId;
  final ValueChanged<bool> onCommentToggle;
  final bool isCommentExpanded;


  @override
  _PostingCardState createState() => _PostingCardState();
}

class _PostingCardState extends State<PostingCard> {
  final FeedController feedController = FeedController();
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likeCount;
  }


  Future<List<Map<String, dynamic>>> _getComments() async {
    final comments = await FeedController().viewComments(widget.feedId);
    print('Feed');
    print(widget.feedId);
    return comments;
  }

  void _toggleComments() {
    widget.onCommentToggle(!widget.isCommentExpanded); // toggle state from parent
  }

  // Delete a feed
  Future<void> _deleteFeed(String feedId) async {
    try {
      await feedController.deleteFeed(feedId);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feed deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting feed: $e')),
      );
    }
  }

  // Show confirmation dialog
  Future<void> _showDeleteConfirmationDialog(String feedId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this feed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteFeed(feedId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _commentController = TextEditingController();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Username and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Content Text
            Text(
              widget.contentText,
              style: const TextStyle(fontSize: 14),
            ),
            // Content Image (optional)
            if (widget.contentImageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.contentImageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Like and Comment Section
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      onPressed: () async {
                        bool liked = await FeedController().like(widget.feedId, widget.userId);
                        setState(() {
                          _likeCount += liked ? 1 : -1;
                        });
                      },
                    ),
                    Text(_likeCount.toString()),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: _toggleComments, // Show comments
                    ),
                    Text(widget.commentCount.toString()),
                    // Delete icon for the current user's post
                    if (widget.userId == widget.ownerId)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(widget.feedId); // Show delete confirmation dialog
                        },
                      ),
                  ],
                ),
              ],
            ),
            // Show comments section when expanded
            if (widget.isCommentExpanded)
              Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comments List
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getComments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('No comments yet.', style: TextStyle(fontSize: 12)),
                          );
                        } else {
                          return Column(
                            children: snapshot.data!.map((comment) {
                              return ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                contentPadding: EdgeInsets.zero,
                                title: Text(comment['Username'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text(comment['Comment'], style: const TextStyle(fontSize: 12)),
                                trailing: comment['id'] == FirebaseAuth.instance.currentUser?.uid
                                    ? IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () async {
                                    await FeedController().removeComment(widget.feedId, comment['id']);
                                    setState(() {});
                                  },
                                )
                                    : null,
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    // Comment Input Field
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Write a comment...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, size: 20),
                            onPressed: () async {
                              if (_commentController.text.trim().isEmpty) return;
                              await FeedController().addComment(widget.feedId, widget.userId, _commentController.text.trim());
                              _commentController.clear();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )

          ],
        ),
      ),
    );
  }
}
