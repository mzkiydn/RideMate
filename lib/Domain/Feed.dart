class Feed {
  final String id;
  final String ownerId;
  final String username;
  final String date;
  final String contentText;
  final String? mediaUrl; // Can store image or video URL (optional)
  final String mediaType; // Either "none", "image", or "video"
  final int likeCount;
  final int commentCount;

  Feed({
    required this.id,
    required this.ownerId,
    required this.username,
    required this.date,
    required this.contentText,
    this.mediaUrl,
    this.mediaType = 'None', // Default: no media
    this.likeCount = 0,
    this.commentCount = 0,
  });

  // Convert a Feed object to JSON
  Map<String, dynamic> toJson() {
    return {
      'Feed ID': id,
      'Owner ID': ownerId,
      'Owner': username,
      'Date': date,
      'Content': contentText,
      'URL': mediaUrl,
      'Media Type': mediaType,
      'Like Count': likeCount,
      'Comment Count': commentCount,
    };
  }

  // Factory method to create a Feed object from JSON
  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['Feed ID'] as String,
      ownerId: json['Owner ID'] as String,
      username: json['Owner'] as String,
      date: json['Date'] as String,
      contentText: json['Content'] as String,
      mediaUrl: json['URL'] as String?,
      mediaType: json['Media Type'] as String,
      likeCount: json['Like Count'] as int,
      commentCount: json['Comment Count'] as int,
    );
  }
}
