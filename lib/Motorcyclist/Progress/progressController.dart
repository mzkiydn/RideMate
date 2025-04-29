import 'package:flutter/material.dart';

class ProgressController extends ChangeNotifier {
  // Example data to be used in the progress page
  Map<String, dynamic> workshopInfo = {
    'name': '123 Workshop St, Cityville',
    'contact': '+1234567890',
    'address': '123 Workshop St, Cityville',
    'logo': 'assets/workshop_logo.png',
    'rating': 4.0,
  };

  Map<String, dynamic> receiptInfo = {
    'receiptNumber': '123456',
    'dateTime': '2023-10-01, 10:30 AM',
    'mechanicName': 'John Doe',
    'mechanicContact': '+9876543210',
    'service': 'Oil Change (Qty: 1)',
    'product': 'Engine Oil (Qty: 2)',
    'paymentStatus': 'Paid',
  };

  // Method to simulate verifying the completion
  void verifyCompletion() {
    // Logic for verifying completion, e.g., updating the status
    print("Verification button pressed");

    // Notify listeners if the status changes
    notifyListeners();
  }
}
