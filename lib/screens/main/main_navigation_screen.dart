import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'store_screen.dart';
import 'cart_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottom_navigation_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _wishlistRefreshKey = 0;
  int _homeRefreshKey = 0;
  int _storeRefreshKey = 0;
  int _cartRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: ValueKey(_homeRefreshKey)),
          WishlistScreen(key: ValueKey(_wishlistRefreshKey)),
          StoreScreen(key: ValueKey(_storeRefreshKey)),
          CartScreen(key: ValueKey(_cartRefreshKey)),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            
            if (index == 0) {
              _homeRefreshKey++;
            }
            
            if (index == 1) {
              _wishlistRefreshKey++;
            }
            
            if (index == 2) {
              _storeRefreshKey++;
            }
            
            if (index == 3) {
              _cartRefreshKey++;
            }
          });
        },
      ),
    );
  }
}

