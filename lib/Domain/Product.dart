class Product {
  final String id;
  final String name;
  final String description;
  final String availability;
  final double price;
  final int stock;
  final int order;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.availability,
    required this.price,
    required this.stock,
    required this.order,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['Name'] ?? '',
      description: data['Description'] ?? '',
      availability: data['Availability'] ?? '',
      price: data['Price'] ?? 0.0,
      stock: data['Stock'] ?? 0,
      order: data['Order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Description': description,
      'Availability': description,
      'Price': price,
      'Stock': stock,
      'Order': order,
    };
  }
}
