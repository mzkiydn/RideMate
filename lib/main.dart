import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ridemate/Login/login.dart';
import 'package:ridemate/Owner/Assign/payment.dart';
import 'package:ridemate/Route/routes.dart';
import 'stripe_entrypoint.dart' show stripeMain;

// initialize firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RIw55R0B0Zzi8hZV4ag1Iwk1wKcnVpD4acBDsITfyGgyznwLoeqEvBedMVqWM0sEbGDchiPx1xLyfzLICYxQrfJ00vmhMzCOy'; // Replace with actual key
  await Stripe.instance.applySettings();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RideMate',
        theme: ThemeData(primarySwatch: Colors.blue,),
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: '/login',
      routes: {
        '/': (context) => Login(), // or whatever
        // '/stripe': (context) => Payment(),
      },
    );
  }
}
