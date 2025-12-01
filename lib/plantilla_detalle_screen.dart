import 'package:flutter/material.dart';
import 'reserva_screen.dart';

class PlantillaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> plantilla;

  const PlantillaDetalleScreen({super.key, required this.plantilla});

  @override
  State<PlantillaDetalleScreen> createState() => _PlantillaDetalleScreenState();
}

class _PlantillaDetalleScreenState extends State<PlantillaDetalleScreen> {
  String? colorSeleccionado;
  String? otroColor;
  double cotizacion = 0;

  @override
  void initState() {
    super.initState();
    cotizacion = (widget.plantilla['precio'] ?? 0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Colores fijos
    final coloresDisponibles = [
      'Azul y Blanco',
      'Rojo y Blanco',
      'Verde y Blanco',
      'Negro y Blanco',
      'Otros'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantilla['nombre']),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen
            Image.network(
              widget.plantilla['imagen'],
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 20),

            // Selección de color
            Center(
              child: SizedBox(
                width: 200, 
                child: DropdownButton<String>(
                  value: colorSeleccionado,
                  hint: const Text("Seleccionar color"),
                  isExpanded: true,
                  items: coloresDisponibles.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      colorSeleccionado = value;
                      if (value != 'Otros') otroColor = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Si selecciona "Otros", mostrar campo de texto
            if (colorSeleccionado == 'Otros')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() {
                    otroColor = v;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Escribe tus colores',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Text(
              "Total estimado: S/ $cotizacion",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                ),
                onPressed: (colorSeleccionado == null ||
                        (colorSeleccionado == 'Otros' &&
                            (otroColor == null || otroColor!.isEmpty)))
                    ? null
                    : () {
                        final colorFinal =
                            colorSeleccionado == 'Otros' ? otroColor! : colorSeleccionado!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservaScreen(
                              plantilla: widget.plantilla,
                              color: colorFinal,
                              cotizacion: cotizacion,
                            ),
                          ),
                        );
                      },
                child: const Text("Continuar con la reserva"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
