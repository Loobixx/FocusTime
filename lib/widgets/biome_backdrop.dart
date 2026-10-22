import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Décor de camp dessiné en code pour chaque zone (desert, montagnes, lac,
/// nuages, nuit). Sert de fond tant que tu n'as pas d'image dans assets/biome/,
/// et de secours si une image est introuvable.
class BiomeBackdrop extends StatelessWidget {
  final String zoneId;

  const BiomeBackdrop({super.key, required this.zoneId});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _BiomePainter(zoneId)));
  }
}

class _Palette {
  final Color skyTop;
  final Color skyBottom;
  final Color celestial;
  final Color far;
  final Color mid;
  final Color groundTop;
  final Color groundBottom;
  final int stars;

  const _Palette({
    required this.skyTop,
    required this.skyBottom,
    required this.celestial,
    required this.far,
    required this.mid,
    required this.groundTop,
    required this.groundBottom,
    this.stars = 0,
  });
}

_Palette _paletteFor(String zone) {
  switch (zone) {
    case 'desert':
      return const _Palette(
        skyTop: Color(0xFFF4985A),
        skyBottom: Color(0xFFFFE3A6),
        celestial: Color(0xFFFFF3C4),
        far: Color(0xFFD9955B),
        mid: Color(0xFFE6B06A),
        groundTop: Color(0xFFF1CB8A),
        groundBottom: Color(0xFFD7A25C),
      );
    case 'lac':
      return const _Palette(
        skyTop: Color(0xFF4FB3D9),
        skyBottom: Color(0xFFD2F0F2),
        celestial: Color(0xFFFFF8DC),
        far: Color(0xFF5F9EA0),
        mid: Color(0xFF4C9A6A),
        groundTop: Color(0xFF8CC76F),
        groundBottom: Color(0xFF4E9A55),
      );
    case 'nuages':
      return const _Palette(
        skyTop: Color(0xFFB08CF0),
        skyBottom: Color(0xFFFFC9E2),
        celestial: Color(0xFFFFFFFF),
        far: Color(0xFFE5D8FA),
        mid: Color(0xFFF3E7FB),
        groundTop: Color(0xFFFFF4FB),
        groundBottom: Color(0xFFE0CFF3),
        stars: 25,
      );
    case 'nuit':
      return const _Palette(
        skyTop: Color(0xFF0B1033),
        skyBottom: Color(0xFF3A2A6B),
        celestial: Color(0xFFE8ECFF),
        far: Color(0xFF1D1B4A),
        mid: Color(0xFF1F2A44),
        groundTop: Color(0xFF2E4A47),
        groundBottom: Color(0xFF1B2F33),
        stars: 70,
      );
    case 'montagnes':
    default:
      return const _Palette(
        skyTop: Color(0xFF7FA8D6),
        skyBottom: Color(0xFFE6F0F8),
        celestial: Color(0xFFFFF6D5),
        far: Color(0xFF8D9DB5),
        mid: Color(0xFF5E7F6A),
        groundTop: Color(0xFF86B96C),
        groundBottom: Color(0xFF4F8A4C),
      );
  }
}

class _BiomePainter extends CustomPainter {
  final String zone;

