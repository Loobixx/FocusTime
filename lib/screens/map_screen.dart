import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// -----------------------------------------------------------------------
/// MODELE DE ZONE
/// -----------------------------------------------------------------------
class RegionShape {
  final String id;
  final String name;
  final Color color;
  final Path path;

  RegionShape({
    required this.id,
    required this.name,
    required this.color,
    required this.path,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRegionId; // tap (mobile) -> 2e tap ouvre le détail
  String? _hoveredRegionId; // hover souris (desktop/web)
  bool _debugShowZones = false; // affiche tous les contours pour calibrer

  late final TransformationController _transformationController;

  // Dimensions RÉELLES de assets/map_global.png
  static const Size _baseMapSize = Size(1023, 1537);

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

  // ---------------------------------------------------------------------
  // ZONES — coordonnées ESTIMÉES sur la base de 1023x1537.
  // Utilise le bouton 🐞 (mode debug) pour visualiser ces contours
  // par-dessus la vraie carte et ajuster les points si besoin.
  // ---------------------------------------------------------------------
  final List<RegionShape> _regions = [
    RegionShape(
      id: 'desert',
      name: 'Terres du Désert',
      color: const Color(0xFFE8C468),
      path: Path()
        ..moveTo(300, 330)
        ..lineTo(350, 360)
        ..lineTo(385, 420)
        ..lineTo(392, 500)
        ..lineTo(382, 580)
        ..lineTo(392, 650)
        ..lineTo(372, 700)
        ..lineTo(330, 725)
        ..lineTo(275, 735)
        ..lineTo(220, 685)
        ..lineTo(190, 605)
        ..lineTo(178, 520)
        ..lineTo(183, 440)
        ..lineTo(202, 380)
        ..lineTo(242, 340)
        ..close(),
    ),
    RegionShape(
      id: 'lac',
      name: 'Monde de l\'Eau',
      color: const Color(0xFF3FA9C9),
      path: Path()
        ..moveTo(195, 705)
        ..lineTo(285, 720)
        ..lineTo(350, 745)
        ..lineTo(400, 800)
        ..lineTo(422, 900)
        ..lineTo(400, 1005)
        ..lineTo(365, 1085)
        ..lineTo(315, 1155)
        ..lineTo(265, 1180)
        ..lineTo(218, 1150)
        ..lineTo(193, 1080)
        ..lineTo(183, 1000)
        ..lineTo(188, 900)
        ..close(),
    ),
    RegionShape(
      id: 'nuit',
      name: 'Royaume de la Nuit',
      color: const Color(0xFF16215C),
      path: Path()
        ..moveTo(430, 560)
        ..lineTo(500, 520)
        ..lineTo(600, 500)
        ..lineTo(700, 512)
        ..lineTo(800, 542)
        ..lineTo(880, 565)
        ..lineTo(910, 605)
        ..lineTo(895, 655)
        ..lineTo(850, 755)
        ..lineTo(820, 855)
        ..lineTo(795, 955)
        ..lineTo(700, 1005)
        ..lineTo(600, 985)
        ..lineTo(520, 905)
        ..lineTo(480, 805)
        ..lineTo(450, 700)
        ..close(),
    ),
    RegionShape(
      id: 'nuages',
      name: 'Les Nuages Féeriques',
      color: const Color(0xFFE79ACB),
      path: Path()
        ..moveTo(585, 340)
        ..lineTo(620, 290)
        ..lineTo(700, 270)
        ..lineTo(780, 300)
        ..lineTo(860, 330)
        ..lineTo(895, 380)
        ..lineTo(860, 430)
        ..lineTo(770, 470)
        ..lineTo(700, 480)
        ..lineTo(650, 460)
        ..lineTo(600, 420)
        ..close(),
    ),
    RegionShape(
      id: 'montagnes',
      name: 'Sommets des Montagnes',
      color: const Color(0xFF4F9A5B),
      path: Path()
        ..moveTo(430, 730)
        ..lineTo(480, 700)
        ..lineTo(550, 690)
        ..lineTo(620, 700)
        ..lineTo(680, 720)
        ..lineTo(720, 760)
        ..lineTo(760, 820)
        ..lineTo(780, 900)
        ..lineTo(770, 980)
        ..lineTo(750, 1050)
        ..lineTo(700, 1120)
        ..lineTo(650, 1180)
        ..lineTo(580, 1220)
        ..lineTo(520, 1240)
        ..lineTo(450, 1230)
        ..lineTo(400, 1200)
        ..lineTo(370, 1150)
        ..lineTo(345, 1080)
        ..lineTo(335, 1000)
        ..lineTo(340, 900)
        ..lineTo(360, 820)
        ..lineTo(390, 760)
        ..close(),
    ),
  ];

  List<RegionShape> _scaledRegions(double scale) {
    final matrix = Matrix4.diagonal3Values(scale, scale, 1);
    return _regions
        .map((r) => RegionShape(
              id: r.id,
              name: r.name,
              color: r.color,
              path: r.path.transform(matrix.storage),
            ))
        .toList();
  }

  RegionShape? _regionAt(Offset localPosition, List<RegionShape> scaled) {
    final Matrix4 inverseMatrix =
        Matrix4.copy(_transformationController.value)..invert();
    final Offset pos =
        MatrixUtils.transformPoint(inverseMatrix, localPosition);
    for (var region in scaled) {
      if (region.path.contains(pos)) return region;
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
                final double screenHeight = constraints.maxHeight;
                final double scale = screenHeight / _baseMapSize.height;
                final double displayedWidth = _baseMapSize.width * scale;
                final scaledRegions = _scaledRegions(scale);

                return InteractiveViewer(
                  transformationController: _transformationController,
                  constrained: false, // permet le défilement horizontal
                  boundaryMargin: EdgeInsets.zero,
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: SizedBox(
                    width: displayedWidth,
                    height: screenHeight,
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
                          // foregroundPainter -> dessiné AU-DESSUS de l'image
                          foregroundPainter: MapPainter(
                            regions: scaledRegions,
                            selectedRegionId: _selectedRegionId,
                            hoveredRegionId: _hoveredRegionId,
                            debugShowAll: _debugShowZones,
                          ),
                          child: Image.asset(
                            'assets/map_global.png',
                            width: displayedWidth,
                            height: screenHeight,
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
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
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

          // Bouton debug (calibration des zones)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton.small(
                  heroTag: 'debug',
                  backgroundColor: Colors.white.withOpacity(0.7),
                  onPressed: () =>
                      setState(() => _debugShowZones = !_debugShowZones),
                  child: const Text('🐞'),
                ),
              ),
            ),
          ),

          // Label : nom de la zone survolée / sélectionnée
          if (_displayedName != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: darkBlue.withOpacity(0.85),
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
          ..color = region.color.withOpacity(0.35)
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
          ..color = Colors.white.withOpacity(isSelected ? 0.35 : 0.22)
          ..style = PaintingStyle.fill;
        final highlightStroke = Paint()
          ..color = Colors.white.withOpacity(0.9)
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

/// -----------------------------------------------------------------------
/// ECRAN DE DETAIL
/// -----------------------------------------------------------------------
class RegionDetailScreen extends StatelessWidget {
  final String regionName;
  const RegionDetailScreen({Key? key, required this.regionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/$regionName.png'),
                fit: BoxFit.cover,
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
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
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
        ],
      ),
    );
  }
}