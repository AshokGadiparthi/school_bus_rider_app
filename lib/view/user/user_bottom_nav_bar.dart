
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:riders_app/view/user/home/home_screen.dart';
import 'package:riders_app/view/user/menu/menu_screen.dart';
import 'package:riders_app/view/user/profile/profile_screen.dart';
import 'package:riders_app/view/user/schedule/schedule_screen.dart';
import '../../../utils/colors.dart';

class UserBottomNavBar extends StatefulWidget {
  static const String idScreen = "userbottomnavbar";
  const UserBottomNavBar({super.key});

  @override
  State<UserBottomNavBar> createState() => _UserBottomNavBarState();
}

class _UserBottomNavBarState extends State<UserBottomNavBar> {

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print('Tapped index is: ${_selectedIndex}');
    });
  }

  List<PersistentTabConfig> _navBarsItems() {
    return [
      PersistentTabConfig(
        screen: const HomeScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.home),
          title: "Home",
          activeForegroundColor: teal
        ),
      ),
      PersistentTabConfig(
        screen: const ScheduleScreen(),
        item: ItemConfig(
            icon: const Icon(Icons.schedule_outlined),
            title: "Schedules",
            activeForegroundColor: teal
        ),
      ),
      PersistentTabConfig(
        screen: const ProfileScreen(),
        item: ItemConfig(
            icon: const Icon(Icons.message),
            title: "Message",
            activeForegroundColor: teal
        ),
      ),

      PersistentTabConfig(
        screen: const MenuScreen(),
        item: ItemConfig(
            icon: const Icon(Icons.menu),
            title: "Menu",
            activeForegroundColor: teal
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => PersistentTabView(
    tabs: _navBarsItems(),
    onTabChanged: _onItemTapped,
    navBarBuilder: (navBarConfig) => Style1BottomNavBar(
      navBarConfig: navBarConfig,
    ),
  );
}
