import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class CustomTexturePainterScreen extends StatefulWidget {
  final String templateAsset; // Image de contour du perso/animal

  const CustomTexturePainterScreen({super.key, required this.templateAsset});

  @override
  State<CustomTexturePainterScreen> createState() => _CustomTexturePainterScreenState();
}

class _CustomTexturePainterScreenState extends State<CustomTexturePainterScreen> {
  List<DrawingPoint?> points = [];
  Color selectedColor = const Color(0xFFFF8C00);
  double strokeWidth = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        title: const Text('Atelier de personnalisation'),
        backgroundColor: const Color(0xFF143063),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              if (points.isNotEmpty) {
                setState(() => points.removeLast());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Sauvegarde de l'image (en local ou Firestore/Storage)
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: Stack(
                  children: [
                    // Calque 1 : Modèle / contour de l'animal
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.35,
                        child: Image.asset(widget.templateAsset, fit: BoxFit.contain),
                      ),
                    ),
                    // Calque 2 : Dessin du joueur
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            RenderBox renderBox = context.findRenderObject() as RenderBox;
                            points.add(
                              DrawingPoint(
                                offset: details.localPosition,
                                paint: Paint()
                                  ..color = selectedColor
                                  ..strokeCap = StrokeCap.round
                                  ..strokeWidth = strokeWidth,
                              ),
                            );
                          });
                        },
                        onPanEnd: (_) => points.add(null),
                        child: CustomPaint(
                          painter: _Painter(points: points),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Barre d'outils couleurs
          _buildPalette(),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    final colors = [
      Colors.black,
      const Color(0xFFFF8C00),
      const Color(0xFF143063),
      Colors.pinkAccent,
      Colors.green,
      Colors.blue,
      Colors.white,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors.map((c) {
          return GestureDetector(
            onTap: () => setState(() => selectedColor = c),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedColor == c ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<DrawingPoint?> points;
  _Painter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}