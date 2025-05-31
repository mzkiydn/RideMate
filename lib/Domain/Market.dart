class Market {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final double price;
  final DateTime datePosted;
  final double latitude;
  final double longitude;
  final String img;


  // Constructor
  Market({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.price,
    required this.datePosted,
    required this.latitude,
    required this.longitude,
    required this.img,
  });

  // Factory method to create a Market from Firestore data
  factory Market.fromFirestore(Map<String, dynamic> data, String id) {
    return Market(
      id: id,
      ownerId: data['Owner'] ?? '',
      name: data['Name'] ?? '',
      description: data['Description'] ?? '',
      price: data['Price'] ?? 0.0,
      datePosted: (data['Date']),
      latitude: data['Latitude'] ?? 0.0,
      longitude: data['Longitude'] ?? 0.0,
      img: data['Image'] ?? '',
    );
  }

  // Method to convert a Market to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'Owner': ownerId,
      'Name': name,
      'Description': description,
      'Price': price,
      'Date': datePosted,
      'Latitude': latitude,
      'Longitude': longitude,
      'Image': img,
    };
  }
}
