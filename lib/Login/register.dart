import 'package:flutter/material.dart';
import 'package:ridemate/Login/registerController.dart';

class Register extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<Register> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _userType = 'Motorcyclist';
  final List<String> userTypes = ['Motorcyclist', 'Mechanic', 'Workshop Owner'];
  bool isLoading = false;
  final RegisterController controller = RegisterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  _buildTextField('Username', _usernameController),
                  const SizedBox(height: 10),
                  _buildTextField('Email', _emailController),
                  const SizedBox(height: 10),
                  _buildTextField('Password', _passwordController, obscure: true),
                  const SizedBox(height: 10),
                  _buildTextField('Full Name', _nameController),
                  const SizedBox(height: 10),
                  _buildTextField('Address', _addressController),
                  const SizedBox(height: 10),
                  _buildTextField('Birth Date (YYYY-MM-DD)', _birthDateController),
                  const SizedBox(height: 10),
                  _buildTextField('Phone Number', _phoneNumberController),
                  const SizedBox(height: 10),
                  // User Type Dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _userType,
                        onChanged: (String? newValue) {
                          setState(() {
                            _userType = newValue!;
                          });
                        },
                        items: userTypes.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                          setState(() {
                            isLoading = true;
                          });

                          String? result = await controller.registerUser(
                            username: _usernameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            name: _nameController.text,
                            phoneNumber: _phoneNumberController.text,
                            address: _addressController.text,
                            birthDate: _birthDateController.text,
                            userType: _userType,
                          );

                          setState(() {
                            isLoading = false;
                          });

                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Registration successful')));
                            Navigator.pushReplacementNamed(context, '/');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)));
                          }
                        },
                        child: isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text('Register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[200],
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _usernameController.clear();
                          _emailController.clear();
                          _passwordController.clear();
                          _nameController.clear();
                          _addressController.clear();
                          _birthDateController.clear();
                          _phoneNumberController.clear();
                          setState(() {
                            _userType = 'Motorcyclist';
                          });
                        },
                        child: Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
      ),
    );
  }
}
