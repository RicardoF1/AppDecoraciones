import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logistica_assign_screen.dart';

class LogisticsOrdersScreen extends StatelessWidget {
  const LogisticsOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collectionGroup('Historial')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Órdenes - Logística"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No hay órdenes registradas.'));
          }

          // Filtrar órdenes no asignadas y ordenar por fecha (ascendente)
          final docs = snap.data!.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['equipoAsignado'] == null && data['transporteAsignado'] == null;
              })
              .toList()
            ..sort((a, b) {
              final fechaA = (a.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
              final fechaB = (b.data() as Map<String, dynamic>)['fecha'] as Timestamp?;
              if (fechaA == null && fechaB == null) return 0;
              if (fechaA == null) return 1;
              if (fechaB == null) return -1;
              return fechaA.compareTo(fechaB);
            });

          if (docs.isEmpty) {
            return const Center(child: Text('No hay órdenes pendientes de asignación.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final items = List<dynamic>.from(data['items'] ?? []);
              final plantilla = items.isNotEmpty ? items[0]['nombre'] ?? 'Plantilla' : 'Plantilla';
              final fecha = (data['fecha'] as Timestamp?)?.toDate();
              final clienteNombre = data['nombre'] ?? 'Cliente';
              final estado = (data['estado'] ?? 'pendiente').toString();

              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shadowColor: Colors.pinkAccent.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(
                      '$plantilla',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Cliente: $clienteNombre', style: const TextStyle(fontSize: 14)),
                        if (fecha != null)
                          Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                              style: const TextStyle(fontSize: 14)),
                        Text('Estado: ${estado[0].toUpperCase()}${estado.substring(1)}',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LogisticsAssignScreen(orderDoc: doc),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Asignar"),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
