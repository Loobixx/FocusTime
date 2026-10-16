import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:focus_time/widgets/persistent_animated_character.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_time/screens/map/data/region_cross_data.dart';
import 'package:focus_time/utils/city_name.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../models/city_network.dart';
import '../../utils/time_formatter.dart';
import '../focus_moment/expedition_screen.dart';

// ============================================================================
//  ☁️  RÉGLAGES DU BROUILLARD / DES NUAGES  (tout se règle ici)
//  ⚠️ Après modification : fais un "Hot Restart" (pas juste Hot Reload),
//     car les nuages sont mis en cache au démarrage.
// ============================================================================
class FogSettings {
  FogSettings._();

  // --------------------------- ANIMATION -----------------------------------
  /// Durée d'un cycle complet (en secondes). Plus grand = nuages plus lents.
  /// 60 = assez vif | 120 = calme (défaut) | 240 = très lent
  static const int cycleSeconds = 120;

  /// Vitesse max d'un nuage (multiplicateur ENTIER, 1 = lent ... 3 = plus rapide).
  /// Doit rester un entier pour que la boucle soit parfaite.
  static const int maxSpeedMultiplier = 3;

  /// Amplitude du léger balancement vertical des nuages (en pixels de la carte).
  /// 0 = les nuages avancent en ligne droite.
  static const double verticalBobAmplitude = 14.0;

  // --------------------------- DENSITÉ -------------------------------------
  /// Un nuage par "densityDivisor" pixels² de carte.
  /// PLUS PETIT = PLUS de nuages (ex: 100000). PLUS GRAND = moins (ex: 250000).
  static const double densityDivisor = 150000;

  /// Limites du nombre de nuages (performances : ne pas dépasser ~60).
  static const int minClouds = 20;
  static const int maxClouds = 48;

  // --------------------------- TAILLE / OPACITÉ ----------------------------
  /// Échelle minimale d'un nuage + variation aléatoire ajoutée.
  /// Taille finale = minScale + random * scaleRange.
  static const double minScale = 1.0;
  static const double scaleRange = 1.4;

  /// Opacité minimale d'un nuage + variation aléatoire (0.0 à 1.0).
  static const double minOpacity = 0.55;
  static const double opacityRange = 0.45;

  // --------------------------- COULEURS ------------------------------------
  /// Voile de base qui cache la carte (le fond du brouillard).
  /// Plus clair / blanc = brouillard plus lumineux. Plus foncé = plus sombre.
  static const Color baseFogColor = Color(0xFFC3CEDC);
  /// Opacité du voile de base (1.0 = carte totalement cachée).
  static const double baseFogAlpha = 0.97;

  /// Ombre du dessous des nuages (bleutée).
  static const Color cloudShadowColor = Color(0xFF8FA0B8);
  static const double cloudShadowAlpha = 0.55;
  /// Corps du nuage.
  static const Color cloudBodyColor = Color(0xFFE8EEF6);
  static const double cloudBodyAlpha = 0.85;
  /// Lumière sur le dessus du nuage.
  static const Color cloudLightColor = Colors.white;
  static const double cloudLightAlpha = 0.8;

  // --------------------------- FORME DES NUAGES ----------------------------
  /// Nombre de formes de nuages différentes générées au démarrage (3 à 6).
  static const int spriteVariants = 4;

  /// Taille (pixels) de l'image de chaque nuage généré.
  static const double spriteWidth = 640;
  static const double spriteHeight = 360;

  /// Nombre de "boules" par nuage : minPuffs à minPuffs + puffsRange.
  /// Plus il y en a, plus le nuage est détaillé et "chou-fleur".
  static const int minPuffs = 16;
  static const int puffsRange = 8;

  /// Rayon d'une boule : minPuffRadius à minPuffRadius + puffRadiusRange.
  static const double minPuffRadius = 42;
  static const double puffRadiusRange = 48;

  /// Flou des boules (en fraction du rayon). Petit = contours nets, grand = doux.
  static const double shadowBlur = 0.45;
  static const double bodyBlur = 0.35;
  static const double lightBlur = 0.30;

