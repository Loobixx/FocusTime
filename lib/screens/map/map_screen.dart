import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/utils/app_haptics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_time/screens/map/data/map_region_data.dart';
import 'package:focus_time/screens/map/region_detail_screen.dart';
import 'package:focus_time/screens/map/data/region_cross_data.dart';
import 'package:focus_time/screens/map/fog_of_war.dart';
import 'package:focus_time/widgets/game_sprites.dart';
import 'package:focus_time/config/sprite_config.dart';

class MapScreen extends StatefulWidget {
  final int selectedDurationMinutes;
  final bool readOnly;

  const MapScreen({
    super.key,
    this.selectedDurationMinutes = 0,
    this.readOnly = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRegionId;
  String? _hoveredRegionId;
  String? _currentRegionId;
  String _characterId = 'nuit';

  Set<String> _visitedRegionIds = {};

  late final TransformationController _transformationController;
  bool _viewInitialized = false;
  double _fitScale = 1.0;

  static const double baseWidth = 1023.0;
  static const double baseHeight = 1537.0;

  static const double _zoomInFactor = 3.0;
  static const double _zoomOutFactor = 1.0;

  final List<RegionShape> _regions = MapRegionsData.regions;

  late final AnimationController _cloudAnimationController;
  List<ui.Image>? _cloudSprites;
  late final Rect? _regionsBounds = _computeRegionsBounds();

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _cloudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: FogSettings.cycleSeconds),
    )..repeat();

    CloudSprites.generate().then((sprites) {
      if (!mounted) {
        for (final img in sprites) {
          img.dispose();
        }
        return;
      }
      setState(() => _cloudSprites = sprites);
    });

