import 'package:flutter/material.dart';

// Classe pour définir une forme de zone personnalisée par des points (path)
class RegionShape {
  final String id;
  final String name;
  final Path path; // Le chemin personnalisé tracé à la main

  RegionShape({required this.id, required this.name, required this.path});
}

// Peintre personnalisé pour afficher les bordures et les couleurs quand on clique dessus
class MapPainter extends CustomPainter {
  final List<RegionShape> regions;
  final String? selectedRegionId;

  MapPainter({required this.regions, this.selectedRegionId});

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final paintBorder = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var region in regions) {
      if (region.id == selectedRegionId) {
        // Dessine la zone sélectionnée avec une couleur et une bordure lumineuse
        canvas.drawPath(region.path, paintFill);
        canvas.drawPath(region.path, paintBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.selectedRegionId != selectedRegionId;
  }
}