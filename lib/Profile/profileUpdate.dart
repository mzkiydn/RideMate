import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridemate/Login/encryption_helper.dart';
import 'package:ridemate/Profile/profileController.dart';
import 'package:ridemate/Template/masterScaffold.dart';

class ProfileUpdate extends StatefulWidget {
  @override
  _ProfileUpdateState createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final ProfileController _controller = ProfileController();
  bool isLoading = false;
  late Map<String, dynamic> currentUserData;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _showSnackBar('No user logged in.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('User').doc(uid).get();

      if (userDoc.exists) {
        currentUserData = userDoc.data()!;
        _usernameController.text = currentUserData['Username'] ?? '';
        _emailController.text = currentUserData['Email'] ?? '';
        _nameController.text = currentUserData['Name'] ?? '';
        _addressController.text = currentUserData['Address'] ?? '';
        _birthDateController.text = currentUserData['Birth Date'] ?? '';
        _phoneNumberController.text = currentUserData['Phone Number'] ?? '';
      } else {
        _showSnackBar('User data not found.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _showSnackBar('Failed to fetch user data.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final uid = currentUser.uid;

    final newUsername = _usernameController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newName = _nameController.text.trim();
    final newAddress = _addressController.text.trim();
    final newBirthDate = _birthDateController.text.trim();
    final newPhoneNumber = _phoneNumberController.text.trim();

    if (newUsername.isEmpty || newName.isEmpty || newBirthDate.isEmpty || newAddress.isEmpty || newPhoneNumber.isEmpty) {
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    setState(() => isLoading = true);

    final result = await _controller.updateUserProfile(
      userId: uid,
      currentPassword: currentPassword,
      newPassword: newPassword,
      currentUsername: currentUserData['Username'] ?? '',
      newUsername: newUsername,
      name: newName,
      address: newAddress,
      birthDate: newBirthDate,
      phoneNumber: newPhoneNumber,
    );

    if (result == null) {
      _showSnackBar('Profile updated successfully.');
      Navigator.pop(context);
    } else {
      _showSnackBar(result);
    }

    setState(() => isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false, bool enabled = true, VoidCallback? toggleVisibility}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: toggleVisibility != null
            ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScaffold(
      customBarTitle: 'Update Profile',
      leftCustomBarAction: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('Username', _usernameController),
                    SizedBox(height: 10),
                    _buildTextField('Full Name', _nameController),
                    SizedBox(height: 10),
                    _buildTextField('Address', _addressController),
                    SizedBox(height: 10),
                    _buildTextField('Birth Date (YYYY-MM-DD)', _birthDateController),
                    SizedBox(height: 10),
                    _buildTextField('Phone Number', _phoneNumberController),
                    SizedBox(height: 20),
                    Divider(),
                    _buildTextField(
                        'Current Password',
                        _currentPasswordController,
                        obscure: !_isCurrentPasswordVisible,
                        toggleVisibility: () {
                          setState(() {
                            _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                          });
                        }
                    ),
                    SizedBox(height: 10),
                    _buildTextField(
                        'New Password (leave blank if no change)',
                        _newPasswordController,
                        obscure: !_isNewPasswordVisible,
                        toggleVisibility: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        }
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[200],
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            )
          ],
        ),
      ),
      currentIndex: 4,
    );
  }
}
