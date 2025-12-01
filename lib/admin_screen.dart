import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPlantillasScreen extends StatelessWidget {
  const AdminPlantillasScreen({super.key});

  Future<void> eliminarPlantilla(String id) async {
    try {
      await FirebaseFirestore.instance.collection('plantillas').doc(id).delete();
    } catch (e) {
      print("Error eliminando plantilla: $e");
    }
  }

  void mostrarFormularioPlantilla(BuildContext context, [DocumentSnapshot? doc]) {
    final nombreController = TextEditingController(text: doc?['nombre'] ?? '');
    final precioController =
        TextEditingController(text: doc?['precio']?.toString() ?? '');
    final imagenController = TextEditingController(text: doc?['imagen'] ?? '');

    String tipo = doc?['tipo'] ?? 'Columna';
    final tiposOpciones = ['Columna', 'Arco', 'Centro'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(doc == null ? 'Agregar Plantilla' : 'Editar Plantilla'),
            backgroundColor: Colors.pinkAccent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: tiposOpciones
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) tipo = v;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: precioController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      prefixText: 'S/ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imagenController,
                    decoration: InputDecoration(
                      labelText: 'URL Imagen',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final nombre = nombreController.text.trim();
                          final precio =
                              double.tryParse(precioController.text.trim()) ?? 0;
                          final imagen = imagenController.text.trim();

                          if (nombre.isEmpty || tipo.isEmpty || precio <= 0) return;

                          final data = {
                            'nombre': nombre,
                            'tipo': tipo,
                            'precio': precio,
                            'imagen': imagen,
                          };

                          try {
                            if (doc == null) {
                              await FirebaseFirestore.instance.collection('plantillas').add(data);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('plantillas')
                                  .doc(doc.id)
                                  .update(data);
                            }
                            Navigator.pop(context);
                          } catch (e) {
                            print("Error guardando plantilla: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Guardar', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Plantillas'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plantillas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay plantillas registradas.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                shadowColor: Colors.pinkAccent.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: data['imagen'] != null && data['imagen'] != ''
                        ? Image.network(
                            data['imagen'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  title: Text(
                    data['nombre'] ?? 'Nombre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Tipo: ${data['tipo'] ?? '-'} | Precio: S/ ${data['precio'] ?? '-'}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => mostrarFormularioPlantilla(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => eliminarPlantilla(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarFormularioPlantilla(context),
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
