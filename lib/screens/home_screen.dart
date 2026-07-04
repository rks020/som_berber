import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'customer_list_screen.dart';
import 'barbers_screen.dart';
import 'services_screen.dart';
import 'appointment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomerListScreen(),
    AppointmentScreen(),
    BarbersScreen(),
    ServicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Müşteriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Randevu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural_outlined),
            activeIcon: Icon(Icons.face_retouching_natural),
            label: 'Berberler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dry_cleaning_outlined),
            activeIcon: Icon(Icons.dry_cleaning),
            label: 'Fiyatlar',
          ),
        ],
      ),
    );
  }
}
