import 'package:cafetarium/screens/add_post_screen.dart';
import 'package:cafetarium/screens/favorite_screen.dart';
import 'package:cafetarium/screens/home_screen.dart';
import 'package:cafetarium/screens/map_screen.dart';
import 'package:cafetarium/screens/profile_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final String role;

  const MainScreen({
    super.key,
    required this.role,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  static const Color primaryBrown = Color(0xff6f4e37);

  bool get isOwner => widget.role.toLowerCase() == 'owner';

  List<Widget> get pages {
    if (isOwner) {
      return const [
        HomeScreen(),
        MapScreen(),
        AddPostScreen(),
        FavoriteScreen(),
        ProfileScreen(),
      ];
    }

    return const [
      HomeScreen(),
      MapScreen(),
      FavoriteScreen(),
      ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> get navItems {
    if (isOwner) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded, size: 28),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_rounded, size: 28),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_rounded, size: 30),
          label: 'Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_rounded, size: 28),
          label: 'Favorite',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded, size: 28),
          label: 'Profile',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded, size: 28),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on_rounded, size: 28),
        label: 'Map',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_rounded, size: 28),
        label: 'Favorite',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded, size: 28),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xff6f4e37), Color(0xff8b5e3c)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: navItems,
          ),
        ),
      ),
    );
  }
}