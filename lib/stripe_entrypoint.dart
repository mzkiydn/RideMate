import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

@pragma('vm:entry-point')
void stripeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RIw55R0B0Zzi8hZV4ag1Iwk1wKcnVpD4acBDsITfyGgyznwLoeqEvBedMVqWM0sEbGDchiPx1xLyfzLICYxQrfJ00vmhMzCOy'; // Replace with actual key
  Stripe.instance.applySettings().then((_) {
    runApp(StripeApp());
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RIw55R0B0Zzi8hZV4ag1Iwk1wKcnVpD4acBDsITfyGgyznwLoeqEvBedMVqWM0sEbGDchiPx1xLyfzLICYxQrfJ00vmhMzCOy'; // Replace with actual key
  await Stripe.instance.applySettings();
  runApp(StripeApp());
}

class StripeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StripePaymentPage(),
    );
  }
}

class StripePaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stripe")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            payMechanic(
              context: context,
              amount: 9.99,
              applicantId: "abc",
              shiftId: "xyz",
              workshopId: "123",
            );
          },
          child: Text("Pay Now"),
        ),
      ),
    );
  }
}

Future<void> payMechanic({
  required BuildContext context,
  required double amount,
  required String applicantId,
  required String shiftId,
  required String workshopId,
}) async {
  final Dio dio = Dio();

  try {
    final int centAmount = (amount * 100).toInt();

    final response = await dio.post(
      'http://10.0.2.2:5000/create-payment-intent',
      data: {
        'amount': centAmount,
        'applicantId': applicantId,
        'shiftId': shiftId,
        'workshopId': workshopId,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final data = response.data;
    final clientSecret = data['clientSecret'];

    if (clientSecret == null) {
      throw Exception('Missing client secret from backend');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ridemate',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment successful')),
    );
  } catch (e) {
    print('Error during payment: $e');

    if (e is StripeException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe error: ${e.error.localizedMessage}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    }
  }
}
