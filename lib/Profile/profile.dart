import 'package:flutter/material.dart';
import 'package:ridemate/Profile/profileController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

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
    setState(() {});
  }

  Widget _buildOptionTile(BuildContext context, String title, String routeName) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, routeName),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
        ),
        trailing: const Icon(Icons.logout, color: Colors.red),
        onTap: () {
          _controller.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MasterScaffold(
      customBarTitle: "Profle",
      body: Column(
        children: [
          // Profile Header Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, size: 48, color: Colors.blueGrey),
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
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // location toggle
                    // Column(
                    //   children: [
                    //     const Text("Location"),
                    //     Switch(
                    //       value: _controller.isLocationEnabled,
                    //       onChanged: (value) {
                    //         setState(() {
                    //           _controller.toggleLocation(value);
                    //         });
                    //       },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              children: [
                _buildOptionTile(context, "Account", '/account'),
                // _buildOptionTile(context, "Motorcycle", '/motorcycle'),
                if (user.userType == "Workshop Owner")
                  _buildOptionTile(context, "Workshop", '/workshop'),
                // _buildOptionTile(context, "Notification", '/notification'),
                // _buildOptionTile(context, "History", '/history'),
                // _buildOptionTile(context, "Help & Documentation", '/help'),
                _buildLogoutTile(context),
              ],
            ),
          ),
        ],
      ), currentIndex: 4,
    );
  }
}
