import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:FocusTime/screens/home_screen.dart'; 

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  bool _isLoading = false;

  // Tes 5 régions avec leurs données temporaires
  final List<Map<String, dynamic>> _regions = [
    {
      'id': 'desert',
      'title': 'Le Désert',
      'color': Colors.orange,
      'startCity': 'ville du desert',
    },
    {
      'id': 'montagnes',
      'title': 'Les Montagnes',
      'color': Colors.green,
      'startCity': 'Le village de Néris',
    },
    {
      'id': 'eau',
      'title': 'L\'Eau',
      'color': Colors.blue,
      'startCity': 'ville de l\'eau',
    },
    {
      'id': 'nocturne',
      'title': 'La Nuit',
      'color': Colors.deepPurple,
      'startCity': 'ville nocturne',
    },
    {
      'id': 'nuages',
      'title': 'Les Nuages',
      'color': Colors.lightBlueAccent,
      'startCity': 'ville des nuages',
    },
  ];

  Future<void> _selectCharacter(Map<String, dynamic> region) async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // On sauvegarde le choix dans Firebase
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'currentCity': region['startCity'], // "ville du desert", etc.
          'profileRegion': region['id'],      // Pour afficher le bon avatar plus tard
          'profileColor': region['color'].value, // Si tu veux utiliser la couleur en attendant les dessins
        }, SetOptions(merge: true)); // merge: true évite d'écraser d'autres données s'il y en a

        if (!mounted) return;
        
        // Redirection vers ta carte principale
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        title: const Text('Choisis ton origine', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Empêche de faire "retour"
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  // On donne la couleur directement au ListTile
                  tileColor: region['color'].withValues(alpha: 0.2),
                  // On lui donne aussi la forme avec les bords arrondis
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: region['color'], width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  title: Text(
                    region['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Commencer à : ${region['startCity']}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () => _selectCharacter(region),
                ),
              );
            },
          ),
    );
  }
}