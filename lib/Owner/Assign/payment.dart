import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:ridemate/Owner/Assign/assignController.dart';
import 'package:ridemate/Template/masterScaffold.dart';


class Payment extends StatefulWidget {
  final double amount; // in RM
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
  String userId = '';
  final AssignController _controller = AssignController();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayment();
    });

  }

  Future<void> _startPayment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      Navigator.pop(context, false);
      return;
    }

    try {
      // 1. Request client secret from backend
      final response = await http.post(
        Uri.parse('https://ridemate-backend.onrender.com/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': (widget.amount * 100).toInt(), // in cents
          'applicantId': widget.applicantId,
          'shiftId': widget.shiftId,
        }),
      );

      final data = json.decode(response.body);

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      final clientSecret = data['clientSecret'];

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RideMate',
          style: ThemeMode.light,
        ),
      );

      // 3. Show the payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. On success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful')),
        );
        await _controller.completePayment(widget.workshopId, widget.shiftId, widget.applicantId);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MasterScaffold(
      customBarTitle: "Payment",
      body: Center(child:
      Text("Processing Payment ...")),
      currentIndex: 2,
    );
  }
}
