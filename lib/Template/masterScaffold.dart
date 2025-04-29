import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridemate/Template/baseScaffold.dart';

class MasterScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final String customBarTitle;
  final Widget? rightCustomBarAction;
  final Widget? leftCustomBarAction;

  const MasterScaffold({
    required this.body,
    required this.currentIndex,
    this.customBarTitle = "",
    this.rightCustomBarAction,
    this.leftCustomBarAction,
    Key? key,
  }) : super(key: key);

  @override
  _MasterScaffoldState createState() => _MasterScaffoldState();
}

class _MasterScaffoldState extends State<MasterScaffold> {
  String userType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserType();
  }

  Future<void> _fetchUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fetchedUserType = await _getUserType(user.uid);
      setState(() {
        userType = fetchedUserType;
        isLoading = false;
      });
    } else {
      setState(() {
        userType = 'Motorcyclist';
        isLoading = false;
      });
    }
  }

  Future<String> _getUserType(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('User').doc(uid).get();
      return userDoc.data()?['Type'] ?? 'Motorcyclist';
    } catch (e) {
      return 'Motorcyclist';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BaseScaffold(
      body: widget.body,
      currentIndex: widget.currentIndex,
      customBarTitle: widget.customBarTitle,
      rightCustomBarAction: widget.rightCustomBarAction,
      leftCustomBarAction: widget.leftCustomBarAction,
      userType: userType, // Ensure BaseScaffold gets the userType
    );
  }
}
