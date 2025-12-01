import 'package:flutter/material.dart';
import 'decorator_orders_screen.dart';
import 'mi_perfil_screen.dart'; 

class DecoratorBottomNav extends StatefulWidget {
  const DecoratorBottomNav({super.key});

  @override
  State<DecoratorBottomNav> createState() => _DecoratorBottomNavState();
}

class _DecoratorBottomNavState extends State<DecoratorBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DecoratorOrdersScreen(),
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
        onTap: _onItemTapped,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Órdenes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
