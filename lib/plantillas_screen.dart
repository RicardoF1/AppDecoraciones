import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plantilla_detalle_screen.dart';

class PlantillasScreen extends StatefulWidget {
  const PlantillasScreen({super.key});

  @override
  State<PlantillasScreen> createState() => _PlantillasScreenState();
}

class _PlantillasScreenState extends State<PlantillasScreen> {
  List<Map<String, dynamic>> plantillas = [];

  @override
  void initState() {
    super.initState();
    obtenerPlantillas();
  }

  Future<void> obtenerPlantillas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plantillas')
          .get();

      setState(() {
        plantillas = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });

    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Decoración'),
        backgroundColor: Colors.pinkAccent,
      ),
      
      body: plantillas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,          
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.68, 
              ),
              itemCount: plantillas.length,
              itemBuilder: (context, index) {
                final plantilla = plantillas[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantillaDetalleScreen(plantilla: plantilla),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15)),
                            child: plantilla['imagen'] != null
                                ? Image.network(
                                    plantilla['imagen'],
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 110,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                          ),

                          const SizedBox(height: 6),

                          // Texto (flexible)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  plantilla['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "S/ ${plantilla['precio'] ?? '0.00'}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.pinkAccent,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plantilla['tipo'] ?? "Sin tipo",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // Botón Ver 
                          SizedBox(
                            width: 100,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlantillaDetalleScreen(plantilla: plantilla),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero, 
                              ),
                              child: const Text(
                                'Ver',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
