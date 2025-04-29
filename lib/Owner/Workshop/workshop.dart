import 'package:flutter/material.dart';
import 'package:ridemate/Owner/Workshop/workshopController.dart';
import 'package:ridemate/Template/baseScaffold.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class Workshop extends StatefulWidget {
  @override
  _WorkshopState createState() => _WorkshopState();
}

class _WorkshopState extends State<Workshop> {
  final WorkshopController workshopController = WorkshopController();
  final Map<int, bool> expandedWorkshops = {}; // Track expanded states by index

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: "Workshop",
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/profile');
        },
      ),
      rightCustomBarAction: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/workshop/detail');
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: workshopController.getWorkshops(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No workshops available.'));
          }

          final workshops = snapshot.data!;

          return ListView.builder(
            itemCount: workshops.length,
            itemBuilder: (context, index) {
              final workshop = workshops[index];
              final isExpanded = expandedWorkshops[index] ?? false;

              return Column(
                children: [
                  ListTile(
                    title: Text(workshop['Name'] ?? 'No name'),
                    subtitle: Text(workshop['Operating Hours'] ?? 'No operating hours'),
                    trailing: IconButton(
                      icon: Icon(
                        isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      ),
                      onPressed: () {
                        setState(() {
                          expandedWorkshops[index] = !isExpanded; // Toggle expansion
                        });
                      },
                    ),
                  ),
                  if (isExpanded) _buildExpandedWorkshop(workshop, context),
                ],
              );
            },
          );
        },
      ),

      // Bottom navigation bar
      currentIndex: 4,
    );
  }

  Widget _buildExpandedWorkshop(Map<String, dynamic> workshop, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Placeholder for workshop logo
                  Container(
                    height: 50,
                    width: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workshop['Name'] ?? 'No name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/workshop/detail',
                        arguments: {'id': workshop['id']},
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Operating Hours: ${workshop['Operating Hours'] ?? 'Unavailable'}',
              ),
              const SizedBox(height: 8),
              Text(
                'Contact: ${workshop['Contact'] ?? 'Unavailable'}',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(workshop['Rating']?.toString() ?? 'No rating'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
