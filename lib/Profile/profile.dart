import 'package:flutter/material.dart';
import 'package:ridemate/Profile/profileController.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    await _controller.fetchUserData();
    setState(() {}); // Rebuild the widget after fetching data
  }

  Widget _buildOptionTile(BuildContext context, String title, String routeName) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(context, routeName); // Navigate to the route
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      title: const Text("Logout"),
      trailing: const Icon(Icons.logout, color: Colors.red),
      onTap: () {
        _controller.logout();
        Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Show loading indicator while fetching user
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.userType ?? "None",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text("Location"),
                    Switch(
                      value: _controller.isLocationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _controller.toggleLocation(value);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Options List
          Expanded(
            child: ListView(
              children: [
                _buildOptionTile(context, "Account", '/account'),
                _buildOptionTile(context, "Motorcycle", '/motorcycle'),
                _buildOptionTile(context, "Workshop", '/workshop'), // Ensure this route corresponds to the Workshop screen
                _buildOptionTile(context, "Notification", '/notification'),
                _buildOptionTile(context, "History", '/history'),
                _buildOptionTile(context, "Help & Documentation", '/help'),
                _buildLogoutTile(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
