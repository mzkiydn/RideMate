import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ridemate/Route/routes.dart';

// initialize firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RideMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
                onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: '/login',
    );
  }
}
