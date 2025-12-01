import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "pendiente":
        return Colors.orange;
      case "confirmada":
        return Colors.blue;
      case "finalizada":
        return Colors.green;
      case "cancelada":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Debes iniciar sesión para ver el historial")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Reservas"),
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(uid)
            .collection('Historial')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text(
              "No tienes reservas aún.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final fecha =
                  (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
              final estado =
                  (data['estado'] ?? "pendiente").toString().toLowerCase();
              final senal = data['senal'] ?? 0.0;
              final mensaje = data['mensaje'] ?? "";

              final List<dynamic> items = data['items'] ?? [];
              final plantilla = items.isNotEmpty
                  ? items[0]['nombre'] ?? "Plantilla"
                  : "Plantilla";
              final color =
                  items.isNotEmpty ? items[0]['color'] ?? "No definido" : "No definido";

              final fotosLugar = List<String>.from(data['fotosLugar'] ?? []);
              final fotosMontaje = List<String>.from(data['fotosMontaje'] ?? []);

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(
                      width: 6,
                      color: _colorEstado(estado),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  color: Colors.white,
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      "$plantilla - Color: $color",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Fecha
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "${fecha.day}/${fecha.month}/${fecha.year}",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Estado
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Estado:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estado[0].toUpperCase() + estado.substring(1),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _colorEstado(estado),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Señal
                    Row(
                      children: [
                        const Icon(Icons.payments, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Señal pagada: S/ $senal",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (mensaje.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.message_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Mensaje: $mensaje",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // Fotos Lugar
                    if (fotosLugar.isNotEmpty) ...[
                      const Text(
                        "Fotos del lugar:",
                        style:
                            TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fotosLugar.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                fotosLugar[i],
                                width: 100,
                                height: 95,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Fotos Montaje
                    if (fotosMontaje.isNotEmpty) ...[
                      const Text(
                        "Fotos del montaje:",
                        style:
                            TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fotosMontaje.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                fotosMontaje[i],
                                width: 100,
                                height: 95,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
