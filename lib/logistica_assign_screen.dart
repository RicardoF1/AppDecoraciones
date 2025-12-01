import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

class LogisticsAssignScreen extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;

  const LogisticsAssignScreen({required this.orderDoc, super.key});

  @override
  State<LogisticsAssignScreen> createState() => _LogisticsAssignScreenState();
}

class _LogisticsAssignScreenState extends State<LogisticsAssignScreen> {
  String? selectedDecorador;
  String? selectedTransporte;
  bool cargando = false;

  // Decoradores disponibles
  final Map<String, String> decoradores = {
    'GtMUoTFQ5fOJUVwdGJXVzpfQBj12': 'Decorador 1',
    'o4ws72KheQa2aOWZsSrX8HmpMSD3': 'Decorador 2',
  };

  final List<String> transportesDisponibles = ['Auto', 'Camión', 'Moto'];

  Map<String, dynamic> get data => widget.orderDoc.data() as Map<String, dynamic>;
  DocumentReference get docRef => widget.orderDoc.reference;

  Future<void> asignar() async {
    if (selectedDecorador == null || selectedTransporte == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona decorador y transporte')),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      await docRef.update({
        'decoradorAsignado': selectedDecorador,
        'transporteAsignado': selectedTransporte,
        'estado': 'asignada',
        'logisticaAsignadoEl': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asignación registrada')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<dynamic>.from(data['items'] ?? []);
    final plantilla = items.isNotEmpty ? items[0]['nombre'] ?? 'Plantilla' : 'Plantilla';
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final clienteNombre = data['nombre'] ?? 'Cliente';
    final mensaje = data['mensaje'] ?? 'Sin mensaje';
    final fotosLugar = List<String>.from(data['fotosLugar'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar decorador y transporte'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la orden
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orden: $plantilla', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Cliente: $clienteNombre', style: const TextStyle(fontSize: 16)),
                    if (fecha != null) Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    const Text('Mensaje del cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(mensaje, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    if (fotosLugar.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fotos del lugar:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: fotosLugar.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(fotosLugar[index], width: 100, height: 100, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Selección de decorador
            const Text('Selecciona decorador:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedDecorador,
              hint: const Text('Elige un decorador'),
              items: decoradores.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => selectedDecorador = v),
            ),

            const SizedBox(height: 20),
            // Selección de transporte
            const Text('Selecciona transporte:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedTransporte,
              hint: const Text('Elige un transporte'),
              items: transportesDisponibles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => selectedTransporte = v),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: cargando ? null : asignar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar Asignación', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