  const _BiomePainter(this.zone);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final _Palette p = _paletteFor(zone);
    final int seed = zone.codeUnits.fold<int>(
      7,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    final math.Random rnd = math.Random(seed);
    final Rect rect = Offset.zero & size;

    double Function(double) ridge({
      required double base,
      required double amp,
      required double freq,
      double phase = 0,
      bool jagged = false,
    }) {
      return (double x) {
        final double t = x / w * freq + phase;
        if (jagged) {
          final double f = t - t.floorToDouble();
          final double tri = 1 - (2 * f - 1).abs();
          final double v =
              math.pow(tri, 1.3).toDouble() * (0.65 + 0.35 * math.sin(t * 1.7 + 1));
          return base - amp * v;
        }
        return base - amp * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
      };
    }

    void fillRidge(double Function(double) fn, Paint paint) {
      final Path path = Path()..moveTo(0, h);
      const int steps = 80;
      for (int i = 0; i <= steps; i++) {
        final double x = w * i / steps;
        path.lineTo(x, fn(x));
      }
      path.lineTo(w, h);
      path.close();
      canvas.drawPath(path, paint);
    }

    // 1. Ciel
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyBottom],
        ).createShader(rect),
    );

    // 2. Étoiles
    for (int i = 0; i < p.stars; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.42),
        0.6 + rnd.nextDouble() * 1.2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4 + rnd.nextDouble() * 0.6),
      );
    }

    // 3. Soleil / lune
    final bool isDesert = zone == 'desert';
    final Offset sunCenter = Offset(w * 0.72, h * (isDesert ? 0.26 : 0.16));
    final double sunRadius = w * (isDesert ? 0.12 : 0.085);
    canvas.drawCircle(
      sunCenter,
      sunRadius * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.celestial.withValues(alpha: 0.38),
            p.celestial.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 3)),
    );
    canvas.drawCircle(sunCenter, sunRadius, Paint()..color = p.celestial);

    // 4. Nuages
    void cloud(double cx, double cy, double s, double alpha) {
      final Paint paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: s, height: s * 0.38),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - s * 0.25, cy + s * 0.05),
          width: s * 0.6,
          height: s * 0.3,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + s * 0.28, cy + s * 0.06),
          width: s * 0.55,
          height: s * 0.28,
        ),
        paint,
      );
    }

    final int cloudCount = zone == 'nuages' ? 7 : 3;
    for (int i = 0; i < cloudCount; i++) {
      cloud(
        rnd.nextDouble() * w,
        h * (0.08 + rnd.nextDouble() * 0.22),
        w * (0.25 + rnd.nextDouble() * 0.25),
        zone == 'nuit' ? 0.07 : 0.55,
      );
    }

    // 5. Relief lointain
    final Paint farPaint = Paint()..color = p.far;
    final Paint midPaint = Paint()..color = p.mid;
    double Function(double) farFn;
    double Function(double) midFn;
    switch (zone) {
      case 'desert':
        farFn = ridge(base: h * 0.38, amp: h * 0.05, freq: 1.3);
        midFn = ridge(base: h * 0.46, amp: h * 0.04, freq: 2.2, phase: 0.3);
        break;
      case 'lac':
        farFn = ridge(base: h * 0.38, amp: h * 0.05, freq: 1.4);
        midFn = ridge(base: h * 0.50, amp: h * 0.03, freq: 2.1, phase: 0.2);
        break;
      case 'nuages':
        farFn = ridge(base: h * 0.40, amp: h * 0.035, freq: 4);
        midFn = ridge(base: h * 0.47, amp: h * 0.03, freq: 3, phase: 0.5);
        break;
      case 'nuit':
        farFn = ridge(base: h * 0.40, amp: h * 0.12, freq: 2, phase: 0.2, jagged: true);
        midFn = ridge(base: h * 0.47, amp: h * 0.035, freq: 1.8, phase: 0.1);
        break;
      case 'montagnes':
      default:
        farFn = ridge(base: h * 0.40, amp: h * 0.17, freq: 2.5, phase: 0.1, jagged: true);
        midFn = ridge(base: h * 0.47, amp: h * 0.035, freq: 1.8);
        break;
    }
    fillRidge(farFn, farPaint);

    // Sommets enneigés
    if (zone == 'montagnes') {
      final Paint snow = Paint()..color = Colors.white.withValues(alpha: 0.92);
      for (int k = -1; k <= 4; k++) {
        final double x = (k + 0.5 - 0.1) / 2.5 * w;
        if (x < 0 || x > w) continue;
        final double y = farFn(x);
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x - w * 0.04, y + h * 0.04)
            ..lineTo(x - w * 0.015, y + h * 0.032)
            ..lineTo(x, y + h * 0.045)
            ..lineTo(x + w * 0.02, y + h * 0.032)
            ..lineTo(x + w * 0.04, y + h * 0.04)
            ..close(),
          snow,
        );
      }
    }

    // Lac
    if (zone == 'lac') {
      final Rect water = Rect.fromLTRB(0, h * 0.43, w, h * 0.54);
      canvas.drawRect(
        water,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5BC0E3), Color(0xFF3A9BD0)],
          ).createShader(water),
      );
      for (int i = 0; i < 8; i++) {
        final double y = h * (0.45 + rnd.nextDouble() * 0.07);
        final double x = rnd.nextDouble() * w;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w * 0.12, 2),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
      }
    }

    fillRidge(midFn, midPaint);

    // 6. Sol
    final double Function(double) groundFn = ridge(
      base: h * 0.52,
      amp: h * 0.012,
      freq: 2.2,
      phase: 0.4,
    );
    fillRidge(
      groundFn,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.groundTop, p.groundBottom],
        ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)),
    );

    // Clairière claire où se pose le camp
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.64),
        width: w * 1.0,
        height: h * 0.2,
      ),
      Paint()
        ..color = Color.lerp(p.groundTop, Colors.white, 0.25)!.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // 7. Décor sur les côtés (arbres / cactus)
    if (zone != 'nuages') {
      final List<Offset> spots = [];
      for (int i = 0; i < 12; i++) {
        final bool left = i.isEven;
        final double x = (left ? 0.0 : 0.82) * w + rnd.nextDouble() * 0.16 * w;
        final double y = h * (0.53 + rnd.nextDouble() * 0.32);
        spots.add(Offset(x, y));
      }
      spots.sort((a, b) => a.dy.compareTo(b.dy));

      for (final Offset s in spots) {
        final double sc = w * (0.06 + (s.dy / h - 0.5) * 0.16);
        canvas.drawOval(
          Rect.fromCenter(center: s, width: sc * 0.7, height: sc * 0.14),
          Paint()..color = Colors.black.withValues(alpha: 0.18),
        );
        if (zone == 'desert') {
          _cactus(canvas, s, sc);
        } else if (zone == 'lac') {
          _roundTree(canvas, s, sc);
        } else {
          _pine(canvas, s, sc, zone == 'nuit' ? const Color(0xFF14302F) : const Color(0xFF2F6B4A));
        }
      }
    }

    // 8. Ombre en bas pour garder les boutons lisibles
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
          stops: const [0.65, 1],
        ).createShader(rect),
    );
  }

  void _pine(Canvas canvas, Offset base, double s, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(base.dx - s * 0.06, base.dy - s * 0.25, s * 0.12, s * 0.25),
      Paint()..color = const Color(0xFF5A3A1C),
    );
    for (int i = 0; i < 3; i++) {
      final double apexY = base.dy - s * 1.3 + i * s * 0.32;
      final double baseY = apexY + s * 0.62;
      final double half = s * (0.28 + i * 0.1);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, apexY)
          ..lineTo(base.dx - half, baseY)
          ..lineTo(base.dx + half, baseY)
          ..close(),
        Paint()..color = Color.lerp(color, Colors.black, i * 0.08)!,
      );
    }
  }

  void _roundTree(Canvas canvas, Offset base, double s) {
    canvas.drawRect(
      Rect.fromLTWH(base.dx - s * 0.06, base.dy - s * 0.5, s * 0.12, s * 0.5),
      Paint()..color = const Color(0xFF6B4423),
    );
    final Paint crown = Paint()..color = const Color(0xFF3E8E52);
    canvas.drawCircle(Offset(base.dx, base.dy - s * 0.8), s * 0.38, crown);
    canvas.drawCircle(Offset(base.dx - s * 0.24, base.dy - s * 0.62), s * 0.28, crown);
    canvas.drawCircle(Offset(base.dx + s * 0.24, base.dy - s * 0.62), s * 0.28, crown);
  }

  void _cactus(Canvas canvas, Offset base, double s) {
    final Paint paint = Paint()..color = const Color(0xFF4C8C4A);
    RRect r(double l, double t, double w, double h) => RRect.fromRectAndRadius(
      Rect.fromLTWH(l, t, w, h),
      Radius.circular(w / 2),
    );
    canvas.drawRRect(r(base.dx - s * 0.08, base.dy - s * 0.9, s * 0.16, s * 0.9), paint);
    canvas.drawRRect(r(base.dx - s * 0.28, base.dy - s * 0.3, s * 0.28, s * 0.1), paint);
    canvas.drawRRect(r(base.dx - s * 0.28, base.dy - s * 0.55, s * 0.12, s * 0.35), paint);
    canvas.drawRRect(r(base.dx, base.dy - s * 0.45, s * 0.26, s * 0.1), paint);
    canvas.drawRRect(r(base.dx + s * 0.14, base.dy - s * 0.65, s * 0.12, s * 0.30), paint);
  }

  @override
  bool shouldRepaint(covariant _BiomePainter oldDelegate) =>
      oldDelegate.zone != zone;
}
