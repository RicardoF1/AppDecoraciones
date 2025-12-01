import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class GestorCalendarScreen extends StatefulWidget {
  const GestorCalendarScreen({super.key});

  @override
  State<GestorCalendarScreen> createState() => _GestorCalendarScreenState();
}

class _GestorCalendarScreenState extends State<GestorCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('Historial')
        .get(); 

    final eventsTemp = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;

      final fechaKey = DateTime(fecha.year, fecha.month, fecha.day);

      eventsTemp.putIfAbsent(fechaKey, () => []).add({
        'doc': doc,
        'cliente': data['nombre'] ?? data['email'] ?? data['clienteEmail'] ?? 'Cliente',
        'estado': (data['estado'] ?? 'pendiente').toString(),
        'plantilla': (data['items'] as List<dynamic>?)?.first['nombre'] ?? 'Plantilla',
        'mensaje': data['mensaje'] ?? '',
        'fotosLugar': List<String>.from(data['fotosLugar'] ?? []),
        'fotosMontaje': List<String>.from(data['fotosMontaje'] ?? []),
        'fecha': fecha,
      });
    }

    setState(() {
      _events = eventsTemp;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final list = _events[key] ?? [];
    // Ordenar por fecha de reserva dentro del día
    list.sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));
    return list;
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'asignada':
        return Colors.blue;
      case 'finalizada':
        return Colors.green;
      case 'en proceso':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Montajes'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.pinkAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecciona un día para ver montajes'))
                : _getEventsForDay(_selectedDay!).isEmpty
                    ? const Center(child: Text('No hay montajes para este día'))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: _getEventsForDay(_selectedDay!).map((e) {
                          final estado = e['estado'] ?? 'pendiente';
                          final cliente = e['cliente'] ?? 'Cliente';
                          final plantilla = e['plantilla'] ?? 'Plantilla';
                          final mensaje = e['mensaje'] ?? '';
                          final fotosLugar = List<String>.from(e['fotosLugar'] ?? []);
                          final fotosMontaje = List<String>.from(e['fotosMontaje'] ?? []);
                          final fecha = e['fecha'] as DateTime?;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: _estadoColor(estado).withOpacity(0.1),
                              border: Border.all(color: _estadoColor(estado), width: 1.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                '$plantilla - $cliente',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: fecha != null
                                  ? Text(
                                      'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} | Estado: ${estado[0].toUpperCase()}${estado.substring(1)}',
                                      style: TextStyle(color: _estadoColor(estado)),
                                    )
                                  : null,
                              childrenPadding: const EdgeInsets.all(12),
                              children: [
                                if (mensaje.isNotEmpty) ...[
                                  const Text('Mensaje del cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(mensaje),
                                  const SizedBox(height: 10),
                                ],
                                if (fotosLugar.isNotEmpty) ...[
                                  const Text('Fotos del lugar:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: fotosLugar.length,
                                      itemBuilder: (c, i) => Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            fotosLugar[i],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (fotosMontaje.isNotEmpty) ...[
                                  const Text('Fotos de montaje:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: fotosMontaje.length,
                                      itemBuilder: (c, i) => Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            fotosMontaje[i],
                                            width: 100,
                                            height: 100,
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
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
