import 'package:flutter/material.dart';
import 'views/screens/home/dashboard_screen.dart';
import 'views/screens/workers/workers_screen.dart';
import 'views/screens/services/services_screen.dart';
import 'views/screens/service_types/service_types_screen.dart';
import 'navigation/bottom_nav_bar.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WorkersScreen(),
    const ServicesScreen(),
    const ServiceTypesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
