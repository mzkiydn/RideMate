import 'package:flutter/material.dart';
import 'package:ridemate/Chat/chat.dart';
import 'package:ridemate/Login/login.dart';
import 'package:ridemate/Login/register.dart';
import 'package:ridemate/Feed/feedList.dart';
import 'package:ridemate/Feed/addFeed.dart';
import 'package:ridemate/Mechanic/Shift/detailShift.dart';
import 'package:ridemate/Mechanic/Work/work.dart';
import 'package:ridemate/Mechanic/Work/workDetail.dart';
import 'package:ridemate/Motorcyclist/Market/detailMarket.dart';
import 'package:ridemate/Motorcyclist/Market/market.dart';
import 'package:ridemate/Motorcyclist/Market/marketView.dart';
import 'package:ridemate/Motorcyclist/Service/detailProduct.dart';
import 'package:ridemate/Motorcyclist/Service/service.dart';
import 'package:ridemate/Mechanic/Shift/shift.dart';
import 'package:ridemate/Chat/chatDetail.dart';
import 'package:ridemate/Owner/Assign/assign.dart';
import 'package:ridemate/Owner/Inventory/detailInventory.dart';
import 'package:ridemate/Owner/Inventory/detailShift.dart';
import 'package:ridemate/Owner/Inventory/inventory.dart';
import 'package:ridemate/Owner/Inventory/pastShift.dart';
import 'package:ridemate/Owner/Workshop/workshop.dart';
import 'package:ridemate/Owner/Workshop/workshopDetail.dart';
import 'package:ridemate/Profile/profile.dart';
import 'package:ridemate/Profile/profileUpdate.dart';


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
      case '/inventory/detail':
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
      case '/pastShift/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => PastShift(shiftId: args?['shiftId']),
        );
      case '/market':
        return MaterialPageRoute(builder: (context) => const Market());
      case '/market/detail':
        final args = settings.arguments as Map<dynamic, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => MarketDetail(marketId: args?['marketId']),
        );
      case '/market/view':
        final args = settings.arguments as Map<dynamic, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => MarketView(
            marketId: args?['marketId'],
            isOwner: args != null && args['isOwner'] == true, // Check if 'isOwner' exists and is true
          ),
        );
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
      case '/workDetail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => WorkDetail(shiftId: args?['shiftId']),
        );
      case '/chat':
        return MaterialPageRoute(builder: (context) => Chat());
      case '/chat/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ChatDetail(
            otherUserId: args?['otherUserId'],  // Get the user ID passed in arguments, default to empty string if not available
          ),
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (context) => const Profile(), // No controller parameter needed
        );
      case '/account':
        return MaterialPageRoute(builder: (context) => ProfileUpdate());
      case '/workshop':
        return MaterialPageRoute(builder: (context) => Workshop());
      case '/workshop/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => WorkshopDetail(id: args?['id']),
        );
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
