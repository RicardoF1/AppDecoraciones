import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DecoratorOrdersScreen extends StatefulWidget {
  const DecoratorOrdersScreen({super.key});

  @override
  State<DecoratorOrdersScreen> createState() => _DecoratorOrdersScreenState();
}

class _DecoratorOrdersScreenState extends State<DecoratorOrdersScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión como decorador'),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collectionGroup('Historial')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes - Decorador'),
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

          final docs = snap.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final estado = (data['estado'] ?? '').toString().toLowerCase();
            final decoradorId = data['decoradorAsignado'] ?? '';
            return ['pendiente', 'asignada', 'finalizada'].contains(estado) &&
                decoradorId == uid;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No hay órdenes asignadas a ti.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final items = List<dynamic>.from(data['items'] ?? []);
              final plantilla =
                  items.isNotEmpty ? items[0]['nombre'] ?? 'Plantilla' : 'Plantilla';
              final color =
                  items.isNotEmpty ? items[0]['color'] ?? 'No definido' : 'No definido';
              final fecha = (data['fecha'] as Timestamp?)?.toDate();
              final clienteNombre = data['nombre'] ?? 'Cliente';
              final estado = (data['estado'] ?? 'pendiente').toString();

              Color estadoColor;
              switch (estado.toLowerCase()) {
                case 'pendiente':
                  estadoColor = Colors.orange;
                  break;
                case 'asignada':
                  estadoColor = const Color.fromARGB(255, 184, 188, 192);
                  break;
                case 'finalizada':
                  estadoColor = Colors.green;
                  break;
                default:
                  estadoColor = Colors.grey;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$plantilla — $color',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (fecha != null)
                        Text(
                          'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      Text(
                        'Cliente: $clienteNombre',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(
                              estado[0].toUpperCase() + estado.substring(1),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: estadoColor,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Abrir'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(orderDoc: doc),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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

// ---------------------------------------------------
// Pantalla detalle de orden 
// ---------------------------------------------------
class OrderDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;

  const OrderDetailScreen({required this.orderDoc, super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<File> fotosMontajeLocal = [];
  bool cargando = false;

  final uid = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic> get data => widget.orderDoc.data() as Map<String, dynamic>;
  DocumentReference get docRef => widget.orderDoc.reference;

  bool get esMiOrden => data['decoradorAsignado'] == uid;

  Future<void> seleccionarFotoMontaje() async {
    if (!esMiOrden) return;

    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => fotosMontajeLocal.add(File(img.path)));
    }
  }

  Future<List<String>> subirFotosMontaje(String clienteUid, String orderId) async {
    List<String> urls = [];
    for (var f in fotosMontajeLocal) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('montajes')
            .child(clienteUid)
            .child(orderId)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await ref.putFile(f);
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('Error subiendo foto montaje: $e');
      }
    }
    return urls;
  }

  Future<void> marcarFinalizada() async {
    if (!esMiOrden) return;

    if (fotosMontajeLocal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sube al menos una foto del montaje')));
      return;
    }

    setState(() => cargando = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      final parent = docRef.parent.parent;
      final clienteUid = parent?.id ?? data['clienteUid'] ?? 'unknown';
      final orderId = docRef.id;

      final urls = await subirFotosMontaje(clienteUid, orderId);

      await docRef.update({
        'fotosMontaje': FieldValue.arrayUnion(urls),
        'estado': 'finalizada',
        'finalizadoEl': FieldValue.serverTimestamp(),
        'decoradorAsignado': user?.uid ?? '',
        'decoradorEmail': user?.email ?? '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Orden marcada como finalizada')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<dynamic>.from(data['items'] ?? []);
    final plantilla = items.isNotEmpty ? items[0]['nombre'] ?? 'Plantilla' : 'Plantilla';
    final color = items.isNotEmpty ? items[0]['color'] ?? 'No definido' : 'No definido';
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final fotosLugar = List<String>.from(data['fotosLugar'] ?? []);
    final fotosMontajeExisting = List<String>.from(data['fotosMontaje'] ?? []);
    final estado = (data['estado'] ?? '').toString();
    final clienteNombre = data['nombre'] ?? 'Cliente';

    Color estadoColor;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        estadoColor = Colors.orange;
        break;
      case 'asignada':
        estadoColor = Color.fromARGB(255, 184, 188, 192);
        break;
      case 'finalizada':
        estadoColor = Colors.green;
        break;
      default:
        estadoColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de orden'), backgroundColor: Colors.pinkAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$plantilla — Color: $color',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (fecha != null)
            Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                style:  TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Cliente: $clienteNombre', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 6),
          Chip(
            label: Text(
              estado[0].toUpperCase() + estado.substring(1),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: estadoColor,
          ),
          const SizedBox(height: 16),
          const Text('Fotos del lugar (cliente):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          fotosLugar.isNotEmpty
              ? SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotosLugar.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(fotosLugar[i],
                            width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                )
              : const Text('No hay fotos del lugar'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Fotos de montaje (existentes):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          fotosMontajeExisting.isNotEmpty
              ? SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotosMontajeExisting.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(fotosMontajeExisting[i],
                            width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                )
              : const Text('Aún no hay fotos de montaje'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Subir fotos del montaje:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fotosMontajeLocal
                .map((f) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(f, width: 100, height: 100, fit: BoxFit.cover),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: esMiOrden ? seleccionarFotoMontaje : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Agregar foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: esMiOrden && !cargando ? marcarFinalizada : null,
              child: cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Marcar como Finalizada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
