import 'dart:async';
import 'package:flutter/material.dart';

class SpriteAnimator extends StatefulWidget {
  final double width;
  final double height;
  final Map<String, List<String>> animations; // Dictionnaire des listes d'images
  final String currentState; // L'état actuel ('marche', 'arret', 'dort'...)
  final Duration frameDuration;
  final BoxFit fit;

  const SpriteAnimator({
    super.key,
    required this.width,
    required this.height,
    required this.animations,
    required this.currentState,
    this.frameDuration = const Duration(milliseconds: 100),
    this.fit = BoxFit.contain,
  });

  @override
  State<SpriteAnimator> createState() => _SpriteAnimatorState();
}

class _SpriteAnimatorState extends State<SpriteAnimator> {
  // On stocke les fournisseurs d'images préchargées pour chaque état
  final Map<String, List<ImageProvider>> _cachedProviders = {};
  
  final ValueNotifier<int> _frameIndex = ValueNotifier<int>(0);
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _prepareImages();
    _startTimer();
  }

  // Si le parent change l'état (ex: passe de 'marche' à 'arret'), on redémarre à l'image 0
  @override
  void didUpdateWidget(SpriteAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentState != widget.currentState) {
      _frameIndex.value = 0;
    }
  }

  void _prepareImages() {
    final int pxWidth = (widget.width * 2).round();
    final int pxHeight = (widget.height * 2).round();

    widget.animations.forEach((stateName, frames) {
      _cachedProviders[stateName] = frames
          .map<ImageProvider>((p) => ResizeImage(AssetImage(p), width: pxWidth, height: pxHeight, policy: ResizeImagePolicy.fit,))
          .toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (var providersList in _cachedProviders.values) {
        for (final p in providersList) {
          precacheImage(p, context);
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(widget.frameDuration, (_) {
      final currentListLength = _cachedProviders[widget.currentState]?.length ?? 1;
      if (currentListLength > 1) {
        _frameIndex.value = (_frameIndex.value + 1) % currentListLength;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frameIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProviders = _cachedProviders[widget.currentState];

    // Sécurité au cas où l'état demandé n'existe pas ou la liste est vide
    if (activeProviders == null || activeProviders.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(Icons.error_outline, color: Colors.red),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: _frameIndex,
      builder: (_, i, _) {
        // Sécurité si l'index dépasse la taille de la liste lors d'un changement d'état très rapide
        final safeIndex = i < activeProviders.length ? i : 0;
        
        return Image(
          image: activeProviders[safeIndex],
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}