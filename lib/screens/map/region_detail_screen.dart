import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/widgets/game_sprites.dart';
import 'package:focus_time/config/sprite_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/screens/map/data/region_cross_data.dart';
import 'package:focus_time/utils/city_name.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../models/city_network.dart';
import '../../utils/time_formatter.dart';
import '../focus/expedition_screen.dart';
import '../focus/focus_screen.dart'; // ✨ Ajouté pour s'assurer que FocusScreen est bien reconnu
import 'fog_of_war.dart';

// ============================================================================
//  ⚙️  RÉGLAGES DE LA CARTE (zoom, survol, couleurs des marqueurs)
// ============================================================================
class MapSettings {
  MapSettings._();

  /// Zoom max = fitScale * zoomInFactor ; zoom min = fitScale * zoomOutFactor.
  static const double zoomInFactor = 4.0;
  static const double zoomOutFactor = 1.0;

  /// Zoom max sur téléphone (la carte y est très réduite, il faut pouvoir zoomer plus).
  static const double zoomInFactorPhone = 8.0;

  /// 📱 Taille MINIMALE (en pixels d'écran) d'un marqueur de ville.
  static const double minMarkerScreenSize = 32.0;
  static const double maxMarkerCounterScale = 8.0;
  static const double minTapScreenSize = 48.0;

  static final bool isPhone = _detectPhone();

  static bool _detectPhone() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return false;
    final v = views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio < 600;
  }

  static const double maxHoverDistance = 40.0;

  // Palette des marqueurs
  static const Color colorStopped = Color(0xFFD500F9);     // Violet : ville visitée (arrêt)
  static const Color colorTraversed = Color(0xFFFFB300);   // Ambre : ville traversée
  static const Color colorReachable = Color(0xFF00E676);   // Vert : destination accessible
  static const Color colorUnreachable = Color(0xFFFF1744); // Rouge : trop loin
}

class RegionDetailScreen extends StatefulWidget {
  final String regionName;
  final int selectedDurationMinutes;
  final bool readOnly;
  
  // ✨ FIX : Ajout des paramètres optionnels de transit
  final List<String>? transitRoute;
  final int? transitRemainingMinutes;

  const RegionDetailScreen({
    super.key,
    required this.regionName,
    this.selectedDurationMinutes = 0,
    this.readOnly = false,
    this.transitRoute,
    this.transitRemainingMinutes,
  });

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _cloudAnimationController;

  Size? _imageSize;
  bool _viewInitialized = false;

  double _fitScale = 1.0;
  String? _hoveredCrossId;
  String? _selectedCrossId;

  Map<String, ShortestPathResult> _routes = {};

  String? _currentCity;
  String _characterId = 'nuit';
  Set<String> _visitedCities = {};
  Set<String> _stoppedCities = {};

  Set<String> _visitedKeys = {};
  Set<String> _stoppedKeys = {};
  Set<String> _visibleKeys = {};

  List<ui.Image>? _cloudSprites;

  // ✨ Variables pour stocker l'état de transit récupéré de Firebase
  int _transitRemainingMinutes = 0;
  List<String> _transitRoute = [];

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();

