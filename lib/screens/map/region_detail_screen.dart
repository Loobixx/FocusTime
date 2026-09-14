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

  double _fitScale = 1.0;
  String? _hoveredCrossId;
  
  // ✨ NOUVEAU : On retient l'ID de la croix qui est cliquée pour afficher son image
  String? _selectedCrossId; 
  
  Set<String> _visitedCities = {};

  static const double _zoomInFactor = 4.0;
  static const double _zoomOutFactor = 1;

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
      case 'desert': return 'Sahur';
      case 'montagnes': return 'Orane';
      case 'nuit': return 'Vallée Nocturne';
      case 'nuages': return 'Valoris';
      case 'lac': return 'Nayris';
      default: return regionName;
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
      ..translate(dx, dy)
      ..scale(fitScale);
  }

  void _resetZoom(Size screenSize) {
    setState(() {
      _setupInitialView(screenSize);
      _selectedCrossId = null; // On cache l'image si on dézoome
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
                              child: Stack(
                                children: [
                                  // COUCHE 1 : La carte de fond
                                  Image.asset(
                                    _getImageAsset(widget.regionName),
                                    width: imgWidth,
                                    height: imgHeight,
                                    fit: BoxFit.fill,
                                  ),
                                  
                                  // COUCHE 2 : L'image de la ville (Affichée DERRIÈRE les croix)
                                  if (_selectedCrossId != null)
                                    ...regionCrosses
                                        .where((c) => c.id == _selectedCrossId && c.imagePath != null && c.imageX != null && c.imageY != null)
                                        .map((cross) => Positioned(
                                              left: cross.imageX,
                                              top: cross.imageY,
                                              child: GestureDetector(
                                                onTap: () {
                                                  if (widget.selectedDurationMinutes == 0) return;
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
                                                child: Image.asset(
                                                  cross.imagePath!,
                                                  width: imgWidth,
                                                  height: imgHeight,
                                                ),
                                              ),
                                            )),

                                  // COUCHE 3 : Toutes les croix (Affichées TOUT DEVANT)
                                  ...regionCrosses.map((cross) {
                                    final bool isHovered = _hoveredCrossId == cross.id;
                                    
                                    // 1. La taille du visuel (le petit cercle)
                                    final double visualSize = isHovered ? cross.size * 1.3 : cross.size;
                                    
                                    // 2. La taille de la zone cliquable (fixée à 60x60 minimum pour les gros doigts !)
                                    final double clickAreaSize = math.max(visualSize, 50.0);

                                    // 3. Ta fonction magique pour choisir la couleur selon l'ID
                                    Color getAuraColor(String id) {
                                      switch (id) {
                                        case 'm1': return Colors.blue.withValues(alpha: 0.6);   // Exemple : Bleu pour le port
                                        case 'm2': return Colors.orange.withValues(alpha: 0.6); // Exemple : Orange pour la cité
                                        case 'm3': return Colors.cyan.withValues(alpha: 0.6);   // Exemple : Cyan pour le bain
                                        
                                        // Par défaut, l'aura est totalement transparente (invisible) !
                                        default: return Colors.transparent; 
                                      }
                                    }

                                    return Positioned(
                                      // On centre la position par rapport à la GRANDE zone cliquable
                                      left: cross.x - (clickAreaSize / 2),
                                      top: cross.y - (clickAreaSize / 2),
                                      child: GestureDetector(
                                        // IMPORTANT : Ceci permet de cliquer même si le fond est transparent !
                                        behavior: HitTestBehavior.opaque, 
                                        onTapDown: (_) => setState(() => _hoveredCrossId = cross.id),
                                        onTapCancel: () => setState(() => _hoveredCrossId = null),
                                        onTapUp: (_) {
                                          setState(() {
                                            _hoveredCrossId = null;
                                            if (_selectedCrossId == cross.id) {
                                              _selectedCrossId = null; // Ferme l'image
                                            } else {
                                              _selectedCrossId = cross.id; // Ouvre l'image
                                            }
                                          });
                                        },
                                        // La grande boîte cliquable
                                        child: SizedBox(
                                          width: clickAreaSize,
                                          height: clickAreaSize,
                                          child: Center(
                                            // Le visuel (l'aura) qui reste à sa petite taille d'origine
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              width: visualSize,
                                              height: visualSize,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: getAuraColor(cross.id), // Appelle ta fonction ici !
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
                                                  color: Colors.transparent, // La croix elle-même reste invisible
                                                ),
                                              ),
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