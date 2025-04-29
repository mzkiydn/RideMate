class Service {
  final String id;
  final String name;
  final String description;
  final String availability;
  final double price;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.availability,
    required this.price,
  });

  factory Service.fromMap(Map<String, dynamic> data, String documentId) {
    return Service(
      id: documentId,
      name: data['Name'] ?? '',
      description: data['Description'] ?? '',
      availability: data['Availability'] ?? '',
      price: data['Price'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Description': description,
      'Availability': availability,
      'Price': price,
    };
  }
}
