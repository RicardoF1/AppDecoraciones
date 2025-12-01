import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'logistica_orders_screen.dart';
import 'mi_perfil_screen.dart';

class LogisticsBottomNav extends StatefulWidget {
  const LogisticsBottomNav({super.key});

  @override
  State<LogisticsBottomNav> createState() => _LogisticsBottomNavState();
}

class _LogisticsBottomNavState extends State<LogisticsBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    LogisticsOrdersScreen(),
    MiPerfilScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Órdenes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
