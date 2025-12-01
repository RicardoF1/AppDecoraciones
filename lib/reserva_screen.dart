import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
//import 'plantillas_screen.dart';
import 'main.dart';

class ReservaScreen extends StatefulWidget {
  final Map<String, dynamic> plantilla;
  final String color;
  final double cotizacion;

  const ReservaScreen({
    super.key,
    required this.plantilla,
    required this.color,
    required this.cotizacion,
  });

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  DateTime? fechaSeleccionada;
  final TextEditingController mensajeController = TextEditingController();
  final TextEditingController senalController = TextEditingController();
  final TextEditingController contactoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();

  String? formaPagoSeleccionada;

  List<File> imagenes = [];
  bool cargando = false;

  final List<String> formasPago = ['Efectivo', 'Transferencia', 'Tarjeta'];

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      setState(() {
        imagenes.add(File(img.path));
      });
    }
  }

  Future<List<String>> subirImagenes() async {
    List<String> urls = [];
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return urls;

    for (var img in imagenes) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child("reservas")
            .child(user.uid)
            .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

        await ref.putFile(img);
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print("Error al subir imagen: $e");
      }
    }
    return urls;
  }

  Future<void> guardarReserva() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
    }

    if (fechaSeleccionada == null ||
        contactoController.text.isEmpty ||
        senalController.text.isEmpty ||
        direccionController.text.isEmpty ||
        formaPagoSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final urls = await subirImagenes();

      await FirebaseFirestore.instance
          .collection("Usuarios")
          .doc(user.uid)
          .collection("Historial")
          .add({
        "fecha": fechaSeleccionada,
        "contacto": contactoController.text,
        "formaPago": formaPagoSeleccionada,
        "senal": double.tryParse(senalController.text) ?? 0,
        "direccion": direccionController.text,
        "fotosLugar": urls,
        "mensaje": mensajeController.text,
        "total": widget.cotizacion,
        "estado": "Pendiente",
        "items": [
          {
            "nombre": widget.plantilla['nombre'],
            "color": widget.color,
            "precio": widget.cotizacion,
            "plantillaId": widget.plantilla['id'],
          }
        ],
        "creadoEl": FieldValue.serverTimestamp(),
        "nombre": user.displayName ?? "Cliente",
        "email": user.email ?? "",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva registrada con éxito")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainApp()),
        (route) => false,
      );
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => cargando = false);
  }

  Widget titulo(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Reserva"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FECHA
                titulo("Fecha del Evento"),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (fecha != null) {
                      setState(() => fechaSeleccionada = fecha);
                    }
                  },
                  child: Text(
                    fechaSeleccionada == null
                        ? "Seleccionar fecha"
                        : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}",
                  ),
                ),

                const SizedBox(height: 18),

                // 2. CONTACTO
                titulo("Número de Contacto"),
                TextField(
                  controller: contactoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: "Ejemplo: 987654321",
                  ),
                ),

                const SizedBox(height: 18),

                // 3. FORMA DE PAGO
                titulo("Forma de Pago"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: formaPagoSeleccionada,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text("Seleccionar forma de pago"),
                    items: formasPago.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f));
                    }).toList(),
                    onChanged: (v) {
                      setState(() => formaPagoSeleccionada = v);
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // 4. MONTO SEÑAL
                titulo("Monto de la Señal"),
                TextField(
                  controller: senalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: "Ejemplo: 50",
                  ),
                ),

                const SizedBox(height: 18),

                // 5. DIRECCIÓN
                titulo("Dirección"),
                TextField(
                  controller: direccionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: "Ejemplo: Av. Principal 123",
                  ),
                ),

                const SizedBox(height: 18),

                // 6. FOTOS
                titulo("Fotos del Lugar"),
                Wrap(
                  children: imagenes
                      .map((img) => Padding(
                            padding: const EdgeInsets.all(6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(img, height: 80),
                            ),
                          ))
                      .toList(),
                ),
                ElevatedButton(
                  onPressed: seleccionarImagen,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent),
                  child: const Text("Subir foto"),
                ),

                const SizedBox(height: 18),

                // 7. MENSAJE
                titulo("Mensaje Adicional"),
                TextField(
                  controller: mensajeController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: "Escribe un mensaje o indicaciones...",
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: cargando ? null : guardarReserva,
                    child: cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Confirmar Reserva"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
