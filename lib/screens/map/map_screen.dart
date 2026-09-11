import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FocusTime/screens/map/map_region_data.dart';
import 'package:FocusTime/screens/map/region_detail_screen.dart';
// Importation du fichier des coordonnées

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRegionId; 
  String? _hoveredRegionId; 
  bool _debugShowZones = false; 

  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // On récupère directement les régions depuis le fichier externe
  final List<RegionShape> _regions = MapRegionsData.regions;


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
        builder: (context) => RegionDetailScreen(regionName: regionId),
      ),
    );
  }

  String? get _displayedName {
    final id = _hoveredRegionId ?? _selectedRegionId;
    if (id == null) return null;
    return _regions.firstWhere((r) => r.id == id).name;
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // On utilise directement la taille de base de l'image comme référence fixe (1023x1537)
                // L'InteractiveViewer permettra de zoomer et de se déplacer librement dessus.
                const double baseWidth = 1023.0;
                const double baseHeight = 1537.0;

                // Le zoom minimum garantit que l'image couvre toujours tout l'écran
                final double minScaleToCover = math.max(
                  constraints.maxWidth / baseWidth,
                  constraints.maxHeight / baseHeight,
                );

                // Pas besoin de recalculer un scale complexe, les chemins correspondent déjà à 1023x1537 !
                final scaledRegions = _regions; // On utilise directement _regions sans multiplier par un scale externe

                return InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false, 
                  boundaryMargin: EdgeInsets.zero,
                  minScale: minScaleToCover,
                  maxScale: math.max(minScaleToCover * 3, 3.5),
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
                        child: CustomPaint(
                          foregroundPainter: MapPainter(
                            regions: scaledRegions,
                            selectedRegionId: _selectedRegionId,
                            hoveredRegionId: _hoveredRegionId,
                            debugShowAll: _debugShowZones,
                          ),
                          child: Image.asset(
                            'assets/map_global.png',
                            width: baseWidth,
                            height: baseHeight,
                            fit: BoxFit.fill,
                          ),
                        ),
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

          // Bouton debug
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton.small(
                  heroTag: 'debug',
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  onPressed: () =>
                      setState(() => _debugShowZones = !_debugShowZones),
                  child: const Text('🐞'),
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

/// -----------------------------------------------------------------------
/// PAINTER
/// -----------------------------------------------------------------------
class MapPainter extends CustomPainter {
  final List<RegionShape> regions;
  final String? selectedRegionId;
  final String? hoveredRegionId;
  final bool debugShowAll;

  MapPainter({
    required this.regions,
    this.selectedRegionId,
    this.hoveredRegionId,
    this.debugShowAll = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final bool isHovered = region.id == hoveredRegionId;
      final bool isSelected = region.id == selectedRegionId;

      if (debugShowAll) {
        final debugFill = Paint()
          ..color = region.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        final debugStroke = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(region.path, debugFill);
        canvas.drawPath(region.path, debugStroke);
      }

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
        oldDelegate.debugShowAll != debugShowAll ||
        oldDelegate.regions != regions;
  }
}
