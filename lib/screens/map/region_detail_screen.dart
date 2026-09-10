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

  // Taille réelle de l'image, résolue dynamiquement (plus de valeur codée en dur).
  Size? _imageSize;

  // Échelle de repos (carte entière visible). Sert de référence pour savoir
  // si l'utilisateur a zoomé ou non.
  double _minScaleToContain = 1.0;

  // Le pan (glisser) n'est autorisé que si l'utilisateur a zoomé au-delà
  // de l'échelle de repos — sinon un simple drag ne fait rien.
  bool _panEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    // On récupère l'échelle actuelle depuis la matrice de transformation.
    final double currentScale = _controller.value.getMaxScaleOnAxis();

    // Petite tolérance pour éviter des allers-retours trop sensibles
    // pile à l'échelle minimale.
    final bool shouldEnablePan = currentScale > _minScaleToContain * 1.01;

    if (shouldEnablePan != _panEnabled) {
      setState(() {
        _panEnabled = shouldEnablePan;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    final imageProvider = AssetImage(_getImageAsset(widget.regionName));
    final stream = imageProvider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
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

          // 2. Image de zoom interactive par-dessus
          Positioned.fill(
            child: _imageSize == null
                ? const SizedBox.shrink() // ou un loader le temps de connaître la taille réelle
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double imgWidth = _imageSize!.width;
                      final double imgHeight = _imageSize!.height;

                      // "contain" : on veut que la carte ENTIÈRE soit visible au départ,
                      // donc on prend le MIN des deux ratios (et non le max comme avant).
                      final double minScaleToContain = math.min(
                        constraints.maxWidth / imgWidth,
                        constraints.maxHeight / imgHeight,
                      );

                      final double maxScale = math.max(minScaleToContain * 4, 5.0);

                      if (!_initialized) {
                        _initialized = true;
                        _minScaleToContain = minScaleToContain;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // On centre l'image dans le viewport : on calcule l'espace
                          // restant une fois l'image mise à l'échelle, et on le
                          // répartit en translation X/Y de chaque côté.
                          final double scaledWidth = imgWidth * minScaleToContain;
                          final double scaledHeight = imgHeight * minScaleToContain;
                          final double dx =
                              (constraints.maxWidth - scaledWidth) / 2;
                          final double dy =
                              (constraints.maxHeight - scaledHeight) / 2;

                          _controller.value = Matrix4.identity()
                            ..translate(dx, dy)
                            ..scale(minScaleToContain);
                        });
                      }

                      return InteractiveViewer(
                        transformationController: _controller,
                        constrained: false,
                        boundaryMargin: EdgeInsets.zero,
                        minScale: minScaleToContain,
                        maxScale: maxScale,
                        // Tant que l'utilisateur n'a pas zoommé (échelle == repos),
                        // on bloque le pan pour éviter le "saut" au premier drag.
                        // Le pinch-to-zoom, lui, reste toujours actif.
                        panEnabled: _panEnabled,
                        child: SizedBox(
                          width: imgWidth,
                          height: imgHeight,
                          child: Image.asset(
                            _getImageAsset(widget.regionName),
                            width: imgWidth,
                            height: imgHeight,
                            // fill n'est plus nécessaire : la SizedBox a déjà
                            // le ratio natif de l'image, donc pas de déformation.
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