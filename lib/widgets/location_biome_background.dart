import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/camp_biome.dart';
import 'biome_backdrop.dart';

/// Affiche le décor de la région où se trouve actuellement le joueur.
/// Le fond change automatiquement quand sa position Firebase change.
class LocationBiomeBackground extends StatefulWidget {
  final double blurSigma;
  final bool listenToUserBiome;

  const LocationBiomeBackground({
    super.key,
    this.blurSigma = 5,
    this.listenToUserBiome = true,
  });

  @override
  State<LocationBiomeBackground> createState() =>
      _LocationBiomeBackgroundState();
}

class _LocationBiomeBackgroundState extends State<LocationBiomeBackground> {
  CampBiome _biome = CampBiomes.fallback;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribeBiome();
  }

  @override
  void reassemble() {
    super.reassemble();
    _sub?.cancel();
    _sub = null;
    _subscribeBiome();
  }

  @override
  void didUpdateWidget(covariant LocationBiomeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenToUserBiome != widget.listenToUserBiome) {
      _sub?.cancel();
      _sub = null;
      _subscribeBiome();
    }
  }

  void _subscribeBiome() {
    if (!widget.listenToUserBiome) return;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) return;

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        final data = snapshot.data();
        final resolved = CampBiomes.resolve(
          city: data?['currentCity'] as String?,
          zone: data?['currentZone'] as String?,
        );
        if (mounted && resolved.id != _biome.id) {
          setState(() => _biome = resolved);
        }
      },
      onError: (Object _) {
        // Ignoré lors de la révocation de session (déconnexion).
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: Image.asset(
          _biome.background,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              BiomeBackdrop(zoneId: _biome.id),
        ),
      ),
    );
  }
}
