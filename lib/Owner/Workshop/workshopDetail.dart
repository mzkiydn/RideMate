import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ridemate/Owner/Workshop/workshopController.dart';
import 'package:ridemate/Template/masterScaffold.dart';
import 'package:geolocator/geolocator.dart';


class WorkshopDetail extends StatefulWidget {
  final String? id;

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

  LatLng? selectedLocation;
  String appBarTitle = "Add Workshop";

  @override
  void initState() {
    super.initState();
    _initializeWorkshopWithLocation();

  }

  Future<void> _initializeWorkshopWithLocation() async {
    if (widget.id != null) {
      await _loadWorkshop(); // For edit mode
    } else {
      // For add mode, get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          print("Location permission denied.");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
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

      setState(() {
        appBarTitle = workshop['Name'] ?? 'Edit Workshop';
      });
    }
  }

  void _saveWorkshop() {
    final name = nameController.text.trim();
    final operatingHours = operatingHoursController.text.trim();
    final contact = contactController.text.trim();

    if (name.isEmpty || operatingHours.isEmpty || contact.isEmpty || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and select a location.')),
      );
      return;
    }

    if (widget.id != null) {
      workshopController.updateWorkshop(widget.id!, name, operatingHours, contact, selectedLocation!.latitude, selectedLocation!.longitude);
    } else {
      workshopController.addWorkshop(name, operatingHours, contact, selectedLocation!.latitude, selectedLocation!.longitude);
    }

    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this workshop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteWorkshop();
    }
  }

  void _deleteWorkshop() {
    if (widget.id != null) {
      workshopController.deleteWorkshop(widget.id!);
      Navigator.pop(context);
    }
  }

  Widget buildInputField(String label, TextEditingController controller, {TextInputType? type}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: appBarTitle,
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      currentIndex: 4,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInputField("Workshop Name", nameController),
                  const SizedBox(height: 16),
                  buildInputField("Operating Hours", operatingHoursController),
                  const SizedBox(height: 16),
                  buildInputField("Contact Number", contactController, type: TextInputType.phone),
                  const SizedBox(height: 24),
                  const Text("Workshop Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        center: selectedLocation ?? LatLng(3.1390, 101.6869), // Fallback center
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
                              point: selectedLocation!,
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
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: FloatingActionButton(
                            onPressed: () async {
                              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                              setState(() {
                                selectedLocation = LatLng(position.latitude, position.longitude);
                              });
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(widget.id == null ? Icons.add : Icons.save),
                    label: Text(widget.id == null ? "Add Workshop" : "Save Changes"),
                    onPressed: _saveWorkshop,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (widget.id != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete Workshop"),
                      onPressed: _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
