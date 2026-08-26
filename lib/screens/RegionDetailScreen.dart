import 'dart:ui';
import 'package:flutter/material.dart';

class RegionDetailScreen extends StatelessWidget {
  final String regionName;

  const RegionDetailScreen({Key? key, required this.regionName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    // Dictionnaire pour associer chaque région à son image zoomée spécifique
    String getImageAsset() {
      switch (regionName) {
        case 'desert':
          return 'assets/zoom_desert.png';
        case 'montagnes':
          return 'assets/zoom_montagne.png';
        case 'nuit':
          return 'assets/zoom_nuit.png';
        case 'nuages':
          return 'assets/zoom_nuages.png';
        case 'lac':
          return 'assets/zoom_lac.png';
        default:
          return 'assets/fond1.png';
      }
    }

    return Scaffold(
      // 1. Fond général appliqué derrière l'image (tu peux changer la couleur ou mettre une texture)
      backgroundColor: const Color(0xFF12121C), 
      body: Stack(
        children: [
          // 2. Image détaillée interactive avec une marge de déplacement (boundaryMargin)
          Positioned.fill(
            child: InteractiveViewer(
              // Permet de libérer l'espace de glissement pour pouvoir bouger la carte dans tous les sens
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 1.0,  
              maxScale: 4.0,  
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.asset(
                    getImageAsset(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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