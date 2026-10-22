import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Image d'un compagnon affichée dans le camp / l'enclos.
String campCompanionAsset(String companionId) => switch (companionId) {
  'chien' => 'assets/compagnons/Chien/chien_arret/1.png',
  // Le chat ne possède pas de dossier chat_arret avec des images séparées.
  'chat' => 'assets/compagnons/Chat/chat_marche/0.png',
  _ => 'assets/compagnons/Chien/chien_arret/1.png',
};

/// Feu de camp animé, entièrement dessiné en code (aucun asset requis).
class Campfire extends StatefulWidget {
  const Campfire({super.key});

  @override
  State<Campfire> createState() => _CampfireState();
}

class _CampfireState extends State<Campfire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _CampfirePainter(_controller.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CampfirePainter extends CustomPainter {
  final double t;

  const _CampfirePainter(this.t);

  double _wave(double speed, double phase) =>
      math.sin(2 * math.pi * (t * speed + phase));

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w * 0.5;
    final double baseY = h * 0.84;

    // Lueur chaude au sol.
    final Offset glowCenter = Offset(cx, baseY - h * 0.08);
    final double glowAlpha = 0.22 + 0.06 * _wave(5, 0);
    canvas.drawCircle(
      glowCenter,
      w * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFB347).withValues(alpha: glowAlpha),
            const Color(0x00FFB347),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: w * 0.95)),
    );

    void stones({required bool front}) {
      const int count = 9;
      for (int i = 0; i < count; i++) {
        final double a = 2 * math.pi * i / count;
        final bool isFront = math.sin(a) > 0;
        if (isFront != front) continue;
        final Offset p = Offset(
          cx + math.cos(a) * w * 0.36,
          baseY + math.sin(a) * h * 0.07,
        );
        canvas.drawOval(
          Rect.fromCenter(center: p, width: w * 0.13, height: h * 0.075),
          Paint()..color = const Color(0xFF5E6165),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: p.translate(0, -h * 0.01),
            width: w * 0.11,
            height: h * 0.055,
          ),
          Paint()..color = const Color(0xFF8A8D91),
        );
      }
    }

    stones(front: false);

    // Fumée.
    for (int i = 0; i < 4; i++) {
      final double p = (t + i / 4) % 1.0;
      final Offset c = Offset(
        cx + math.sin(p * 5 + i) * w * 0.07,
        h * 0.45 - p * h * 0.55,
      );
      canvas.drawCircle(
        c,
        w * 0.05 + p * w * 0.07,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.18 * (1 - p) * math.min(1.0, p * 5),
          ),
      );
    }

    void flame(double fx, double fw, double fh, Color color, double phase) {
      final double flick = 1 + 0.10 * _wave(3, phase);
      final double sway = _wave(2, phase) * fw * 0.18;
      final Offset top = Offset(fx + sway, baseY - fh * flick);
      final Path path = Path()
        ..moveTo(fx - fw / 2, baseY)
        ..quadraticBezierTo(fx - fw * 0.65, baseY - fh * 0.45, top.dx, top.dy)
        ..quadraticBezierTo(fx + fw * 0.65, baseY - fh * 0.45, fx + fw / 2, baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    flame(cx - w * 0.11, w * 0.20, h * 0.42, const Color(0xFFE8531F), 0.0);
    flame(cx + w * 0.11, w * 0.20, h * 0.38, const Color(0xFFE8531F), 0.4);
    flame(cx, w * 0.30, h * 0.58, const Color(0xFFFF8C00), 0.2);
    flame(cx, w * 0.18, h * 0.38, const Color(0xFFFFD54F), 0.6);
    flame(cx, w * 0.08, h * 0.20, const Color(0xFFFFF3C4), 0.8);

    // Étincelles.
    for (int i = 0; i < 3; i++) {
      final double p = (t * 2 + i * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(
          cx + math.sin(i * 2.1 + p * 4) * w * 0.15,
          baseY - h * 0.3 - p * h * 0.5,
        ),
        w * 0.012,
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 1 - p),
      );
    }

    // Bûches croisées devant la base des flammes.
    void log(double angle) {
      canvas.save();
      canvas.translate(cx, baseY - h * 0.01);
      canvas.rotate(angle);
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.62, height: h * 0.09),
        Radius.circular(h * 0.045),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0xFF5A3A1C));
      canvas.drawRRect(
        r.deflate(h * 0.014),
        Paint()..color = const Color(0xFF8B5E34),
      );
      canvas.restore();
    }

    log(0.35);
    log(-0.35);

    stones(front: true);
  }

  @override
  bool shouldRepaint(covariant _CampfirePainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Clôture en bois dessinée en code (utilisée si l'image n'est pas trouvée,
/// et dans la page de choix des compagnons).
class CampFencePainter extends CustomPainter {
  const CampFencePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint railPaint = Paint()
      ..color = const Color(0xFF795332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint highlightPaint = Paint()
      ..color = const Color(0xFFD7AE75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.014
      ..strokeCap = StrokeCap.round;
    final Paint postPaint = Paint()
      ..color = const Color(0xFF986B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    final List<Offset> upperRail = [
      Offset(size.width * 0.12, size.height * 0.26),
      Offset(size.width * 0.88, size.height * 0.26),
      Offset(size.width * 0.78, size.height * 0.70),
      Offset(size.width * 0.22, size.height * 0.70),
    ];
    final List<Offset> lowerRail = [
      Offset(size.width * 0.12, size.height * 0.40),
      Offset(size.width * 0.88, size.height * 0.40),
      Offset(size.width * 0.78, size.height * 0.84),
      Offset(size.width * 0.22, size.height * 0.84),
    ];

    void drawLoop(List<Offset> points, Paint paint) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    drawLoop(upperRail, railPaint);
    drawLoop(upperRail, highlightPaint);
    drawLoop(lowerRail, railPaint);

    for (int i = 0; i < upperRail.length; i++) {
      canvas.drawLine(upperRail[i], lowerRail[i], postPaint);
      canvas.drawCircle(
        upperRail[i],
        size.width * 0.035,
        Paint()..color = const Color(0xFFB88755),
      );
    }

    for (final int side in [0, 2]) {
      for (final double t in [0.33, 0.66]) {
        final int next = (side + 1) % upperRail.length;
        final Offset upper = Offset.lerp(upperRail[side], upperRail[next], t)!;
        final Offset lower = Offset.lerp(lowerRail[side], lowerRail[next], t)!;
        canvas.drawLine(upper, lower, postPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CampFencePainter oldDelegate) => false;
}
