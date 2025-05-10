import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Widget? leftCustomBarAction;
  final Widget? rightCustomBarAction;
  final String customBarTitle;
  final String userType;

  const BaseScaffold({
    Key? key,
    required this.body,
    required this.currentIndex,
    required this.userType,
    this.leftCustomBarAction,
    this.rightCustomBarAction,
    this.customBarTitle = " ",
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/feed');
        break;
      case 1:
        if (userType == 'Motorcyclist') {
          Navigator.pushNamed(context, '/service');
        } else if (userType == 'Workshop Owner') {
          Navigator.pushNamed(context, '/inventory');
        } else {
          Navigator.pushNamed(context, '/shift');
        }
        break;
      case 2:
        if (userType == 'Motorcyclist') {
          Navigator.pushNamed(context, '/market');
        } else if (userType == 'Workshop Owner') {
          Navigator.pushNamed(context, '/assign');
        } else {
          Navigator.pushNamed(context, '/work');
        }
        break;
      case 3:
        Navigator.pushNamed(context, '/chat');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ride Mate'),
        backgroundColor: Colors.deepPurple,
        actions: <Widget>[
          IconButton(
            icon: _getUserTypeIcon(),
            onPressed: () => _onIconTapped(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                leftCustomBarAction ?? const SizedBox.shrink(),
                Text(
                  customBarTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                rightCustomBarAction ?? const SizedBox.shrink(),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _getNavigationBarItems(userType),
        currentIndex: currentIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.white70, // Set unselected item color to slightly faded white
        onTap: (index) => _onItemTapped(context, index),
        backgroundColor: Colors.deepPurple, // Set the background color here
        type: BottomNavigationBarType.fixed, // Ensure background color is applied
      ),
    );
  }

  // top right icon
  Icon _getUserTypeIcon() {
    switch (userType) {
      case 'Motorcyclist':
        return const Icon(Icons.shopping_cart); // Cart
      case 'Mechanic':
        return const Icon(Icons.schedule); // Schedule
      case 'Workshop Owner':
        return const Icon(Icons.local_shipping); // Shipping
      default:
        return const Icon(Icons.shopping_cart); // Default to cart
    }
  }

  // top right logic
  void _onIconTapped(BuildContext context) {
    switch (userType) {
      case 'Motorcyclist':
        Navigator.pushNamed(context, '/cart');
        break;
      case 'Mechanic':
        Navigator.pushNamed(context, '/schedule');
        break;
      case 'Workshop Owner':
        Navigator.pushNamed(context, '/shipping');
        break;
      default:
        Navigator.pushNamed(context, '/cart');
    }
  }

  // bottom navbar logic
  List<BottomNavigationBarItem> _getNavigationBarItems(String userType) {
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
      BottomNavigationBarItem(
        icon: userType == 'Motorcyclist'
            ? const Icon(Icons.handyman)
            : userType == 'Workshop Owner'
            ? const Icon(Icons.inventory)
            : const Icon(Icons.calendar_month),
        label: userType == 'Motorcyclist' ? 'Service' : userType == 'Workshop Owner' ? 'Inventory' : 'Shift',
      ),
      BottomNavigationBarItem(
        icon: userType == 'Motorcyclist'
            ? const Icon(Icons.shopping_bag_outlined)
            : userType == 'Workshop Owner'
            ? const Icon(Icons.task)
            : const Icon(Icons.work),
        label: userType == 'Motorcyclist' ? 'Market' : userType == 'Workshop Owner' ? 'Assign' : 'Work',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
      const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
    ];
  }
}
