import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class RegionDetailScreen extends StatefulWidget {
  final String regionName;
  const RegionDetailScreen({super.key, required this.regionName});

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> {
  late final TransformationController _controller;
  bool _initialized = false;

  // Dimensions par défaut en attendant le chargement de l'image
  double _imageWidth = 2000.0;
  double _imageHeight = 3000.0;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _loadImageDimensions();
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

  // Récupère dynamiquement la taille réelle de l'image pour éviter les problèmes de dimensions
  void _loadImageDimensions() {
    final String assetPath = _getImageAsset(widget.regionName);
    final ImageStream stream = AssetImage(assetPath).resolve(ImageConfiguration.empty);

    stream.addListener(ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (!mounted) return;
      setState(() {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
        _isImageLoaded = true;
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      body: Stack(
        children: [
          // 1. Fond général (fond_de_zoom.png) qui couvre tout l'écran en arrière-plan
          Positioned.fill(
            child: Image.asset(
              'assets/fond_de_zoom.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Image de zoom interactive par-dessus avec dimensions dynamiques
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double minScaleToCover = math.max(
                  constraints.maxWidth / _imageWidth,
                  constraints.maxHeight / _imageHeight,
                );
                final double maxScale = math.max(minScaleToCover * 4, 5.0);

                // On fixe l'échelle de départ une seule fois dès que l'image est chargée
                if (!_initialized && _isImageLoaded) {
                  _initialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _controller.value = Matrix4.identity()..scale(minScaleToCover);
                  });
                }

                return InteractiveViewer(
                  transformationController: _controller,
                  constrained: false,
                  boundaryMargin: EdgeInsets.zero,
                  minScale: minScaleToCover,
                  maxScale: maxScale,
                  child: SizedBox(
                    width: _imageWidth,
                    height: _imageHeight,
                    child: Image.asset(
                      _getImageAsset(widget.regionName),
                      width: _imageWidth,
                      height: _imageHeight,
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Bouton de retour en haut à gauche
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
        ],
      ),
    );
  }
}