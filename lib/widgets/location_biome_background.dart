import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/camp_biome.dart';
import 'biome_backdrop.dart';

/// Affiche le décor de la région où se trouve actuellement le joueur.
/// Le fond change automatiquement quand sa position Firebase change.
class LocationBiomeBackground extends StatelessWidget {
  final double blurSigma;

  const LocationBiomeBackground({super.key, this.blurSigma = 5});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildBackground(CampBiomes.fallback);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final biome = CampBiomes.resolve(
          city: data?['currentCity'] as String?,
          zone: data?['currentZone'] as String?,
        );
        return _buildBackground(biome);
      },
    );
  }

  Widget _buildBackground(CampBiome biome) {
    return SizedBox.expand(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Image.asset(
          biome.background,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              BiomeBackdrop(zoneId: biome.id),
        ),
      ),
    );
  }
}
