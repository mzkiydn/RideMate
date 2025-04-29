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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Service details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['Name'] ?? 'No name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Price: RM ${service['Price'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
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
