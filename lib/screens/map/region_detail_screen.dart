import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FocusTime/screens/map/region_cross_data.dart';
import '../select_destination_screen.dart';

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

  // Niveau de zoom "normal" (image ajustée à l'écran), calculé une fois la taille connue
  double _fitScale = 1.0;

  String? _hoveredCrossId;
  Set<String> _visitedCities = {};

  // Facteurs de zoom par rapport au niveau "fit"
  static const double _zoomInFactor = 4.0;   // on peut zoomer jusqu'à 4x le niveau normal
  static const double _zoomOutFactor = 0.25; // on peut dézoomer jusqu'à 1/4 du niveau normal

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _loadImageDimensions();
    _loadVisitedCities();
  }

  Future<void> _loadVisitedCities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final visitedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('visited_cities')
        .get();

    if (mounted) {
      setState(() {
        _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();
      });
    }
  }

  String _getRegionDisplayName(String regionName) {
    switch (regionName) {
      case 'desert':
        return 'Terres du Désert';
      case 'montagnes':
        return 'Pics Enneigés';
      case 'nuit':
        return 'Vallée Nocturne';
      case 'nuages':
        return 'Cité des Nuages';
      case 'lac':
        return 'Rives du Lac';
      default:
        return regionName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getImageAsset(String regionName) {
    switch (regionName) {
      case 'desert':
        return 'assets/desert.png';
      case 'montagnes':
        return 'assets/montagnes.png';
      case 'nuit':
        return 'assets/nuit.png';
      case 'nuages':
        return 'assets/nuages.png';
      case 'lac':
        return 'assets/lac.png';
      default:
        return 'assets/fond1.png';
    }
  }

  void _loadImageDimensions() {
    final String assetPath = _getImageAsset(widget.regionName);
    final ImageStream stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);

    stream.addListener(ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (!mounted) return;
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    }));
  }

  // Calcule le "fit scale" pour une taille d'écran donnée, et centre la vue.
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

  void _resetZoom(Size screenSize) {
    setState(() {
      _setupInitialView(screenSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    final List<RegionCross> regionCrosses = RegionCrossesData.crossesByRegion[widget.regionName] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fond_de_zoom.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: _imageSize == null
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);

                      // On initialise la vue une seule fois, dès que la taille d'écran est connue.
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

                      return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _controller,
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(2000),
                            minScale: minScale,
                            maxScale: maxScale,
                            child: SizedBox(
                              width: imgWidth,
                              height: imgHeight,
                              child: Stack(
                                children: [
                                  Image.asset(
                                    _getImageAsset(widget.regionName),
                                    width: imgWidth,
                                    height: imgHeight,
                                    fit: BoxFit.fill,
                                  ),
                                  ...regionCrosses.map((cross) {
                                    final bool isHovered = _hoveredCrossId == cross.id;
                                    final bool isVisited = _visitedCities.contains(cross.name);
                                    final double currentSize = isHovered ? cross.size * 1.3 : cross.size;

                                    return Positioned(
                                      left: cross.x - (currentSize / 2),
                                      top: cross.y - (currentSize / 2),
                                      child: GestureDetector(
                                        onTapDown: (_) => setState(() => _hoveredCrossId = cross.id),
                                        onTapCancel: () => setState(() => _hoveredCrossId = null),
                                        onTapUp: (_) {
                                          setState(() => _hoveredCrossId = null);
                                          if (widget.selectedDurationMinutes == 0) {
                                            return;
                                          }
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SelectDestinationScreen(
                                                selectedDurationMinutes: widget.selectedDurationMinutes,
                                              ),
                                            ),
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: currentSize,
                                          height: currentSize,
                                          alignment: Alignment.center,
                                          color: Colors.red.withValues(alpha: 0.5),
                                          child: Transform.rotate(
                                            angle: cross.angle * (math.pi / 180),
                                            child: Icon(
                                              Icons.close,
                                              size: currentSize,
                                              color: isVisited ? Colors.green : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
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

                          // Titre de la région
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: darkBlue.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    _getRegionDisplayName(widget.regionName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bouton reset zoom
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
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
                                        icon: const Icon(Icons.zoom_out_map, color: darkBlue),
                                        onPressed: () => _resetZoom(screenSize),
                                      ),
                                    ),
                                  ),
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