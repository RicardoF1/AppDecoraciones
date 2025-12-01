import 'package:flutter/material.dart';
import 'gestor_calendar_screen.dart';
//import 'gestor_routes_screen.dart';
import 'mi_perfil_screen.dart';

class GestorBottomNav extends StatefulWidget {
  const GestorBottomNav({super.key});

  @override
  State<GestorBottomNav> createState() => _GestorBottomNavState();
}

class _GestorBottomNavState extends State<GestorBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GestorCalendarScreen(),
    //GestorRoutesScreen(),
    MiPerfilScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
          //BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rutas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
