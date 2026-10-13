import 'dart:async';
import 'package:flutter/material.dart';

class PersistentAnimatedCharacter extends StatefulWidget {
  final double size;
  final List<String> frames;
  final Duration frameDuration;

  const PersistentAnimatedCharacter({
    super.key,
    required this.size,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 100),
  });

  @override
  State<PersistentAnimatedCharacter> createState() =>
      _PersistentAnimatedCharacterState();
}

class _PersistentAnimatedCharacterState
    extends State<PersistentAnimatedCharacter> {
  late final List<ImageProvider> _providers;
  final ValueNotifier<int> _index = ValueNotifier<int>(0);
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    // Décodage à la taille d'affichage (x2 pour les écrans retina) :
    // beaucoup moins de mémoire, donc plus d'éviction du cache.
    final int px = (widget.size * 2).round();
    _providers = widget.frames
        .map<ImageProvider>((p) => ResizeImage(AssetImage(p), width: px))
        .toList();

    _timer = Timer.periodic(widget.frameDuration, (_) {
      _index.value = (_index.value + 1) % _providers.length;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final p in _providers) {
        precacheImage(p, context); // une seule fois
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seul ce petit widget se reconstruit à chaque frame, pas la carte.
    return ValueListenableBuilder<int>(
      valueListenable: _index,
      builder: (_, i, __) => Image(
        image: _providers[i],
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true, // pas de clignotement ni de rechargement
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}