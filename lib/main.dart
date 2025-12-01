import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pantallas usuario
import 'plantillas_screen.dart';
import 'mi_perfil_screen.dart';
import 'historial_screen.dart';

// Pantalla admin
//import 'admin_home.dart';
//import 'admin_screen.dart';
import 'admin_bottom_nav.dart';
// Pantalla decorador
//import 'decorator_orders_screen.dart';
import 'decorator_bottom_nav.dart';
// Pantallas roles logistica y gestor
import 'logistica_bottom_nav.dart';
import 'gestor_bottom_nav.dart';

import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase antes de ejecutar la app
  await Firebase.initializeApp();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arcos & Globos',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const AuthWrapper(),
      routes: {
        "/login": (_) => const LoginScreen(),
        "/home": (_) => const BottomNav(),
      },
    );
  }
}

// ==================================================
// AuthWrapper mostrar pantalla según rol
// ==================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<User?>( 
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const LoginScreen();
            }

            final uid = userSnapshot.data!.uid;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("Usuarios").doc(uid).get(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snap.hasData || !snap.data!.exists) {
                  // Crear usuario en Firestore si no existe
                  FirebaseFirestore.instance.collection("Usuarios").doc(uid).set({
                    "rol": "user",
                    "nombre": userSnapshot.data!.displayName ?? "",
                    "email": userSnapshot.data!.email ?? "",
                  });
                  return const BottomNav();
                }

                final data = snap.data!.data() as Map<String, dynamic>;
                final rol = data["rol"] ?? "user";

                // Redirección según rol
                if (rol == "admin") {
                  return const AdminBottomNav();
                } else if (rol == "decorador") {
                  return const DecoratorBottomNav();
                } else if (rol == "logistica") {
                  return const LogisticsBottomNav();
                } else if (rol == "gestor") {
                  return const GestorBottomNav();
                } else {
                  return const BottomNav();
                }
              },
            );
          },
        );
      },
    );
  }
}

// ==================================================
// Bottom Navigation para usuarios 
// ==================================================
class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PlantillasScreen(),
    MiPerfilScreen(),
    HistorialScreen(),
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
            icon: Icon(Icons.view_module),
            label: "Plantillas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Mi Perfil",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Historial",
          ),
        ],
      ),
    );
  }
}
