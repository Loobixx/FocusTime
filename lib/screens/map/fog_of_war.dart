import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ============================================================================
//  ☁️  RÉGLAGES DU BROUILLARD / DES NUAGES  (tout se règle ici)
// ============================================================================
class FogSettings {
  FogSettings._();

  static const int cycleSeconds = 120;
  static const int maxSpeedMultiplier = 3;
  static const double verticalBobAmplitude = 14.0;

  static const double densityDivisor = 150000;
  static const int minClouds = 20;
  static const int maxClouds = 48;

  static const double minScale = 1.0;
  static const double scaleRange = 1.4;

  static const double minOpacity = 0.55;
  static const double opacityRange = 0.45;

  static const Color baseFogColor = Color(0xFFC3CEDC);
  static const double baseFogAlpha = 0.97;

  static const Color cloudShadowColor = Color(0xFF8FA0B8);
  static const double cloudShadowAlpha = 0.55;
  static const Color cloudBodyColor = Color(0xFFE8EEF6);
  static const double cloudBodyAlpha = 0.85;
  static const Color cloudLightColor = Colors.white;
  static const double cloudLightAlpha = 0.8;

  static const int spriteVariants = 4;
  static const double spriteWidth = 640;
  static const double spriteHeight = 360;

  static const int minPuffs = 16;
  static const int puffsRange = 8;

  static const double minPuffRadius = 42;
  static const double puffRadiusRange = 48;

  static const double shadowBlur = 0.45;
  static const double bodyBlur = 0.35;
  static const double lightBlur = 0.30;

  static const double visitedRevealRadius = 260.0;
  static const double frontierRevealRadius = 170.0;
  static const double revealRadiusMultiplier = 1.3;

  static const Map<String, List<RegionTitleReveal>> titleReveals = {
    'montagnes': [
      RegionTitleReveal(
        position: Offset(1150.0, 140.0),
        radiusX: 300.0,
        radiusY: 150.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
    'desert': [
      RegionTitleReveal(
        position: Offset(760.0, 1450.0),
        radiusX: 330.0,
        radiusY: 150.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
    'lac': [
      RegionTitleReveal(
        position: Offset(300.0, 270.0),
        radiusX: 330.0,
        radiusY: 200.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
  };

  static const bool debugTitleZones = false;

  static const int desktopFps = 60;
  static const int phoneFps = 30;
  static const double phoneDensityMultiplier = 0.6;
  static const double phoneSpriteQuality = 0.5;

  static int get cloudFps => phoneFps; // Ajustable selon ta logique de détection de téléphone
  static double get spriteQuality => 1.0;
  static double get densityFactor => phoneDensityMultiplier;
  static FilterQuality get filterQuality => FilterQuality.medium;
}

/// Représente une zone circulaire dégagée dans le brouillard
class FogRevealArea {
  final Offset center;
  final double radius;

  const FogRevealArea({required this.center, required this.radius});
}

/// Zone ovale sans nuages pour laisser apparaître les noms de régions
class RegionTitleReveal {
  final Offset position;
  final double radiusX;
  final double radiusY;
  final double softness;
  final double rotationDegrees;

  const RegionTitleReveal({
    required this.position,
    this.radiusX = 160.0,
    this.radiusY = 55.0,
    this.softness = 0.35,
    this.rotationDegrees = 0.0,
  });
}

/// Génère les sprites de nuages une seule fois
class CloudSprites {
  static const double w = FogSettings.spriteWidth;
  static const double h = FogSettings.spriteHeight;

  static Future<List<ui.Image>> generate() async {
    final List<ui.Image> out = [];
    for (int seed = 0; seed < FogSettings.spriteVariants; seed++) {
      out.add(await _make(seed));
    }
    return out;
  }

  static Future<ui.Image> _make(int seed) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double q = FogSettings.spriteQuality;
    canvas.scale(q);
    final rnd = math.Random(seed * 77 + 5);

    final List<List<double>> puffs = [];
    final int n = FogSettings.minPuffs + rnd.nextInt(FogSettings.puffsRange);
    for (int i = 0; i < n; i++) {
      final double t = rnd.nextDouble() * 2 * math.pi;
      final double dist = math.sqrt(rnd.nextDouble());
      final double x = w / 2 + math.cos(t) * dist * w * 0.26;
      final double sy = math.sin(t);
      final double y = h * 0.58 + (sy > 0 ? sy * dist * h * 0.08 : sy * dist * h * 0.24);
      final double r = (FogSettings.minPuffRadius + rnd.nextDouble() * FogSettings.puffRadiusRange) *
          (1.0 - dist * 0.35);
      puffs.add([x, y, r]);
    }

    // 1) Ombre
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1] + p[2] * 0.35),
        p[2],
        Paint()
          ..color = FogSettings.cloudShadowColor.withValues(alpha: FogSettings.cloudShadowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.shadowBlur),
      );
    }
    // 2) Corps
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1]),
        p[2],
        Paint()
          ..color = FogSettings.cloudBodyColor.withValues(alpha: FogSettings.cloudBodyAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.bodyBlur),
      );
    }
    // 3) Lumière
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1] - p[2] * 0.3),
        p[2] * 0.7,
        Paint()
          ..color = FogSettings.cloudLightColor.withValues(alpha: FogSettings.cloudLightAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.lightBlur),
      );
    }

    return recorder.endRecording().toImage((w * q).round(), (h * q).round());
  }
}

