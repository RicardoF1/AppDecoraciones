import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestorRoutesScreen extends StatefulWidget {
  const GestorRoutesScreen({super.key});

  @override
  State<GestorRoutesScreen> createState() => _GestorRoutesScreenState();
}

class _GestorRoutesScreenState extends State<GestorRoutesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas de Montajes'), backgroundColor: Colors.pinkAccent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('Historial')
            .where('estado', whereIn: ['Asignada', 'En proceso'])
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No hay rutas asignadas.'));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final items = List<dynamic>.from(data['items'] ?? []);
              final plantilla = items.isNotEmpty ? items[0]['nombre'] ?? 'Plantilla' : 'Plantilla';
              final clienteEmail = data['email'] ?? data['clienteEmail'] ?? 'Cliente';
              final equipo = data['equipoAsignado'] ?? 'Sin asignar';
              final transporte = data['transporteAsignado'] ?? 'Sin asignar';
              final fecha = (data['fecha'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text('$plantilla'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fecha != null) Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                      Text('Cliente: $clienteEmail'),
                      Text('Equipo: $equipo'),
                      Text('Transporte: $transporte'),
                    ],
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
