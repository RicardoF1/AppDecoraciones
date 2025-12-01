import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editar_perfil_screen.dart';
import 'main.dart'; 

class MiPerfilScreen extends StatefulWidget {
  const MiPerfilScreen({super.key});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  User? user;
  String nombre = "";
  String imagenUrl = "";

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    cargarDatosUsuario();
  }

  void cargarDatosUsuario() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Nombre desde Firebase Auth
      nombre = user!.displayName ?? "";

      // Imagen y otros datos desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user!.uid)
          .get();

      if (!mounted) return; 

      if (doc.exists) {
        setState(() {
          nombre = doc.data()?['nombre'] ?? nombre;
          imagenUrl = doc.data()?['imagen'] ?? "";
        });
      }
    } else {
      if (!mounted) return; 

      setState(() {
        nombre = "";
        imagenUrl = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estaLogueado = user != null;

    return Scaffold(
      //backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: estaLogueado ? _perfilLogueado() : _perfilNoLogueado(),
        ),
      ),
    );
  }

  // Perfil cuando está logueado
  Widget _perfilLogueado() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: imagenUrl.isNotEmpty
              ? NetworkImage(imagenUrl)
              : const NetworkImage(
                  "https://cdn-icons-png.flaticon.com/512/147/147144.png"),
        ),
        const SizedBox(height: 20),
        Text(
          nombre.isNotEmpty ? nombre : "Usuario",
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          user?.email ?? "correo@desconocido.com",
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
              );

              if (!mounted) return; 

              cargarDatosUsuario();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Actualizar datos",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BottomNav()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Cerrar sesión",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // Perfil cuando NO está logueado
  Widget _perfilNoLogueado() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person, size: 80, color: Colors.grey),
        const SizedBox(height: 20),
        const Text(
          "No has iniciado sesión",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Inicia sesión para ver y actualizar tu perfil",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, "/login");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Iniciar Sesión",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