    _cloudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: FogSettings.cycleSeconds),
    )..repeat();

    CloudSprites.generate().then((s) {
      if (!mounted) {
        for (final img in s) {
          img.dispose();
        }
        return;
      }
      setState(() => _cloudSprites = s);
    });

    _loadImageDimensions();
    _loadUserData();
  }

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
      default:
        return false;
    }
  }

  String _resolveNetworkCityName(String rawName) {
    if (CityNetwork.network.containsKey(rawName)) return rawName;
    final norm = normalizeCityName(rawName);
    for (final key in CityNetwork.network.keys) {
      if (normalizeCityName(key) == norm) return key;
    }
    return rawName;
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    final visitedDoc = await userRef.collection('visited_cities').get();
    final stoppedDoc = await userRef.collection('stopped_cities').get();

    if (mounted) {
      setState(() {
        _currentCity = userDoc.data()?['currentCity'] as String?;
        _characterId = userDoc.data()?['characterId'] as String? ?? 'nuit';
        
        // ✨ Récupération des infos de transit en cours depuis Firebase
        _transitRemainingMinutes = userDoc.data()?['transitRemainingMinutes'] ?? 0;
        _transitRoute = List<String>.from(userDoc.data()?['transitRoute'] ?? []);

        _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();
        _stoppedCities = stoppedDoc.docs.map((d) => d.id).toSet();

        _visitedKeys = _visitedCities.map((c) => normalizeCityName(c)).toSet();
        _stoppedKeys = _stoppedCities.map((c) => normalizeCityName(c)).toSet();

        final Set<String> allKnownNetworkNames = {
          ..._visitedCities.map(_resolveNetworkCityName),
          ..._stoppedCities.map(_resolveNetworkCityName),
        };

        // ✨ Si on est en transit, le point de départ pour calculer la suite est la dernière ville visée
        final String? resolvedCurrent = (_transitRoute.isNotEmpty)
            ? _resolveNetworkCityName(_transitRoute.last)
            : (_currentCity != null ? _resolveNetworkCityName(_currentCity!) : null);

        final Set<String> visibleCities = CityNetwork.getVisibleCities(
          currentCity: resolvedCurrent,
          knownCities: allKnownNetworkNames,
        );
        _visibleKeys = visibleCities.map((c) => normalizeCityName(c)).toSet();

        if (resolvedCurrent != null) {
          _routes = CityNetwork.calculateAllShortestPaths(
            startCity: resolvedCurrent,
            visitedCities: allKnownNetworkNames,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cloudAnimationController.dispose();
    for (final s in _cloudSprites ?? const <ui.Image>[]) {
      s.dispose();
    }
    super.dispose();
  }

  String _getImageAsset(String regionName) {
    switch (regionName) {
      case 'desert': return 'assets/biome/desert.png';
      case 'montagnes': return 'assets/biome/montagnes.png';
      case 'nuit': return 'assets/biome/nuit.png';
      case 'nuages': return 'assets/biome/nuages.png';
      case 'lac': return 'assets/biome/lac.png';
      default: return 'assets/biome/fond1.png';
    }
  }

  void _loadImageDimensions() {
    final String assetPath = _getImageAsset(widget.regionName);
    final ImageStream stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);

    stream.addListener(ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (!mounted) return;
      setState(() {
        _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      });
    }));
  }

  void _setupInitialView(Size screenSize) {
    if (_imageSize == null) return;

    final double imgWidth = _imageSize!.width;
    final double imgHeight = _imageSize!.height;

    final double fitScale = math.min(
      screenSize.width / imgWidth,
      screenSize.height / imgHeight,
    );

    _fitScale = fitScale;

    final double scaledWidth = imgWidth * fitScale;
    final double scaledHeight = imgHeight * fitScale;
    final double dx = (screenSize.width - scaledWidth) / 2;
    final double dy = (screenSize.height - scaledHeight) / 2;

    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(fitScale);
  }

  bool get _hasFocusPlanned => widget.selectedDurationMinutes > 0 || widget.selectedDurationMinutes == -1;

  ShortestPathResult? _routeFor(RegionCross cross) {
    if (_routes.containsKey(cross.name)) return _routes[cross.name];
    final key = normalizeCityName(cross.name);
    for (final entry in _routes.entries) {
      if (normalizeCityName(entry.key) == key) return entry.value;
    }
    return null;
  }

  bool _isCurrentCity(RegionCross cross) {
    if (_currentCity == null) return false;
    return normalizeCityName(cross.name) == normalizeCityName(_currentCity!);
  }

  bool _isStopped(RegionCross cross) {
    return _stoppedKeys.contains(normalizeCityName(cross.name));
  }

  bool _isTraversed(RegionCross cross) {
    return _visitedKeys.contains(normalizeCityName(cross.name));
  }

  bool _isVisibleOutOfFog(RegionCross cross) {
    if (_isCurrentCity(cross) || _isStopped(cross) || _isTraversed(cross)) return true;
    if (widget.readOnly) return false;
    return _visibleKeys.contains(normalizeCityName(cross.name));
  }

  /// Vrai si cette ville est la destination d'un trajet déjà en cours (transit).
  bool _isTransitTarget(RegionCross cross) {
    return _transitRoute.isNotEmpty &&
        normalizeCityName(cross.name) == normalizeCityName(_transitRoute.last);
  }

  // Une destination est atteignable dès qu'un itinéraire existe, qu'une durée
  // ait déjà été choisie ou non (sans durée, FocusScreen la demandera ensuite).
  bool _isReachable(RegionCross cross) {
    if (_isCurrentCity(cross)) return false;

    final route = _routeFor(cross);
    if (route == null) return false;

    return true;
  }

  void _handleHoverPosition(Offset localPosition, List<RegionCross> crosses) {
    if (_selectedCrossId != null) return;

    String? closestId;
    double closestDistance = double.infinity;

    for (final cross in crosses) {
      if (!_isVisibleOutOfFog(cross)) continue;

      final double dx = cross.x - localPosition.dx;
      final double dy = cross.y - localPosition.dy;
      final double distance = math.sqrt(dx * dx + dy * dy);

      if (distance <= MapSettings.maxHoverDistance && distance < closestDistance) {
        closestDistance = distance;
        closestId = cross.id;
      }
    }

    if (closestId != _hoveredCrossId) {
      setState(() {
        _hoveredCrossId = closestId;
      });
    }
  }

  void _clearHover() {
    if (_hoveredCrossId != null) {
      setState(() {
        _hoveredCrossId = null;
      });
    }
  }

  void _navigateToCross(RegionCross cross) {
    if (widget.readOnly) return;

    final route = _routeFor(cross);
    final bool isTransitTarget = _isTransitTarget(cross);

    // La destination du trajet en cours est toujours sélectionnable (même sans
    // nouvel itinéraire) ; sinon il faut une route calculée.
    if (!isTransitTarget && (!_isReachable(cross) || route == null)) return;
    HapticFeedback.lightImpact();

    List<String> finalRoute;
    int finalTravelMinutes;

    if (_transitRoute.isNotEmpty) {
      // Trajet déjà en cours : on conserve l'itinéraire et le temps restant,
      // et on y ajoute la nouvelle portion (sans dupliquer l'étape de jonction).
      final List<String> extra = (isTransitTarget || route == null)
          ? <String>[]
          : List<String>.from(route.path);
      if (extra.isNotEmpty &&
          normalizeCityName(extra.first) == normalizeCityName(_transitRoute.last)) {
        extra.removeAt(0);
      }
      finalRoute = [..._transitRoute, ...extra];
      finalTravelMinutes =
          _transitRemainingMinutes + ((isTransitTarget || route == null) ? 0 : route.totalTravelMinutes);
    } else {
      finalRoute = List<String>.from(route!.path);
      finalTravelMinutes = route.totalTravelMinutes;
    }

    if (_hasFocusPlanned) {
      // Durée déjà choisie (> 0) ou mode admin (-1) : on lance directement
      // l'expédition vers la destination sélectionnée, sans redemander la durée.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveTimerScreen(
            durationMinutes: widget.selectedDurationMinutes,
            plannedTravelMinutes: finalTravelMinutes,
            plannedRoute: finalRoute,
          ),
        ),
      );
      return;
    }

    // Aucune durée choisie (carte ouverte depuis l'accueil) : on la demande.
    // `routeAlreadyChosen` évite que FocusScreen renvoie vers la carte.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          transitRoute: finalRoute,
          transitRemainingMinutes: finalTravelMinutes,
          routeAlreadyChosen: true,
        ),
      ),
    );
  }

  Widget _buildCityMarker(RegionCross cross) {
    final bool isCurrent = _isCurrentCity(cross);
    if (isCurrent) return const SizedBox.shrink();

    if (!_isVisibleOutOfFog(cross)) {
      return const SizedBox.shrink();
    }

    final bool isStopped = _isStopped(cross);
    final bool isTraversed = _isTraversed(cross);
    final bool isReachable = !widget.readOnly && _isReachable(cross);
    final bool isSelected = _selectedCrossId == cross.id;

    if (!_hasFocusPlanned) {
      if (!isStopped && !isTraversed) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF12121C).withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 1.5),
          ),
          child: const Icon(Icons.question_mark_rounded, size: 15, color: Colors.white70),
        );
      }
    }

    Color markerColor;
    IconData markerIcon;
    bool isUnreachableCross = false;

    if (_hasFocusPlanned && !isReachable) {
      markerColor = MapSettings.colorUnreachable;
      markerIcon = Icons.close_rounded;
      isUnreachableCross = true;
    } else if (isStopped) {
      markerColor = MapSettings.colorStopped;
      markerIcon = Icons.home_rounded;
    } else if (isTraversed) {
      markerColor = MapSettings.colorTraversed;
      markerIcon = Icons.star_rounded;
    } else {
      markerColor = MapSettings.colorReachable;
      markerIcon = Icons.navigation_rounded;
    }

    final double baseSize = math.max(cross.size * 1.3, 34.0);
    final double finalSize = isSelected ? baseSize * 1.25 : baseSize;

    if (isUnreachableCross) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: finalSize * 0.9,
        height: finalSize * 0.9,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF12121C).withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(
            color: MapSettings.colorUnreachable.withValues(alpha: 0.9),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: MapSettings.colorUnreachable.withValues(alpha: 0.4),
              blurRadius: 6.0,
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: finalSize * 0.6,
          color: MapSettings.colorUnreachable,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: finalSize,
      height: finalSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF12121C).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : markerColor,
          width: isSelected ? 3.0 : 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: markerColor.withValues(alpha: isSelected ? 0.9 : 0.65),
            blurRadius: isSelected ? 16.0 : 10.0,
            spreadRadius: isSelected ? 4.0 : 2.0,
          ),
          if (_hasFocusPlanned && isReachable && (isStopped || isTraversed))
            BoxShadow(
              color: MapSettings.colorReachable.withValues(alpha: 0.5),
              blurRadius: 12.0,
              spreadRadius: 3.0,
            ),
        ],
      ),
      child: Icon(
        markerIcon,
        size: finalSize * 0.55,
        color: markerColor,
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF12121C),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<RegionTitleReveal> regionTitles =
        FogSettings.titleReveals[widget.regionName] ?? const <RegionTitleReveal>[];

    const darkBlue = Color(0xFF143063);
    final List<RegionCross> regionCrosses = RegionCrossesData.crossesByRegion[widget.regionName] ?? [];
    final String? activeCrossId = _selectedCrossId ?? _hoveredCrossId;

    final List<FogRevealArea> revealAreas = [];
    for (final cross in regionCrosses) {
      if (_isCurrentCity(cross) || _isStopped(cross) || _isTraversed(cross)) {
        revealAreas.add(FogRevealArea(
          center: Offset(cross.x, cross.y),
          radius: FogSettings.visitedRevealRadius,
        ));
      } else if (_isVisibleOutOfFog(cross)) {
        revealAreas.add(FogRevealArea(
          center: Offset(cross.x, cross.y),
          radius: FogSettings.frontierRevealRadius,
        ));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/biome/fond_de_zoom.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: _imageSize == null
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);

                      if (!_viewInitialized) {
                        _viewInitialized = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _setupInitialView(screenSize);
                          });
                        });
                      }

                      final double imgWidth = _imageSize!.width;
                      final double imgHeight = _imageSize!.height;

                      final double minScale = _fitScale * MapSettings.zoomOutFactor;
                      final double maxScale = _fitScale * MapSettings.zoomInFactor;

                      final double horizontalMargin = math.max(0.0, (screenSize.width - (imgWidth * minScale)) / (2 * minScale));
                      final double verticalMargin = math.max(0.0, (screenSize.height - (imgHeight * minScale)) / (2 * minScale));

                      final bool isAdminMode = widget.selectedDurationMinutes == -1;

                      final List<Widget> mapStackChildren = [
                        RepaintBoundary(
                          child: Image.asset(
                            _getImageAsset(widget.regionName),
                            width: imgWidth,
                            height: imgHeight,
                            fit: BoxFit.fill,
                          ),
                        ),

                        if (!isAdminMode)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _cloudAnimationController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: Size(imgWidth, imgHeight),
                                      painter: FogOfWarPainter(
                                        revealAreas: revealAreas,
                                        titleReveals: regionTitles,
                                        animationValue: _cloudAnimationController.value,
                                        sprites: _cloudSprites,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        if (activeCrossId != null)
                          ...regionCrosses
                              .where((c) => c.id == activeCrossId && _isVisibleOutOfFog(c) && c.imagePath != null && c.imageX != null && c.imageY != null)
                              .map((cross) => Positioned(
                                    left: cross.imageX,
                                    top: cross.imageY,
                                    child: RepaintBoundary(
                                      child: IgnorePointer(
                                        child: Image.asset(
                                          cross.imagePath!,
                                          width: imgWidth,
                                          height: imgHeight,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                    ),
                                  )),

                        ...regionCrosses.where(_isVisibleOutOfFog).map((cross) {
                          final double clickAreaSize = math.max(cross.size, 80.0);

                          return Positioned(
                            left: cross.x - (clickAreaSize / 2),
                            top: cross.y - (clickAreaSize / 2),
                            child: RepaintBoundary(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (_selectedCrossId == cross.id) {
                                      _selectedCrossId = null;
                                    } else {
                                      _selectedCrossId = cross.id;
                                      _hoveredCrossId = null;
                                    }
                                  });
                                },
                                child: SizedBox(
                                  width: clickAreaSize,
                                  height: clickAreaSize,
                                  child: Center(
                                    child: _buildCityMarker(cross),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Personnage : taille et animation gérées par SpriteConfig
                        if (_currentCity != null)
                          ...regionCrosses
                              .where((c) => _isCurrentCity(c))
                              .map((cross) {
                              final Size s = SpriteConfig.character(SpriteScene.region);
                              return Positioned(
                                key: const ValueKey('player_position'),
                                left: cross.x - s.width / 2,
                                top: cross.y - s.height * SpriteConfig.footRatio,
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CharacterSprite(
                                    characterId: _characterId,
                                    scene: SpriteScene.region,
                                  ),
                                ),
                              ),
                            );
                          }),
                      ];

                      return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _controller,
                            constrained: false,
                            boundaryMargin: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                              vertical: verticalMargin,
                            ),
                            minScale: minScale,
                            maxScale: maxScale,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_selectedCrossId != null) {
                                  setState(() {
                                    _selectedCrossId = null;
                                  });
                                }
                              },
                              child: SizedBox(
                                width: imgWidth,
                                height: imgHeight,
                                child: _isDesktopOrWeb
                                    ? MouseRegion(
                                        onHover: (event) =>
                                            _handleHoverPosition(event.localPosition, regionCrosses),
                                        onExit: (_) => _clearHover(),
                                        child: Stack(children: mapStackChildren),
                                      )
                                    : Stack(children: mapStackChildren),
                              ),
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
                                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back_ios_new, color: darkBlue),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF12121C).withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildLegendItem(MapSettings.colorStopped, Icons.home_rounded, 'Visitée (Arrêt)'),
                                          _buildLegendItem(MapSettings.colorTraversed, Icons.star_rounded, 'Traversée'),
                                          if (!_hasFocusPlanned)
                                            _buildLegendItem(Colors.white70, Icons.question_mark_rounded, 'À découvrir'),
                                          if (_hasFocusPlanned) ...[
                                            _buildLegendItem(MapSettings.colorReachable, Icons.navigation_rounded, 'Accessible'),
                                            _buildLegendItem(MapSettings.colorUnreachable, Icons.close_rounded, 'Trop loin'),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Builder(
                                  builder: (context) {
                                    final selectedCrossObj = regionCrosses.where((c) => c.id == _selectedCrossId).firstOrNull;
                                    if (selectedCrossObj == null) return const SizedBox.shrink();

// ✨ FIX : Vérifie si c'est la ville vers laquelle on est déjà en route
                                    final bool isCurrentTarget = _isTransitTarget(selectedCrossObj);

// Si c'est notre cible actuelle en transit, on autorise l'accès pour relancer du temps dessus !
                                    final bool canGo = _isReachable(selectedCrossObj) || isCurrentTarget;
                                    final bool isStopped = _isStopped(selectedCrossObj);
                                    final bool isTraversed = _isTraversed(selectedCrossObj);
                                    final route = _routeFor(selectedCrossObj);

                                    String statusText = 'Zone frontalière inconnue';
                                    Color statusColor = Colors.white70;
                                    
                                    final bool willCampOnRoad = canGo && route != null && widget.selectedDurationMinutes > 0 && route.totalTravelMinutes > widget.selectedDurationMinutes;



                                    if (isCurrentTarget) {
                                      statusText = '⛺ Destination actuelle de ton expédition';
                                      statusColor = const Color(0xFFFFB300); // Ambre
                                    } else if (isStopped) {
                                      statusText = '🏕️ Ville déjà visitée';
                                      statusColor = MapSettings.colorStopped;
                                    } else if (isTraversed) {
                                      statusText = '✨ Ville déjà traversée';
                                      statusColor = MapSettings.colorTraversed;
                                    } else if (canGo) {
                                      if (!_hasFocusPlanned) {
                                        statusText = '🧭 Tu choisiras ta durée à l\'étape suivante';
                                        statusColor = MapSettings.colorReachable;
                                      } else if (willCampOnRoad) {
                                        statusText = '⛺ Trajet long : campement en chemin';
                                        statusColor = const Color(0xFFFFB300);
                                      } else {
                                        statusText = '🧭 Destination accessible en une fois';
                                        statusColor = MapSettings.colorReachable;
                                      }
                                    } else if (_hasFocusPlanned) {
                                      statusText = '🔒 Bloquée par une zone inconnue';
                                      statusColor = MapSettings.colorUnreachable;
                                    }

                                    // ✨ Calcul du trajet total cumulé (transit restant + nouveau trajet)
                                  int totalDisplayMinutes = route != null ? route.totalTravelMinutes : 0;
                                    if (isCurrentTarget && route == null) {
                                      totalDisplayMinutes = 0; // Aucun temps supplémentaire si on clique sur notre propre étape actuelle
                                    }
                                    if (_transitRoute.isNotEmpty) {
                                      totalDisplayMinutes += _transitRemainingMinutes;
                                    }

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 420),
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF12121C).withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      selectedCrossObj.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if (canGo && (route != null || isCurrentTarget)) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        // ✨ Affichage du temps total cumulé
                                                        'Trajet total : ${formatMinutesToHours(totalDisplayMinutes)}',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (!widget.readOnly && (_hasFocusPlanned || canGo)) ...[
                                                const SizedBox(width: 12),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: canGo ? const Color(0xFFFF8C00) : Colors.grey.shade800,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    elevation: canGo ? 6 : 0,
                                                  ),
                                                  icon: Icon(canGo ? Icons.navigation_rounded : Icons.lock_rounded, size: 18),
                                                  label: Text(
                                                    canGo ? 'Y aller !' : 'Bloqué',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                  onPressed: canGo ? () => _navigateToCross(selectedCrossObj) : null,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
