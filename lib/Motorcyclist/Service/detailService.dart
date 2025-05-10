import 'package:flutter/material.dart';
import 'package:ridemate/Motorcyclist/Service/serviceController.dart';

class DetailService extends StatefulWidget {
  final String customBarTitle;
  final String workshopId;

  const DetailService({super.key, required this.customBarTitle, required this.workshopId});

  @override
  _DetailServiceState createState() => _DetailServiceState();
}

class _DetailServiceState extends State<DetailService> {
  final ServiceController serviceController = ServiceController();
  List<Map<String, dynamic>> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    List<Map<String, dynamic>> fetchedWorkshops = await serviceController.getWorkshops();
    Map<String, dynamic>? selectedWorkshop = fetchedWorkshops.firstWhere(
          (workshop) => workshop['Name'] == widget.customBarTitle,
      orElse: () => {},
    );

    if (selectedWorkshop.isNotEmpty) {
      List<Map<String, dynamic>> fetchedServices =
      await serviceController.fetchServices(selectedWorkshop['id']);
      setState(() {
        services = fetchedServices;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : services.isEmpty
        ? const Center(child: Text("No services available"))
        : ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name (Title)
                  Text(
                    service['Name'] ?? 'No name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description and Price inline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['Description'] ?? 'No description',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RM ${service['Price']?.toStringAsFixed(2) ?? 'N/A'}",
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
