import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridemate/Domain/Cart.dart';

class ServiceController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all workshops from Firestore
  Future<List<Map<String, dynamic>>> getWorkshops() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Workshop').get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'Name': doc['Name'],
          'Operating Hours': doc['Operating Hours'], // Modify this if needed
          'Contact': doc['Contact'],
          'Rating': doc['Rating'],
          'Latitude': doc['Latitude'],
          'Longitude': doc['Longitude'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching workshops: $e');
      return [];
    }
  }

  // fetch all products
  Future<List<Map<String, dynamic>>> fetchProducts(String workshopId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Products')
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // Store the product ID
          ...doc.data() as Map<String, dynamic>, // Merge with product attributes
        };
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // fetch all services
  Future<List<Map<String, dynamic>>> fetchServices(String workshopId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Workshop')
          .doc(workshopId)
          .collection('Services')
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // Store the product ID
          ...doc.data() as Map<String, dynamic>, // Merge with product attributes
        };
      }).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Function to handle search action (expand functionality as needed)
  void onSearch() {
    print("Search button pressed");
  }

  // initiate map
  Future<List<Map<String, dynamic>>> initializeMap(LatLng userLocation, int type) async {
    final Distance distance = Distance();

    if (type == 0) {
      final allWorkshops = await getWorkshops();
      final sortedWorkshops = allWorkshops.map((workshop) {
        final LatLng loc = LatLng(
          double.parse(workshop['Latitude'].toString()),
          double.parse(workshop['Longitude'].toString()),
        );
        final double km = distance.as(LengthUnit.Kilometer, userLocation, loc);
        return {...workshop, 'Distance': km};
      }).toList();

      sortedWorkshops.sort((a, b) =>
          (a['Distance'] as double).compareTo(b['Distance'] as double));

      final nearby = sortedWorkshops.where((w) => w['Distance'] <= 20.0).toList();
      return nearby.isNotEmpty ? nearby : sortedWorkshops;

    } else if (type == 1) {

      final allHelp = await getHelpRequests();
      final sortedHelps = allHelp.map((help) {
        final LatLng loc = LatLng(
          double.parse(help['Latitude'].toString()),
          double.parse(help['Longitude'].toString()),
        );
        final double km = distance.as(LengthUnit.Kilometer, userLocation, loc);
        return {...help, 'Distance': km};
      }).toList();

      sortedHelps.sort((a, b) =>
          (a['Distance'] as double).compareTo(b['Distance'] as double));

      final nearby = sortedHelps.where((w) => w['Distance'] <= 20.0).toList();
      return nearby.isNotEmpty ? nearby : sortedHelps;
    }

    // Ensure you return an empty list if `type` is neither 0 nor 1
    return [];
  }

  Stream<List<Map<String, dynamic>>> getHelpRequestsStream() {
    return FirebaseFirestore.instance
        .collection('Emergency')
        .where('Status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Latitude': data['Latitude'],
          'Longitude': data['Longitude'],
          'Owner': data['Owner'],
          'Date': data['Date'],
          'Description': data['Description'],
          'Status': data['Status'],
        };
      }).toList();
    });
  }

  // get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permission denied.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permission permanently denied.");
        return null;
      }

      Position position = await Geolocator.getCurrentPosition();
      print("Current user location: (${position.latitude}, ${position.longitude})");
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // create emergency
  Future<void> requestHelp(LatLng userLocation, String helpDescription) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("User not logged in.");
      return;
    }

    final helpRequestData = {
      'Latitude': userLocation.latitude,
      'Longitude': userLocation.longitude,
      'Status': 'Pending',
      'Owner': currentUser.uid,
      'Date': DateTime.now(),
      'Description': helpDescription,
    };

    await FirebaseFirestore.instance.collection('Emergency').add(helpRequestData);
    print("Help request sent!");
  }

  // display emergency that is pending
  Future<List<Map<String, dynamic>>> getHelpRequests() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Emergency')
          .where('Status', isEqualTo: 'Pending')
          .get();

      // Await all async operations and gather results into a List<Map<String, dynamic>>
      final List<Map<String, dynamic>> helpRequests = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final userDoc = await FirebaseFirestore.instance.collection('User').doc(data['Owner']).get();

          return {
            'id': doc.id,
            'Latitude': data['Latitude'],
            'Longitude': data['Longitude'],
            'Owner': data['Owner'],
            'Date': data['Date'],
            'Description': data['Description'],
            'Status': data['Status'],
            'Owner Name': userDoc['Username'],
          };
        }),
      );

      return helpRequests;
    } catch (e) {
      print('Error fetching help requests: $e');
      return [];
    }
  }

  // update emergency status to solve
  Future<void> markHelpAsSolved(String requestId) async {
    await FirebaseFirestore.instance.collection('Emergency').doc(requestId).update({
      'Status': 'Solved',
    });
    print("Help request marked as solved!");
  }

}
