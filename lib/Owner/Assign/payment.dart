import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Payment extends StatefulWidget {
  final double amount; // RM
  final String applicantId;
  final String shiftId;
  final String workshopId;

  const Payment({
    Key? key,
    required this.amount,
    required this.applicantId,
    required this.shiftId,
    required this.workshopId,
  }) : super(key: key);

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  static const platform = MethodChannel('com.ridemate.stripe/payment');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid ?? '';
    _launchStripeActivity(); // Automatically launch payment
  }

  Future<void> _launchStripeActivity() async {
    try {
      await platform.invokeMethod("startStripePayment", {
        "amount": (widget.amount * 100).toInt(), // Stripe expects cents
        "applicantId": widget.applicantId,
        "shiftId": widget.shiftId,
        "ownerId": userId,
      });

      // If success, return to previous page
      Navigator.pop(context, true);
    } on PlatformException catch (e) {
      print("Failed to launch StripeActivity: ${e.message}");
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
