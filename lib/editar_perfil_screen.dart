import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final imagenCtrl = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Inicializamos los campos con los datos existentes
    nombreCtrl.text = user?.displayName ?? "";
    
    if (user != null) {
      FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user!.uid)
          .get()
          .then((doc) {
        if (doc.exists) {
          telefonoCtrl.text = doc.data()?['telefono'] ?? "";
          imagenCtrl.text = doc.data()?['imagen'] ?? "";
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualizar Perfil"),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar preview
            CircleAvatar(
              radius: 60,
              backgroundImage: imagenCtrl.text.isNotEmpty
                  ? NetworkImage(imagenCtrl.text)
                  : NetworkImage("https://cdn-icons-png.flaticon.com/512/147/147144.png"),
                  
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre",
                hintText: "Opcional",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Teléfono",
                hintText: "Opcional",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: imagenCtrl,
              decoration: const InputDecoration(
                labelText: "URL de Imagen",
                hintText: "Opcional",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}), // refresca avatar
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: guardarDatos,
                child: const Text(
                  "Guardar cambios",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void guardarDatos() async {
    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();
    final imagen = imagenCtrl.text.trim();

    try {
      // Actualizar displayName en Firebase Auth
      if (nombre.isNotEmpty && user != null) {
        await user!.updateDisplayName(nombre);
      }

      // Actualizar Firestore
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(user!.uid)
            .set({
          'nombre': nombre,
          'telefono': telefono,
          'imagen': imagen,
        }, SetOptions(merge: true));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil actualizado correctamente"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al actualizar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