    _loadUserRegion();
  }

  Rect? _computeRegionsBounds() {
    Rect? bounds;
    for (final region in _regions) {
      final b = region.path.getBounds();
      bounds = bounds == null ? b : bounds.expandToInclude(b);
    }
    return bounds;
  }

  Rect? _cloudZone() {
    final bounds = _regionsBounds;
    if (bounds == null) return null;

    final double marginMapUnits =
        WorldCloudSettings.clearMarginCm *
        WorldCloudSettings.logicalPxPerCm /
        _fitScale;
    final Rect mapRect = Rect.fromLTWH(0, 0, baseWidth, baseHeight);

    Rect zone = bounds.intersect(mapRect.deflate(marginMapUnits));
    if (zone.width < 200 || zone.height < 200) zone = bounds;
    return zone;
  }

  Future<void> _loadUserRegion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final userDoc = await userRef.get();

    final visitedDoc = await userRef.collection('visited_cities').get();
    final stoppedDoc = await userRef.collection('stopped_cities').get();

    final Set<String> visitedCities = {
      ...visitedDoc.docs.map((d) => d.id),
      ...stoppedDoc.docs.map((d) => d.id),
    };

    final charId = userDoc.data()?['characterId'] as String? ?? 'nuit';
    String? currentCity = userDoc.data()?['currentCity'] as String?;

    Set<String> visitedRegions = {};
    String? foundRegion;

    for (var entry in RegionCrossesData.crossesByRegion.entries) {
      for (var cross in entry.value) {
        if (currentCity != null && cross.name == currentCity) {
          foundRegion = entry.key;
        }
        if (visitedCities.contains(cross.name)) {
          visitedRegions.add(entry.key);
        }
      }
    }

    if (foundRegion != null) {
      visitedRegions.add(foundRegion);
    }

    if (mounted) {
      setState(() {
        _characterId = charId;
        _currentRegionId = foundRegion;
        _visitedRegionIds = visitedRegions;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _cloudAnimationController.dispose();
    for (final s in _cloudSprites ?? const <ui.Image>[]) {
      s.dispose();
    }
    super.dispose();
  }

  RegionShape? _regionAt(Offset localPosition, List<RegionShape> scaled) {
    for (var region in scaled) {
      if (region.path.contains(localPosition)) {
        return region;
      }
    }
    return null;
  }

  void _handleHover(PointerHoverEvent event, List<RegionShape> scaled) {
    final region = _regionAt(event.localPosition, scaled);
    if (region?.id != _hoveredRegionId) {
      if (region != null) AppHaptics.lightImpact();
      setState(() => _hoveredRegionId = region?.id);
    }
  }

  void _handleTapUp(TapUpDetails details, List<RegionShape> scaled) {
    final region = _regionAt(details.localPosition, scaled);
    if (region == null) {
      setState(() => _selectedRegionId = null);
      return;
    }
    if (_selectedRegionId == region.id) {
      AppHaptics.mediumImpact();
    } else {
      AppHaptics.lightImpact();
    }
    setState(() {
      if (_selectedRegionId == region.id) {
        _openRegionDetail(region.id);
      } else {
        _selectedRegionId = region.id;
      }
    });
  }

  void _openRegionDetail(String regionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionDetailScreen(
          regionName: regionId,
          selectedDurationMinutes: widget.selectedDurationMinutes,
          readOnly: widget.readOnly,
        ),
      ),
    );
  }

  String? get _displayedName {
    final id = _hoveredRegionId ?? _selectedRegionId;
    if (id == null) return null;
    return _regions.firstWhere((r) => r.id == id).name;
  }

  void _setupInitialView(Size screenSize) {
    final double fitScale = math.max(
      screenSize.width / baseWidth,
      screenSize.height / baseHeight,
    );

    _fitScale = fitScale * 1;

    final double scaledWidth = baseWidth * _fitScale;
    final double scaledHeight = baseHeight * _fitScale;
    final double dx = (screenSize.width - scaledWidth) / 2;
    final double dy = (screenSize.height - scaledHeight) / 2;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(_fitScale);
  }

  Offset? _getRegionCenter(String? regionId) {
    switch (regionId) {
      case 'desert':
        return const Offset(260, 480);
      case 'lac':
        return const Offset(220, 920);
      case 'montagnes':
        return const Offset(630, 1150);
      case 'nuit':
        return const Offset(710, 700);
      case 'nuages':
        return const Offset(760, 290);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    final playerPosition = _getRegionCenter(_currentRegionId);
    final Size charSize = SpriteConfig.character(SpriteScene.world);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/biome/fond_de_zoom.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size screenSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                if (!_viewInitialized) {
                  _viewInitialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _setupInitialView(screenSize);
                    });
                  });
                }

                final double minScale = _fitScale * _zoomOutFactor;
                final double maxScale = _fitScale * _zoomInFactor;

                final scaledRegions = _regions;
                final Rect? cloudZone = _cloudZone();

                // ✨ On donne TOUTES les régions pour empêcher les nuages blancs d'aller sur l'île
                final List<Path> allIslandPaths = _regions
                    .map((r) => r.path)
                    .toList();

                return InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false,
                  boundaryMargin: EdgeInsets.zero,
                  minScale: minScale,
                  maxScale: maxScale,
                  child: SizedBox(
                    width: baseWidth,
                    height: baseHeight,
                    child: MouseRegion(
                      cursor: _hoveredRegionId != null
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      onHover: (e) => _handleHover(e, scaledRegions),
                      onExit: (_) => setState(() => _hoveredRegionId = null),
                      child: GestureDetector(
                        onTapUp: (details) =>
                            _handleTapUp(details, scaledRegions),
                        child: Stack(
                          children: [
                            const RepaintBoundary(
                              child: Image(
                                image: AssetImage(
                                  'assets/biome/map_global.png',
                                ),
                                width: baseWidth,
                                height: baseHeight,
                                fit: BoxFit.fill,
                              ),
                            ),

                            // ☁️ Nuages de la map globale (cantonnés à l'océan)
                            if (cloudZone != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _cloudAnimationController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          size: const Size(
                                            baseWidth,
                                            baseHeight,
                                          ),
                                          painter: WorldCloudsPainter(
                                            zone: cloudZone,
                                            animationValue:
                                                _cloudAnimationController.value,
                                            sprites: _cloudSprites,
                                            revealPaths:
                                                allIslandPaths, // Garde l'île claire !
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                            // Peinture des régions (avec l'assombrissement)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: const Size(baseWidth, baseHeight),
                                painter: MapPainter(
                                  regions: scaledRegions,
                                  selectedRegionId: _selectedRegionId,
                                  hoveredRegionId: _hoveredRegionId,
                                  visitedRegionIds:
                                      _visitedRegionIds, // ✨ On passe les régions explorées
                                  onRegionTap: _handleSemanticRegionTap,
                                ),
                              ),
                            ),

                            if (playerPosition != null)
                              Positioned(
                                left: playerPosition.dx - charSize.width / 2,
                                top:
                                    playerPosition.dy -
                                    charSize.height * SpriteConfig.footRatio,
                                child: IgnorePointer(
                                  child: RepaintBoundary(
                                    child: CharacterSprite(
                                      characterId: _characterId,
                                      scene: SpriteScene.world,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: darkBlue,
                        ),
                        tooltip: 'Retour',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () {
                          AppHaptics.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_displayedName != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: darkBlue.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Semantics(
                    liveRegion: _selectedRegionId != null,
                    label: _selectedRegionId != null
                        ? 'Région sélectionnée : $_displayedName. Touchez de nouveau pour explorer.'
                        : 'Région : $_displayedName',
                    excludeSemantics: true,
                    child: Text(
                      _selectedRegionId != null
                          ? '$_displayedName — retape pour explorer !'
                          : _displayedName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSemanticRegionTap(RegionShape region) {
    if (_selectedRegionId == region.id) {
      AppHaptics.mediumImpact();
      _openRegionDetail(region.id);
    } else {
      AppHaptics.lightImpact();
      setState(() => _selectedRegionId = region.id);
    }
  }
}

class MapPainter extends CustomPainter {
  final List<RegionShape> regions;
  final String? selectedRegionId;
  final String? hoveredRegionId;
  final Set<String> visitedRegionIds; // ✨ Requis pour savoir quoi assombrir
  final ValueChanged<RegionShape> onRegionTap;

  MapPainter({
    required this.regions,
    this.selectedRegionId,
    this.hoveredRegionId,
    required this.visitedRegionIds,
    required this.onRegionTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final bool isHovered = region.id == hoveredRegionId;
      final bool isSelected = region.id == selectedRegionId;
      final bool isExplored = visitedRegionIds.contains(region.id);

      // ✨ L'ombre exacte pour les régions non explorées (Effet "Fog of War" sur terre)
      if (!isExplored) {
        final darkOverlay = Paint()
          ..color = Colors.black
              .withValues(
                alpha: 0.5,
              ) // Noir semi-transparent pour l'effet ombre
          ..style = PaintingStyle.fill;
        canvas.drawPath(region.path, darkOverlay);
      }

      // Surbrillance au survol/clic
      if (isHovered || isSelected) {
        final highlightFill = Paint()
          ..color = Colors.white.withValues(alpha: isSelected ? 0.35 : 0.22)
          ..style = PaintingStyle.fill;
        final highlightStroke = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawPath(region.path, highlightFill);
        canvas.drawPath(region.path, highlightStroke);
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
    return regions.map((region) {
      final bounds = region.path.getBounds();
      final widthPadding = math.max(0.0, (48 - bounds.width) / 2);
      final heightPadding = math.max(0.0, (48 - bounds.height) / 2);
      final semanticRect = bounds.inflate(math.max(widthPadding, heightPadding));
      final bool isVisited = visitedRegionIds.contains(region.id);
      return CustomPainterSemantics(
        rect: semanticRect,
        properties: SemanticsProperties(
          label:
              'Région ${region.name}, état : ${isVisited ? 'visitée' : 'à découvrir'}',
          hint: selectedRegionId == region.id
              ? 'Activer de nouveau pour explorer cette région'
              : 'Activer pour sélectionner cette région',
          button: true,
          selected: selectedRegionId == region.id,
          onTap: () => onRegionTap(region),
        ),
      );
    }).toList();
  };

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.hoveredRegionId != hoveredRegionId ||
        oldDelegate.visitedRegionIds != visitedRegionIds ||
        oldDelegate.regions != regions;
  }
}