  // --------------------------- ZONES DÉGAGÉES ------------------------------
  /// Rayon dégagé autour des villes déjà visitées / traversées / actuelle.
  static const double visitedRevealRadius = 260.0;
  /// Rayon dégagé autour des villes frontalières (à 1 de distance).
  static const double frontierRevealRadius = 170.0;
  /// Multiplicateur appliqué aux deux rayons ci-dessus (trou plus ou moins large).
  static const double revealRadiusMultiplier = 1.3;

  // --------------------------- TITRES DES RÉGIONS --------------------------
  /// Zones OVALES sans nuages pour laisser lire le nom d'une région.
  /// Toutes les valeurs sont en pixels de l'IMAGE de la carte.
  ///   position        = centre de l'ovale
  ///   radiusX         = demi-largeur
  ///   radiusY         = demi-hauteur
  ///   softness        = douceur du bord : 0.0 = bord net | 0.35 = doux (défaut) | 1.0 = très flou
  ///   rotationDegrees = inclinaison de l'ovale (si le titre est penché)
  /// Pour ajouter une région ('lac', 'nuit', ...) copie un bloc.
  ///
  /// 💡 Pour trouver les bonnes valeurs : mets debugTitleZones = true (plus bas),
  ///    l'ovale s'affiche en rouge sur la carte, et un appui long sur la carte
  ///    affiche dans la console les coordonnées du point touché.
  static const Map<String, List<RegionTitleReveal>> titleReveals = {
    'montagnes': [
      RegionTitleReveal(
        position: Offset(1150.0, 140.0), // "Orane"
        radiusX: 300.0,
        radiusY: 150.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
    'desert': [
      RegionTitleReveal(
        position: Offset(760.0, 1450.0), // "Sahur"
        radiusX: 330.0,
        radiusY: 150.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
    'lac': [
      RegionTitleReveal(
        position: Offset(300.0, 200.0), // "Nayris"
        radiusX: 330.0,
        radiusY: 150.0,
        softness: 0.35,
        rotationDegrees: 0,
      ),
    ],
  };

  /// true = affiche le contour rouge des ovales de titres + coordonnées en
  /// appui long (console). À remettre sur false une fois les zones réglées.
  static const bool debugTitleZones = false;

  // --------------------------- TÉLÉPHONE 📱 ---------------------------------
  // Détecté automatiquement (écran dont le petit côté < 600 px logiques).

  /// Images par seconde du mouvement des nuages (0 = pas de limite).
  /// Les nuages bougent très lentement : 30 fps est invisible à l'œil
  /// mais divise le travail du GPU/CPU par deux sur téléphone.
  static const int desktopFps = 60;
  static const int phoneFps = 30;

  /// Sur téléphone : multiplicateur du nombre de nuages (0.6 = 40 % de moins).
  static const double phoneDensityMultiplier = 0.6;

  /// Sur téléphone : résolution des sprites de nuages (0.5 = moitié moins de pixels).
  /// Les nuages sont flous, la différence ne se voit pas, mais c'est bien plus léger.
  static const double phoneSpriteQuality = 0.5;

  static int get cloudFps => MapSettings.isPhone ? phoneFps : desktopFps;
  static double get spriteQuality => MapSettings.isPhone ? phoneSpriteQuality : 1.0;
  static double get densityFactor => MapSettings.isPhone ? phoneDensityMultiplier : 1.0;
  static FilterQuality get filterQuality =>
      MapSettings.isPhone ? FilterQuality.low : FilterQuality.medium;
}

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
  /// Si la carte est dézoomée, les marqueurs sont agrandis pour rester lisibles.
  /// 0 = désactivé (les marqueurs rétrécissent avec la carte).
  static const double minMarkerScreenSize = 32.0;

  /// Agrandissement maximum appliqué à un marqueur pour atteindre cette taille.
  static const double maxMarkerCounterScale = 8.0;

  /// Zone tactile minimale (en pixels d'écran) autour d'un marqueur.
  /// ~44-48 est la taille recommandée pour un doigt.
  static const double minTapScreenSize = 48.0;

  /// true sur téléphone (petit côté de l'écran < 600 px logiques).
  static final bool isPhone = _detectPhone();

  static bool _detectPhone() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return false;
    final v = views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio < 600;
  }

  /// Distance max (px) de la souris pour survoler une ville (desktop / web).
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
  const RegionDetailScreen({
    super.key,
    required this.regionName,
    this.selectedDurationMinutes = 0,
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
  Set<String> _visitedCities = {};
  Set<String> _stoppedCities = {};

  // Clés normalisées pour éviter tout bug d'accent ou de majuscule
  Set<String> _visitedKeys = {};
  Set<String> _stoppedKeys = {};
  Set<String> _visibleKeys = {}; // Villes hors du brouillard (Connues + 1 de distance)

  // Sprites de nuages pré-rendus (générés une seule fois)
  List<ui.Image>? _cloudSprites;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();

    // Animation des nuages en boucle (durée réglable dans FogSettings)
    _cloudAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: FogSettings.cycleSeconds),
    )..repeat();

    // Génération des nuages (une seule fois)
    CloudSprites.generate().then((s) {
      if (!mounted) {
        for (final img in s) {
          img.dispose();
        }
        return;
      }
      setState(() => _cloudSprites = s);
    });

    // ⚠️ Ces deux lignes étaient manquantes dans ta version
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

  // Trouve le nom exact utilisé dans CityNetwork même s'il y a une différence d'accent
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
        _visitedCities = visitedDoc.docs.map((d) => d.id).toSet();
        _stoppedCities = stoppedDoc.docs.map((d) => d.id).toSet();

        _visitedKeys = _visitedCities.map((c) => normalizeCityName(c)).toSet();
        _stoppedKeys = _stoppedCities.map((c) => normalizeCityName(c)).toSet();

        // Toutes les villes connues du joueur (visitées + arrêtées)
        final Set<String> allKnownNetworkNames = {
          ..._visitedCities.map(_resolveNetworkCityName),
          ..._stoppedCities.map(_resolveNetworkCityName),
        };

        final String? resolvedCurrent = _currentCity != null ? _resolveNetworkCityName(_currentCity!) : null;

        // Calcul des villes visibles (Connues + voisines à 1 de distance)
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

  // Vérifie si la ville est dévoilée (connue ou à 1 de distance d'une ville connue)
  bool _isVisibleOutOfFog(RegionCross cross) {
    if (_isCurrentCity(cross) || _isStopped(cross) || _isTraversed(cross)) return true;
    return _visibleKeys.contains(normalizeCityName(cross.name));
  }

  bool _isReachable(RegionCross cross) {
    if (!_hasFocusPlanned) return false;
    if (_isCurrentCity(cross)) return false;

    final route = _routeFor(cross);
    // Si route == null, c'est que la ville est bloquée derrière une ville non visitée !
    if (route == null) return false;

    if (widget.selectedDurationMinutes == -1) return true;
    return route.totalTravelMinutes <= widget.selectedDurationMinutes;
  }

  void _handleHoverPosition(Offset localPosition, List<RegionCross> crosses) {
    if (_selectedCrossId != null) return;

    String? closestId;
    double closestDistance = double.infinity;

    for (final cross in crosses) {
      // On ignore le survol des villes cachées dans le brouillard
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

  Widget _buildCityMarker(RegionCross cross) {
    final bool isCurrent = _isCurrentCity(cross);
    if (isCurrent) return const SizedBox.shrink();

    // Si la ville est dans le brouillard, on ne l'affiche pas du tout
    if (!_isVisibleOutOfFog(cross)) {
      return const SizedBox.shrink();
    }

    final bool isStopped = _isStopped(cross);
    final bool isTraversed = _isTraversed(cross);
    final bool isReachable = _isReachable(cross);
    final bool isSelected = _selectedCrossId == cross.id;

    // En mode exploration libre (sans timer), on affiche les villes connues
    // et un petit "?" discret sur les villes frontalières découvertes mais jamais visitées
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
      markerIcon = Icons.close_rounded; // Croix rouge (trop loin en temps ou non reliée au chemin actuel)
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
    // Zones sans nuages pour les titres de la région (réglables dans FogSettings.titleReveals)
    final List<RegionTitleReveal> regionTitles =
        FogSettings.titleReveals[widget.regionName] ?? const <RegionTitleReveal>[];

    const darkBlue = Color(0xFF143063);
    final List<RegionCross> regionCrosses = RegionCrossesData.crossesByRegion[widget.regionName] ?? [];
    final String? activeCrossId = _selectedCrossId ?? _hoveredCrossId;

    // Calcul des cercles de visibilité pour percer le brouillard
    final List<FogRevealArea> revealAreas = [];
    for (final cross in regionCrosses) {
      if (_isCurrentCity(cross) || _isStopped(cross) || _isTraversed(cross)) {
        // Grande zone dégagée autour des villes déjà conquises
        revealAreas.add(FogRevealArea(
          center: Offset(cross.x, cross.y),
          radius: FogSettings.visitedRevealRadius,
        ));
      } else if (_isVisibleOutOfFog(cross)) {
        // Zone plus restreinte autour des villes frontalières (à 1 de distance)
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

                        // CALQUE DU BROUILLARD DE GUERRE (masqué en mode admin)
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
                                        sprites: _cloudSprites, // ⚠️ manquait dans ta version
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // Affichage de l'illustration de la ville sélectionnée/survolée
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

                        // Affichage des marqueurs de villes (uniquement celles hors du brouillard)
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

                        // Affichage du personnage sur la ville actuelle
                        if (_currentCity != null)
                          ...regionCrosses
                              .where((c) => _isCurrentCity(c))
                              .map((cross) => Positioned(
                                    key: const ValueKey('player_position'),
                                    left: cross.x - 60,
                                    top: cross.y - 80,
                                    child: IgnorePointer(
                                      child: RepaintBoundary(
                                        child: PersistentAnimatedCharacter(
                                          key: const ValueKey('player_character'),
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

                          // Bouton Retour (Haut Gauche)
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

                          // Légende (Haut Droite)
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

                          // Panneau d'information et bouton "Y aller !" (Bas)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Builder(
                                  builder: (context) {
                                    final selectedCrossObj = regionCrosses.where((c) => c.id == _selectedCrossId).firstOrNull;
                                    if (selectedCrossObj == null) return const SizedBox.shrink();

                                    final bool canGo = _isReachable(selectedCrossObj);
                                    final bool isStopped = _isStopped(selectedCrossObj);
                                    final bool isTraversed = _isTraversed(selectedCrossObj);
                                    final route = _routeFor(selectedCrossObj);

                                    String statusText = 'Zone frontalière inconnue';
                                    Color statusColor = Colors.white70;
                                    if (isStopped) {
                                      statusText = '🏕️ Ville déjà visitée';
                                      statusColor = MapSettings.colorStopped;
                                    } else if (isTraversed) {
                                      statusText = '✨ Ville déjà traversée';
                                      statusColor = MapSettings.colorTraversed;
                                    } else if (canGo) {
                                      statusText = '🧭 Nouvelle destination accessible';
                                      statusColor = MapSettings.colorReachable;
                                    } else if (_hasFocusPlanned) {
                                      statusText = route == null
                                          ? '🔒 Bloquée par une zone inconnue'
                                          : '❌ Temps de focus insuffisant';
                                      statusColor = MapSettings.colorUnreachable;
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
                                                    if (route != null && _hasFocusPlanned) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Trajet : ${formatMinutesToHours(route.totalTravelMinutes)}',
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (_hasFocusPlanned) ...[
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

/// Représente une zone circulaire dégagée dans le brouillard
class FogRevealArea {
  final Offset center;
  final double radius;

  const FogRevealArea({required this.center, required this.radius});
}

/// Zone ovale sans nuages pour laisser apparaître les noms de régions
class RegionTitleReveal {
  final Offset position;
  final double radiusX; // Demi-largeur de l'ovale
  final double radiusY; // Demi-hauteur de l'ovale
  final double softness; // 0 = bord net, 1 = tout en dégradé
  final double rotationDegrees; // Inclinaison de l'ovale

  const RegionTitleReveal({
    required this.position,
    this.radiusX = 160.0,
    this.radiusY = 55.0,
    this.softness = 0.35,
    this.rotationDegrees = 0.0,
  });
}

/// Génère les sprites de nuages une seule fois (coûteux, mais pas à chaque frame).
/// Un nuage = plein de boules floues qui se chevauchent :
/// ombre dessous, corps au milieu, lumière dessus.
class CloudSprites {
  static const double w = FogSettings.spriteWidth;
  static const double h = FogSettings.spriteHeight;

  static Future<List<ui.Image>> generate() async {
    final List<ui.Image> out = [];
    for (int seed = 0; seed < FogSettings.spriteVariants; seed++) {
      out.add(await _make(seed));
    }
    return out;
  }

  static Future<ui.Image> _make(int seed) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final double q = FogSettings.spriteQuality; // 1.0 desktop, 0.5 téléphone
    canvas.scale(q);
    final rnd = math.Random(seed * 77 + 5);

    final List<List<double>> puffs = []; // [x, y, r]
    final int n = FogSettings.minPuffs + rnd.nextInt(FogSettings.puffsRange);
    for (int i = 0; i < n; i++) {
      final double t = rnd.nextDouble() * 2 * math.pi;
      final double dist = math.sqrt(rnd.nextDouble());
      final double x = w / 2 + math.cos(t) * dist * w * 0.26;
      // Dessous plutôt plat, dessus bien bombé
      final double sy = math.sin(t);
      final double y = h * 0.58 + (sy > 0 ? sy * dist * h * 0.08 : sy * dist * h * 0.24);
      final double r = (FogSettings.minPuffRadius + rnd.nextDouble() * FogSettings.puffRadiusRange) *
          (1.0 - dist * 0.35);
      puffs.add([x, y, r]);
    }

    // 1) Ombre (dessous)
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1] + p[2] * 0.35),
        p[2],
        Paint()
          ..color = FogSettings.cloudShadowColor.withValues(alpha: FogSettings.cloudShadowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.shadowBlur),
      );
    }
    // 2) Corps
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1]),
        p[2],
        Paint()
          ..color = FogSettings.cloudBodyColor.withValues(alpha: FogSettings.cloudBodyAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.bodyBlur),
      );
    }
    // 3) Lumière (dessus)
    for (final p in puffs) {
      canvas.drawCircle(
        Offset(p[0], p[1] - p[2] * 0.3),
        p[2] * 0.7,
        Paint()
          ..color = FogSettings.cloudLightColor.withValues(alpha: FogSettings.cloudLightAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p[2] * FogSettings.lightBlur),
      );
    }

    return recorder.endRecording().toImage((w * q).round(), (h * q).round());
  }
}

class _CloudInstance {
  final int sprite;
  final double baseX, baseY, scale, opacity, phase;
  final int speed; // multiplicateur entier => boucle parfaite
  const _CloudInstance(this.sprite, this.baseX, this.baseY, this.scale,
      this.opacity, this.phase, this.speed);
}

/// Dessine le brouillard : voile + nuages (sprites pré-rendus) + trous (villes, titres).
/// Dessine le brouillard : voile + nuages (sprites pré-rendus) + trous (villes, titres).
class FogOfWarPainter extends CustomPainter {
  final List<FogRevealArea> revealAreas;
  final List<RegionTitleReveal> titleReveals;
  final double animationValue;
  final List<ui.Image>? sprites;

  // ☁️ Marge géante pour que les nuages couvrent l'écran entier même dézoomé à fond
  static const double overflow = 2000.0;

  FogOfWarPainter({
    required this.revealAreas,
    required this.titleReveals,
    required this.animationValue,
    required this.sprites,
  });

  static List<_CloudInstance>? _cache;
  static Size? _cacheSize;
  static int? _cacheSpriteCount;

  static List<_CloudInstance> _instances(Size size, int spriteCount) {
    if (_cache != null && _cacheSize == size && _cacheSpriteCount == spriteCount) {
      return _cache!;
    }
    final rnd = math.Random(123);
    
    // Calcul de la surface totale en incluant le grand débordement
    final double totalWidth = size.width + (overflow * 2);
    final double totalHeight = size.height + (overflow * 2);

    final int baseCount = (totalWidth * totalHeight / FogSettings.densityDivisor)
        .round()
        .clamp(FogSettings.minClouds, FogSettings.maxClouds * 4); // Plafond augmenté pour couvrir l'overflow

    final int count = (baseCount * FogSettings.densityFactor).round().clamp(8, FogSettings.maxClouds * 4);
    final list = <_CloudInstance>[];
    
    for (int i = 0; i < count; i++) {
      list.add(_CloudInstance(
        rnd.nextInt(spriteCount),
        -overflow + rnd.nextDouble() * (totalWidth + CloudSprites.w * 2.4), // X avec débordement
        -overflow + rnd.nextDouble() * totalHeight,                         // Y avec débordement
        FogSettings.minScale + rnd.nextDouble() * FogSettings.scaleRange,
        FogSettings.minOpacity + rnd.nextDouble() * FogSettings.opacityRange,
        rnd.nextDouble() * 2 * math.pi,
        1 + rnd.nextInt(FogSettings.maxSpeedMultiplier),
      ));
    }
    
    // Petits/pâles derrière, grands devant
    list.sort((a, b) => a.scale.compareTo(b.scale));
    _cacheSize = size;
    _cacheSpriteCount = spriteCount;
    return _cache = list;
  }

  @override
  bool shouldRepaint(covariant FogOfWarPainter old) =>
      old.animationValue != animationValue ||
      old.sprites != sprites ||
      old.revealAreas.length != revealAreas.length ||
      old.titleReveals.length != titleReveals.length;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Zone de dessin géante qui inclut l'overflow
    final Rect fullRect = Rect.fromLTWH(
      -overflow, 
      -overflow, 
      size.width + (overflow * 2), 
      size.height + (overflow * 2),
    );
    canvas.saveLayer(fullRect, Paint());

    // Voile de base (cache la carte ET les bords extérieurs)
    canvas.drawRect(
      fullRect,
      Paint()..color = FogSettings.baseFogColor.withValues(alpha: FogSettings.baseFogAlpha),
    );

    // Nuages (sprites pré-rendus)
    final s = sprites;
    if (s != null && s.isNotEmpty) {
      final double wrapW = size.width + (overflow * 2) + CloudSprites.w * 2.4;
      final Paint p = Paint()..filterQuality = FogSettings.filterQuality;
      
      for (final c in _instances(size, s.length)) {
        final double cw = CloudSprites.w * c.scale;
        final double ch = CloudSprites.h * c.scale;
        
        // Boucle infinie calculée sur la grande largeur
        double x = c.baseX + animationValue * wrapW * c.speed;
        x = -overflow + ((x + overflow) % wrapW) - cw;
        
        final double y = c.baseY +
            math.sin(animationValue * 2 * math.pi * c.speed + c.phase) * FogSettings.verticalBobAmplitude;
            
        // Affichage uniquement si dans la zone visible élargie
        if (x > size.width + overflow || x + cw < -overflow || y > size.height + overflow || y + ch < -overflow) continue;

        p.color = Color.fromRGBO(255, 255, 255, c.opacity);
        final img = s[c.sprite];
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(x, y, cw, ch),
          p,
        );
      }
    }

    // Trous : villes explorées
    for (final area in revealAreas) {
      final double r = area.radius * FogSettings.revealRadiusMultiplier;
      final Rect holeRect = Rect.fromCircle(center: area.center, radius: r);
      canvas.drawCircle(
        area.center,
        r,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: [Colors.black, Colors.black.withValues(alpha: 0.8), Colors.transparent],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(holeRect),
      );
    }

    // Trous : titres de région
    for (final title in titleReveals) {
      canvas.save();
      canvas.translate(title.position.dx, title.position.dy);
      canvas.rotate(title.rotationDegrees * math.pi / 180.0);
      canvas.scale(title.radiusX, title.radiusY);

      final double inner = (1.0 - title.softness).clamp(0.0, 0.999);
      canvas.drawCircle(
        Offset.zero,
        1.0,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, inner, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.0)),
      );
      canvas.restore();
    }

    canvas.restore();

    // Aide au réglage
    if (FogSettings.debugTitleZones) {
      final Paint outline = Paint()
        ..color = const Color(0xFFFF1744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      final Paint dot = Paint()..color = const Color(0xFFFF1744);
      for (final title in titleReveals) {
        canvas.save();
        canvas.translate(title.position.dx, title.position.dy);
        canvas.rotate(title.rotationDegrees * math.pi / 180.0);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: title.radiusX * 2,
            height: title.radiusY * 2,
          ),
          outline,
        );
        canvas.drawCircle(Offset.zero, 8, dot);
        canvas.restore();
      }
    }
  }
}