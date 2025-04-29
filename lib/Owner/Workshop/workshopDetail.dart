import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ridemate/Owner/Workshop/workshopController.dart';

class WorkshopDetail extends StatefulWidget {
  final String? id; // Optional ID to identify the workshop being edited

  const WorkshopDetail({Key? key, this.id}) : super(key: key);

  @override
  _WorkshopDetailState createState() => _WorkshopDetailState();
}

class _WorkshopDetailState extends State<WorkshopDetail> {
  final WorkshopController workshopController = WorkshopController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController operatingHoursController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();

  late LatLng selectedLocation;
  String appBarTitle = "Add Workshop"; // Default title

  @override
  void initState() {
    super.initState();
    selectedLocation = LatLng(37.7749, -122.4194); // Default location

    if (widget.id != null) {
      _loadWorkshop();
    }
  }

  Future<void> _loadWorkshop() async {
    var workshop = await workshopController.getWorkshopById(widget.id!);
    if (workshop.isNotEmpty) {
      nameController.text = workshop['Name'] ?? '';
      operatingHoursController.text = workshop['Operating Hours'] ?? '';
      contactController.text = workshop['Contact'] ?? '';
      ratingController.text = workshop['Rating']?.toString() ?? '0.0';
      selectedLocation = LatLng(workshop['Latitude'] ?? 37.7749, workshop['Longitude'] ?? -122.4194);

      // Update the AppBar title to the workshop name
      setState(() {
        appBarTitle = workshop['Name'] ?? 'Edit Workshop';
      });
    }
  }

  void _saveWorkshop() {
    if (widget.id != null) {
      // Update existing workshop
      workshopController.updateWorkshop(
        widget.id!,
        nameController.text,
        operatingHoursController.text,
        contactController.text,
        double.parse(ratingController.text),
        selectedLocation.latitude,
        selectedLocation.longitude,
      );
    } else {
      // Add new workshop
      workshopController.addWorkshop(
        nameController.text,
        operatingHoursController.text,
        contactController.text,
        double.parse(ratingController.text),
        selectedLocation.latitude,
        selectedLocation.longitude,
      );
    }
    Navigator.pop(context); // Return to the previous screen (workshop list)
  }

  void _deleteWorkshop() {
    if (widget.id != null) {
      workshopController.deleteWorkshop(widget.id!);
      Navigator.pop(context); // Return to the previous screen (workshop list)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // Set the dynamic title
        actions: [
          if (widget.id != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteWorkshop,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Workshop Name"),
              ),
              TextField(
                controller: operatingHoursController,
                decoration: const InputDecoration(labelText: "Operating Hours"),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact Number"),
              ),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(labelText: "Rating"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Map to select workshop location
              Container(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    center: selectedLocation,
                    zoom: 12.0,
                    onTap: (tapPosition, latLng) {
                      setState(() {
                        selectedLocation = latLng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 40,
                          height: 40,
                          builder: (ctx) => const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkshop,
                child: Text(widget.id == null ? "Add Workshop" : "Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
