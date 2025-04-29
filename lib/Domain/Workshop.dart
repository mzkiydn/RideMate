import 'package:ridemate/Domain/Product.dart';
import 'package:ridemate/Domain/Service.dart';
import 'package:ridemate/Domain/Shift.dart';

class Workshop {
  final String id;
  final String owner;
  final String name;
  final String contact;
  final String operatingHours;
  final double latitude;
  final double longitude;
  final double rating;
  final List<Product> products;
  final List<Service> services;
  final List<Shift> shifts;

  Workshop({
    required this.id,
    required this.owner,
    required this.name,
    required this.contact,
    required this.operatingHours,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.products,
    required this.services,
    required this.shifts,
  });

  factory Workshop.fromMap(Map<String, dynamic> data, String documentId) {
    var products = <Product>[];
    var services = <Service>[];
    var shifts = <Shift>[];

    // Parse products, services, and shifts subcollections
    if (data['Products'] != null) {
      products = (data['Products'] as List).map((item) => Product.fromMap(item, item['id'])).toList();
    }
    if (data['Services'] != null) {
      services = (data['Services'] as List).map((item) => Service.fromMap(item, item['id'])).toList();
    }
    if (data['Shifts'] != null) {
      shifts = (data['Shifts'] as List).map((item) => Shift.fromMap(item, item['id'])).toList();
    }

    return Workshop(
      id: documentId,
      owner: data['Owner'] ?? '',
      name: data['Name'] ?? '',
      contact: data['Contact'] ?? '',
      operatingHours: data['Operating Hours'] ?? '',
      latitude: data['Latitude'] ?? 0.0,
      longitude: data['Longitude'] ?? 0.0,
      rating: data['Rating'] ?? 0.0,
      products: products,
      services: services,
      shifts: shifts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Owner': owner,
      'Contact': contact,
      'Operating Hours': operatingHours,
      'Latitude': latitude,
      'Longitude': longitude,
      'Rating': rating,
      'Products': products.map((e) => e.toMap()).toList(),
      'Services': services.map((e) => e.toMap()).toList(),
      'Shifts': shifts.map((e) => e.toMap()).toList(),
    };
  }
}
