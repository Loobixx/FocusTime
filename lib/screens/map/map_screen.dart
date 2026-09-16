import 'dart:math' as math;
import 'dart:ui';
import 'package:FocusTime/screens/focus_moment/animated_character.dart';
import 'package:FocusTime/screens/widgets/persistent_animated_character.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FocusTime/screens/map/map_region_data.dart';
import 'package:FocusTime/screens/map/region_detail_screen.dart';
import 'package:FocusTime/screens/map/region_cross_data.dart';

class MapScreen extends StatefulWidget {
  final int selectedDurationMinutes;
  const MapScreen({super.key, this.selectedDurationMinutes = 0});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRegionId;
  String? _hoveredRegionId;
  String? _currentRegionId;

  late final TransformationController _transformationController;
  bool _viewInitialized = false;
  double _fitScale = 1.0;

  static const double baseWidth = 1023.0;
  static const double baseHeight = 1537.0;

  static const double _zoomInFactor = 3.0;
  static const double _zoomOutFactor = 1.0;

  final List<RegionShape> _regions = MapRegionsData.regions;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _loadUserRegion();
  }

  Future<void> _loadUserRegion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String? currentCity = userDoc.data()?['currentCity'] as String?;
    if (currentCity == null) return;

    String? foundRegion;
    for (var entry in RegionCrossesData.crossesByRegion.entries) {
      for (var cross in entry.value) {
        if (cross.name == currentCity) {
          foundRegion = entry.key;
          break;
        }
      }
      if (foundRegion != null) break;
    }

    if (mounted) {
      setState(() {
        _currentRegionId = foundRegion;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
      setState(() => _hoveredRegionId = region?.id);
    }
  }

  void _handleTapUp(TapUpDetails details, List<RegionShape> scaled) {
    final region = _regionAt(details.localPosition, scaled);
    if (region == null) {
      setState(() => _selectedRegionId = null);
      return;
    }
    HapticFeedback.lightImpact();
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

  // ✨ Coordonnées approximatives au centre de chaque région sur la map globale
  Offset? _getRegionCenter(String? regionId) {
    switch (regionId) {
      case 'desert': return const Offset(260, 480);
      case 'lac': return const Offset(310, 720);
      case 'montagnes': return const Offset(550, 900);
      case 'nuit': return const Offset(710, 700);
      case 'nuages': return const Offset(760, 290);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    final playerPosition = _getRegionCenter(_currentRegionId);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fond_de_zoom.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
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

                final double minScale = _fitScale * _zoomOutFactor;
                final double maxScale = _fitScale * _zoomInFactor;

                final scaledRegions = _regions;

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
                        onTapUp: (details) => _handleTapUp(details, scaledRegions),
                        child: Stack(
                          children: [
                            // On isole l'image de fond
                            const RepaintBoundary(
                              child: Image(
                                image: AssetImage('assets/map_global.png'),
                                width: baseWidth,
                                height: baseHeight,
                                fit: BoxFit.fill,
                              ),
                            ),
                            
                            // On isole le survol des territoires
                            RepaintBoundary(
                              child: CustomPaint(
                                size: const Size(baseWidth, baseHeight),
                                painter: MapPainter(
                                  regions: scaledRegions,
                                  selectedRegionId: _selectedRegionId,
                                  hoveredRegionId: _hoveredRegionId,
                                ),
                              ),
                            ),

                            // Le personnage reste tout devant
                            if (playerPosition != null)
                              Positioned(
                                left: playerPosition.dx - 25,
                                top: playerPosition.dy - 50,
                                child: const IgnorePointer(
                                  child: RepaintBoundary( // On isole aussi le personnage
                                    child: PersistentAnimatedCharacter(
                                      size: 120,

                                    frames: [
                                      'assets/PersonnageAnimation/Nuit/Arret/1.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/2.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/3.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/4.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/5.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/6.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/7.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/8.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/9.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/10.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/11.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/12.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/13.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/14.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/15.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/16.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/17.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/18.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/19.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/20.png',
                                      'assets/PersonnageAnimation/Nuit/Arret/21.png',
                                    ],
                                   frameDuration: Duration(milliseconds: 2000),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                                                
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bouton retour
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

          // Label
          if (_displayedName != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: darkBlue.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: Text(
                    _selectedRegionId != null
                        ? '$_displayedName — retape pour explorer !'
                        : _displayedName!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<RegionShape> regions;
  final String? selectedRegionId;
  final String? hoveredRegionId;

  MapPainter({
    required this.regions,
    this.selectedRegionId,
    this.hoveredRegionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final bool isHovered = region.id == hoveredRegionId;
      final bool isSelected = region.id == selectedRegionId;

      // On garde uniquement l'effet discret quand on survole ou sélectionne une région pour l'explorer
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
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.hoveredRegionId != hoveredRegionId ||
        oldDelegate.regions != regions;
  }
}