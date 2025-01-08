import 'package:flutter/material.dart';
import 'package:new_project/screens/checkpoint_list_screen.dart';
import 'package:new_project/screens/conversation_screen.dart';
import 'package:new_project/screens/home_screen.dart';
import 'package:new_project/screens/profile_screen.dart';
import 'package:new_project/screens/ProductListScreen.dart'; // Import the Product List Screen
import 'checkpoint_map.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 3; // Default to the Map screen
  final PageController _pageController = PageController(initialPage: 3);

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          ProductListScreen(),
          ConversationsScreen(), // Add the Product List Screen here

          CheckpointMap(),
          CheckpointsListPage(),

          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green, // Change the selected icon color
        unselectedItemColor: Colors.grey, // Change the unselected icon color
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), // Add a shopping cart icon
            label: 'Products', // Label for Product List
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages', // Label for Messages
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Checkpoints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
