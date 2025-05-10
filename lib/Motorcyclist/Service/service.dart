import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Service/detailProduct.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridemate/Template/masterScaffold.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'serviceController.dart';

class Service extends StatefulWidget {
  Service({super.key});

  @override
  _ServiceState createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
  final ServiceController serviceController = ServiceController();
  List<Map<String, dynamic>> workshops = [];
  List<Map<String, dynamic>> products = [];
  LatLng? _userLocation;
  final Distance distance = const Distance();
  MapController? _mapController; // MapController is nullable
  bool isOwner = false; // Simulate the role of the user (owner or not)
  String helpDescription = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    initializeMap();
  }

  Future<void> initializeMap() async {
    final userLocation = await serviceController.getCurrentLocation();
    if (userLocation != null) {
      final nearbyWorkshops = await serviceController.initializeMap(userLocation);
      setState(() {
        _userLocation = userLocation;
        workshops = nearbyWorkshops;
      });
    }
  }

  Future<void> requestHelp() async {
    if (_userLocation == null) {
      print("Location is required to request help.");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Emergency Description'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                helpDescription = value;
              });
            },
            decoration: InputDecoration(hintText: 'Describe the help needed'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await serviceController.requestHelp(_userLocation!, helpDescription);
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> getHelpRequestsStream() {
    return serviceController.getHelpRequestsStream();
  }

  Future<void> showHelpRequestDialog(Map<String, dynamic> helpRequest) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserOwner = currentUser != null && helpRequest['Owner'] == currentUser.uid;

    final Timestamp timestamp = helpRequest['Date'];
    final DateTime dateTime = timestamp.toDate();
    final String formattedDate = "${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Emergency Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: (${helpRequest['Latitude']}, ${helpRequest['Longitude']})'),
              Text('Date: $formattedDate'),
              Text('Description: ${helpRequest['Description']}'),
            ],
          ),
          actions: <Widget>[
            if (isCurrentUserOwner)
              TextButton(
                onPressed: () async {
                  await serviceController.markHelpAsSolved(helpRequest['id']);
                  Navigator.of(context).pop();
                },
                child: Text('Solve'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchProducts(String workshopId) async {
    List<Map<String, dynamic>> fetchedProducts =
    await serviceController.fetchProducts(workshopId);
    setState(() {
      products = fetchedProducts;
    });
  }

  void centerMapOnWorkshop(Map<String, dynamic> workshop) {
    final lat = double.parse(workshop['Latitude'].toString());
    final lng = double.parse(workshop['Longitude'].toString());
    final LatLng workshopLocation = LatLng(lat, lng);

    if (_mapController != null) {
      _mapController!.move(workshopLocation, 15.0); // 15 is a closer zoom level
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Service",
      rightCustomBarAction: IconButton(
        icon: Icon(Icons.search, color: Colors.white),
        onPressed: () {
          serviceController.onSearch();
        },
      ),
      body: Column(
        children: [
          // Map section
          Expanded(
            flex: 3,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getHelpRequestsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final helpRequests = snapshot.data!;
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _userLocation ?? LatLng(3.1390, 101.6869),
                    zoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    if (_userLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _userLocation!,
                            color: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                            radius: 20000, // 20km radius in meters
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            builder: (ctx) => const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blueAccent,
                              size: 40,
                            ),
                          ),
                        ...helpRequests.map((helpRequest) {
                          return Marker(
                            point: LatLng(
                              helpRequest['Latitude'],
                              helpRequest['Longitude'],
                            ),
                            width: 40,
                            height: 40,
                            builder: (ctx) => GestureDetector(
                              onTap: () => showHelpRequestDialog(helpRequest),
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                        // Workshop markers section
                        ...workshops.map((workshop) {
                          return Marker(
                            point: LatLng(
                              double.parse(workshop['Latitude'].toString()),
                              double.parse(workshop['Longitude'].toString()),
                            ),
                            width: 40,
                            height: 40,
                            builder: (ctx) => GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(workshop['Name']),
                                      content: const Text('Choose an action:'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () async {
                                            if (_userLocation != null) {
                                              final lat = double.parse(workshop['Latitude'].toString());
                                              final lng = double.parse(workshop['Longitude'].toString());
                                              final url = Uri.parse(
                                                'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=$lat,$lng&travelmode=driving',
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                              } else {
                                                print("Could not launch Google Maps");
                                              }
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Get Directions'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.pushNamed(
                                              context,
                                              '/service/detail',
                                              arguments: {
                                                'Name': workshop['Name'],
                                                'workshopId': workshop['id'],
                                              },
                                            );
                                          },
                                          child: const Text('View Details'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Icon(
                                Icons.build_circle,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Buttons section (Inline)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Center on location button with icon
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      if (_userLocation != null && _mapController != null) {
                        _mapController!.move(_userLocation!, 15.0); // Center map on user location
                      }
                    },
                    icon: Icon(Icons.my_location, size: 30, color: Colors.blue),
                  ),
                ),
                // Request help button with icon
                Expanded(
                  child: IconButton(
                    onPressed: requestHelp,
                    icon: Icon(Icons.warning, size: 30, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          // List of workshops
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: workshops.length,
              itemBuilder: (context, index) {
                final workshop = workshops[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(workshop['Name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operating Hours: ${workshop['Operating Hours']}'),
                        if (workshop.containsKey('Distance'))
                          Text('Distance: ${workshop['Distance'].toStringAsFixed(2)} km'),
                      ],
                    ),
                    onTap: () {
                      centerMapOnWorkshop(workshop); // 👈 center the map
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ), currentIndex: 1,
    );
  }
}