class _CloudInstance {
  final int sprite;
  final double baseX, baseY, scale, opacity, phase;
  final int speed;
  const _CloudInstance(this.sprite, this.baseX, this.baseY, this.scale,
      this.opacity, this.phase, this.speed);
}

/// Dessine le brouillard : voile + nuages + trous
class FogOfWarPainter extends CustomPainter {
  final List<FogRevealArea> revealAreas;
  final List<RegionTitleReveal> titleReveals;
  final double animationValue;
  final List<ui.Image>? sprites;

  static const double overflow = 2000.0;

  FogOfWarPainter({
    required this.revealAreas,
    required this.titleReveals,
    required this.animationValue,
    required this.sprites,
  });

  static List<_CloudInstance>? _cache;
  static Size? _cacheSize;
  static int? _cacheSpriteCount;

  static List<_CloudInstance> _instances(Size size, int spriteCount) {
    if (_cache != null && _cacheSize == size && _cacheSpriteCount == spriteCount) {
      return _cache!;
    }
    final rnd = math.Random(123);
    final double totalWidth = size.width + (overflow * 2);
    final double totalHeight = size.height + (overflow * 2);

    final int baseCount = (totalWidth * totalHeight / FogSettings.densityDivisor)
        .round()
        .clamp(FogSettings.minClouds, FogSettings.maxClouds * 4);

    final int count = (baseCount * FogSettings.densityFactor).round().clamp(8, FogSettings.maxClouds * 4);
    final list = <_CloudInstance>[];
    
    for (int i = 0; i < count; i++) {
      list.add(_CloudInstance(
        rnd.nextInt(spriteCount),
        -overflow + rnd.nextDouble() * (totalWidth + CloudSprites.w * 2.4),
        -overflow + rnd.nextDouble() * totalHeight,
        FogSettings.minScale + rnd.nextDouble() * FogSettings.scaleRange,
        FogSettings.minOpacity + rnd.nextDouble() * FogSettings.opacityRange,
        rnd.nextDouble() * 2 * math.pi,
        1 + rnd.nextInt(FogSettings.maxSpeedMultiplier),
      ));
    }
    
    list.sort((a, b) => a.scale.compareTo(b.scale));
    _cacheSize = size;
    _cacheSpriteCount = spriteCount;
    return _cache = list;
  }

  @override
  bool shouldRepaint(covariant FogOfWarPainter old) =>
      old.animationValue != animationValue ||
      old.sprites != sprites ||
      old.revealAreas.length != revealAreas.length ||
      old.titleReveals.length != titleReveals.length;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Rect.fromLTWH(
      -overflow, 
      -overflow, 
      size.width + (overflow * 2), 
      size.height + (overflow * 2),
    );
    canvas.saveLayer(fullRect, Paint());

    canvas.drawRect(
      fullRect,
      Paint()..color = FogSettings.baseFogColor.withValues(alpha: FogSettings.baseFogAlpha),
    );

    final s = sprites;
    if (s != null && s.isNotEmpty) {
      final double wrapW = size.width + (overflow * 2) + CloudSprites.w * 2.4;
      final Paint p = Paint()..filterQuality = FogSettings.filterQuality;
      
      for (final c in _instances(size, s.length)) {
        final double cw = CloudSprites.w * c.scale;
        final double ch = CloudSprites.h * c.scale;
        
        double x = c.baseX + animationValue * wrapW * c.speed;
        x = -overflow + ((x + overflow) % wrapW) - cw;
        
        final double y = c.baseY +
            math.sin(animationValue * 2 * math.pi * c.speed + c.phase) * FogSettings.verticalBobAmplitude;
            
        if (x > size.width + overflow || x + cw < -overflow || y > size.height + overflow || y + ch < -overflow) continue;

        p.color = Color.fromRGBO(255, 255, 255, c.opacity);
        final img = s[c.sprite];
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(x, y, cw, ch),
          p,
        );
      }
    }

    for (final area in revealAreas) {
      final double r = area.radius * FogSettings.revealRadiusMultiplier;
      final Rect holeRect = Rect.fromCircle(center: area.center, radius: r);
      canvas.drawCircle(
        area.center,
        r,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: [Colors.black, Colors.black.withValues(alpha: 0.8), Colors.transparent],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(holeRect),
      );
    }

    for (final title in titleReveals) {
      canvas.save();
      canvas.translate(title.position.dx, title.position.dy);
      canvas.rotate(title.rotationDegrees * math.pi / 180.0);
      canvas.scale(title.radiusX, title.radiusY);

      final double inner = (1.0 - title.softness).clamp(0.0, 0.999);
      canvas.drawCircle(
        Offset.zero,
        1.0,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, inner, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.0)),
      );
      canvas.restore();
    }

    canvas.restore();

    if (FogSettings.debugTitleZones) {
      final Paint outline = Paint()
        ..color = const Color(0xFFFF1744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      final Paint dot = Paint()..color = const Color(0xFFFF1744);
      for (final title in titleReveals) {
        canvas.save();
        canvas.translate(title.position.dx, title.position.dy);
        canvas.rotate(title.rotationDegrees * math.pi / 180.0);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: title.radiusX * 2,
            height: title.radiusY * 2,
          ),
          outline,
        );
        canvas.drawCircle(Offset.zero, 8, dot);
        canvas.restore();
      }
    }
  }
}