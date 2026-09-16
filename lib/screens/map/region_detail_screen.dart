import 'dart:math' as math;
import 'dart:ui';
import 'package:focus_time/screens/widgets/persistent_animated_character.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/screens/map/data/region_cross_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../models/city_network.dart';
import '../focus_moment/active_timer_screen.dart';

class RegionDetailScreen extends StatefulWidget {
  final String regionName;
  final int selectedDurationMinutes;
  const RegionDetailScreen({
    super.key,
    required this.regionName,
    this.selectedDurationMinutes = 0,
  });

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> {
  late final TransformationController _controller;

  Size? _imageSize;
  bool _viewInitialized = false;

  double _fitScale = 1.0;
  String? _hoveredCrossId;  // Survol de la souris (PC)
  String? _selectedCrossId; // Sélection définitive par clic

  Map<String, ShortestPathResult> _routes = {};

  String? _currentCity;
  Set<String> _visitedCities = {};

  static const double _zoomInFactor = 4.0;
  static const double _zoomOutFactor = 1;
  static const double _maxHoverDistance = 40.0;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _loadImageDimensions();
    _loadVisitedCities();
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

  Future<void> _loadVisitedCities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final visitedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('visited_cities')
        .get();

    if (mounted) {
      setState(() {
        _currentCity = userDoc.data()?['currentCity'] as String?;
        _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();

        if (_currentCity != null) {
          _routes = CityNetwork.calculateAllShortestPaths(
            startCity: _currentCity!,
            visitedCities: _visitedCities,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getImageAsset(String regionName) {
    switch (regionName) {
      case 'desert': return 'assets/desert.png';
      case 'montagnes': return 'assets/montagnes.png';
      case 'nuit': return 'assets/nuit.png';
      case 'nuages': return 'assets/nuages.png';
      case 'lac': return 'assets/lac.png';
      default: return 'assets/fond1.png';
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
      ..translateByDouble(dx, dy, 0.0, 0.0)
      ..scaleByDouble(fitScale, fitScale, 1.0, 1.0);
  }

  bool get _hasFocusPlanned => widget.selectedDurationMinutes > 0;

  ShortestPathResult? _routeFor(RegionCross cross) => _routes[cross.name];

  bool _isReachable(RegionCross cross) {
    if (!_hasFocusPlanned) return false;
    if (_currentCity != null && cross.name == _currentCity) return false;
    final route = _routeFor(cross);
    if (route == null) return false;
    return route.totalTravelMinutes <= widget.selectedDurationMinutes;
  }

  void _handleHoverPosition(Offset localPosition, List<RegionCross> crosses) {
    // Si une ville est déjà sélectionnée par clic, on ignore le survol pour ne pas l'écraser
    if (_selectedCrossId != null) return;

    String? closestId;
    double closestDistance = double.infinity;

    for (final cross in crosses) {
      final double dx = cross.x - localPosition.dx;
      final double dy = cross.y - localPosition.dy;
      final double distance = math.sqrt(dx * dx + dy * dy);

      if (distance <= _maxHoverDistance && distance < closestDistance) {
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
    final route = _routeFor(cross);
    if (!_isReachable(cross) || route == null) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTimerScreen(
          plannedRoute: route.path,
          durationMinutes: widget.selectedDurationMinutes,
          plannedTravelMinutes: route.totalTravelMinutes,
        ),
      ),
    );
  }

  Color _getAuraColor(RegionCross c) {
    if (_currentCity != null && c.name == _currentCity) {
      return Colors.transparent;
    }
    if (_visitedCities.contains(c.name)) {
      return const Color(0xFFFFD700).withValues(alpha: 0.8);
    }
    if (_isReachable(c)) {
      return const Color.fromARGB(255, 245, 4, 4).withValues(alpha: 0.7);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    final List<RegionCross> regionCrosses = RegionCrossesData.crossesByRegion[widget.regionName] ?? [];

    // Priorité à la sélection par clic, sinon on prend le survol de la souris
    final String? activeCrossId = _selectedCrossId ?? _hoveredCrossId;

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fond_de_zoom.png', fit: BoxFit.cover),
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

                      final double minScale = _fitScale * _zoomOutFactor;
                      final double maxScale = _fitScale * _zoomInFactor;

                      final double horizontalMargin = math.max(0.0, (screenSize.width - (imgWidth * minScale)) / (2 * minScale));
                      final double verticalMargin = math.max(0.0, (screenSize.height - (imgHeight * minScale)) / (2 * minScale));

                      final List<Widget> mapStackChildren = [
                        // COUCHE 1 : La carte de fond
                        RepaintBoundary(
                          child: Image.asset(
                            _getImageAsset(widget.regionName),
                            width: imgWidth,
                            height: imgHeight,
                            fit: BoxFit.fill,
                          ),
                        ),

                        // COUCHE 2 : L'image de la ville active (basée sur activeCrossId)
                        if (activeCrossId != null)
                          ...regionCrosses
                              .where((c) => c.id == activeCrossId && c.imagePath != null && c.imageX != null && c.imageY != null)
                              .map((cross) => Positioned(
                                    left: cross.imageX,
                                    top: cross.imageY,
                                    child: RepaintBoundary(
                                      child: GestureDetector(
                                        onTap: () => _navigateToCross(cross),
                                        child: Image.asset(
                                          cross.imagePath!,
                                          width: imgWidth,
                                          height: imgHeight,
                                          gaplessPlayback: true,
                                        ),
                                      ),
                                    ),
                                  )),

                        // COUCHE 3 : Les zones cliquables des croix
                        ...regionCrosses.map((cross) {
                          final double visualSize = cross.size;
                          final double clickAreaSize = math.max(visualSize, 80.0);

                          return Positioned(
                            left: cross.x - (clickAreaSize / 2),
                            top: cross.y - (clickAreaSize / 2),
                            child: RepaintBoundary(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (_selectedCrossId == cross.id) {
                                      _selectedCrossId = null; // Désélectionne au second clic
                                    } else {
                                      _selectedCrossId = cross.id; // Sélectionne par clic
                                      _hoveredCrossId = null;
                                    }
                                  });
                                },
                                child: SizedBox(
                                  width: clickAreaSize,
                                  height: clickAreaSize,
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: visualSize,
                                      height: visualSize,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getAuraColor(cross),
                                            blurRadius: 15.0,
                                            spreadRadius: 4.0,
                                          ),
                                        ],
                                      ),
                                      child: Transform.rotate(
                                        angle: cross.angle * (math.pi / 180),
                                        child: Icon(
                                          Icons.close,
                                          size: visualSize,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                         // ✨ LE PERSONNAGE
                        if (_currentCity != null)
                          ...regionCrosses
                              .where((c) => c.name == _currentCity)
                              .map((cross) => Positioned(
                                  key: const ValueKey('player_position'), // ✨ Ajoute une clé ici
                                  left: cross.x - 60,
                                  top: cross.y - 80,
                                  child: IgnorePointer(
                                    child: RepaintBoundary(
                                      child: PersistentAnimatedCharacter(
                                        key: const ValueKey('player_character'), // ✨ ET LA CLÉ MAGIQUE ICI
                                        size: 200,
                                        frames: List.generate(21, (i) => 'assets/PersonnageAnimation/Nuit/Arret/${i + 1}.png'),
                                        frameDuration: const Duration(milliseconds: 2000),
                                      ),
                                    ),
                                  ),
                                )), 
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

                          // Bouton retour en haut à gauche
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

                          // Bouton "Y aller !" en bas à droite
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_hasFocusPlanned) ...[
                                      Builder(
                                        builder: (context) {
                                          final selectedCrossObj = regionCrosses.where((c) => c.id == _selectedCrossId).firstOrNull;
                                          final bool canGo = selectedCrossObj != null && _isReachable(selectedCrossObj);

                                          return AnimatedOpacity(
                                            opacity: canGo ? 1.0 : 0.5,
                                            duration: const Duration(milliseconds: 200),
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: canGo ? const Color(0xFFFF8C00) : Colors.grey,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                                elevation: canGo ? 6 : 0,
                                              ),
                                              icon: const Icon(Icons.navigation, size: 18),
                                              label: const Text('Y aller !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              onPressed: canGo ? () => _navigateToCross(selectedCrossObj) : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
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