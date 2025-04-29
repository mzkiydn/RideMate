class Cart {
  final String id;
  final String userId;
  final String workshopId;
  final Map<String, int> productQuantities;
  final List<String> serviceIds;
  final String status;
  final double totalPrice;

  Cart({
    required this.id,
    required this.userId,
    required this.workshopId,
    required this.productQuantities,
    required this.serviceIds,
    required this.status,
    required this.totalPrice,
  });

  factory Cart.fromMap(String id, Map<String, dynamic> data) {
    return Cart(
      id: id,
      userId: data['Owner'] ?? '',
      workshopId: data['Workshop'] ?? '',
      productQuantities: Map<String, int>.from(data['Products'] ?? {}),
      serviceIds: List<String>.from(data['Services'] ?? []),
      status: data['Status'] ?? '',
      totalPrice: (data['Price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Owner': userId,
      'Workshop': workshopId,
      'Products': productQuantities,
      'Services': serviceIds,
      'Status': status,
      'Price': totalPrice,
    };
  }
}
