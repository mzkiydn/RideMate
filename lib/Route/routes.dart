import 'package:flutter/material.dart';
import 'package:ridemate/Login/login.dart';
import 'package:ridemate/Login/register.dart';
import 'package:ridemate/Feed/feedList.dart';
import 'package:ridemate/Feed/addFeed.dart';
import 'package:ridemate/Mechanic/Shift/detailShift.dart';
import 'package:ridemate/Mechanic/Work/work.dart';
import 'package:ridemate/Motorcyclist/Service/detailProduct.dart';
import 'package:ridemate/Motorcyclist/Service/service.dart';
import 'package:ridemate/Motorcyclist/Progress/progress.dart';
import 'package:ridemate/Mechanic/Shift/shift.dart';
// import 'package:ridemate/Mechanic/Work/work.dart';
import 'package:ridemate/Chat/personal.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Owner/Assign/assign.dart';
import 'package:ridemate/Owner/Inventory/detailInventory.dart';
import 'package:ridemate/Owner/Inventory/detailShift.dart';
import 'package:ridemate/Owner/Inventory/inventory.dart';
import 'package:ridemate/Owner/Workshop/workshop.dart';
import 'package:ridemate/Owner/Workshop/workshopDetail.dart';
import 'package:ridemate/Profile/profile.dart';
import 'package:ridemate/Profile/profileController.dart';
import 'package:ridemate/Owner/Inventory/inventory.dart';

import '../Mechanic/Shift/shift.dart';
import 'package:ridemate/Motorcyclist/Cart/cart.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => Login());
      case '/register':
        return MaterialPageRoute(builder: (context) => Register());
      case '/feed':
        return MaterialPageRoute(builder: (context) => const FeedList());
      case '/addFeed':
        return MaterialPageRoute(builder: (context) => const AddFeed());
      case '/service':
        return MaterialPageRoute(builder: (context) => Service());
      case '/service/detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => DetailProduct(
            customBarTitle: args['Name'],
            workshopId: args['workshopId'] ?? '',
          ),
        );
      case '/inventory':
        return MaterialPageRoute(builder: (context) => const Inventory());
      case '/inventory/detail': // Add this route for DetailInventory
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => DetailInventory(
            itemId: args?['itemId'], // Passing itemId for editing
            isProduct: args?['isProduct'], // Passing isProduct to differentiate
          ),
        );
      case '/shift/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => DetailShift(shiftId: args?['shiftId']),
        );
      case '/progress':
        return MaterialPageRoute(builder: (context) => const Progress());
      case '/shift':
        return MaterialPageRoute(builder: (context) => const Shift());
      case '/shiftDetail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ShiftDetail(
            shiftId: args?['shiftId'], // Only passing shiftId
          ),
        );
      case '/assign':
        return MaterialPageRoute(builder: (context) => Assign());
    case '/work':
        return MaterialPageRoute(builder: (context) => Work());
    case '/cart':
        return MaterialPageRoute(builder: (context) => Cart());
      case '/chat/personal':
        return MaterialPageRoute(builder: (context) => const Personal());
      case '/profile':
        return MaterialPageRoute(
          builder: (context) => const Profile(), // No controller parameter needed
        );
    // case '/inventory':
      //   return MaterialPageRoute(builder: (context) => const Inventory());
      case '/chat/personal/name':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ChatDetail(name: args['name']),
        );

        // Example dynamic navigation based on option name
      case '/account':
        return MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Account'));
      case '/motorcycle':
        return MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Motorcycle'));
      case '/workshop':
        return MaterialPageRoute(builder: (context) => Workshop());
      case '/workshop/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => WorkshopDetail(id: args?['id']),
        );
        // case '/notification':
      //   return MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Notification'));
      // case '/history':
      //   return MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'History'));
      // case '/help':
      //   return MaterialPageRoute(builder: (context) => const PlaceholderPage(title: 'Help & Documentation'));

      default:
        return MaterialPageRoute(builder: (context) => Login());
    }
  }
}

// A simple placeholder page for missing routes
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("This is the $title page")),
    );
  }
}
