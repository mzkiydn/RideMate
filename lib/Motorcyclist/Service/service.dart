import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Service/detailProduct.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridemate/Template/masterScaffold.dart';
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

  @override
  void initState() {
    super.initState();
    fetchWorkshops();
  }

  Future<void> fetchWorkshops() async {
    List<Map<String, dynamic>> fetchedWorkshops = await serviceController.getWorkshops();
    setState(() {
      workshops = fetchedWorkshops;
    });
  }

  Future<void> fetchProducts(String workshopId) async {
    List<Map<String, dynamic>> fetchedProducts = await serviceController.fetchProducts(workshopId);
    setState(() {
      products = fetchedProducts;
    });
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
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                center: workshops.isNotEmpty
                    ? LatLng(workshops[0]['Latitude'], workshops[0]['Longitude'])
                    : LatLng(37.7749, -122.4194),
                zoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: workshops.map((workshop) {
                    return Marker(
                      point: LatLng(workshop['Latitude'], workshop['Longitude']),
                      width: 40,
                      height: 40,
                      builder: (ctx) => GestureDetector(
                        onTap: () async {
                          await fetchProducts(workshop['id']);
                        },
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: workshops.length,
              itemBuilder: (context, index) {
                final workshop = workshops[index];
                return ListTile(
                  title: Text(workshop['Name'] ?? 'No name'),
                  subtitle: Text(workshop['Operating Hours'] ?? 'N/A'),
                  onTap: () async {
                    await fetchProducts(workshop['id']);
                    Navigator.pushNamed(
                      context,
                      '/service/detail',
                      arguments: {
                        'Name': workshop['Name'] ?? 'Workshop Details',
                        'workshopId': workshop['id'] ?? '',
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      currentIndex: 1,
    );
  }
}
