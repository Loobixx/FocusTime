import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:focus_time/screens/home_screen.dart'; 

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  bool _isLoading = false;

 // 1. Les 5 régions avec les BONS IDs qui matchent tes assets et ton code
  final List<Map<String, dynamic>> _regions = [
    {
      'id': 'desert',
      'title': 'Le Désert',
      'color': Colors.orange,
      'startCity': 'La cité Solaris',
    },
    {
      'id': 'montagnes',
      'title': 'Les Montagnes',
      'color': Colors.green,
      'startCity': 'Le village de Néris',
    },
    {
      'id': 'lac', // 👈 'lac' au lieu de 'eau'
      'title': 'Le Lac',
      'color': Colors.blue,
      'startCity': 'Le village Keltia',
    },
    {
      'id': 'nuit', // 👈 'nuit' au lieu de 'nocturne'
      'title': 'La Nuit',
      'color': Colors.deepPurple,
      'startCity': 'ville nocturne',
    },
    {
      'id': 'nuages',
      'title': 'Les Nuages',
      'color': Colors.pinkAccent, // Assorti avec CharacterOptions
      'startCity': 'ville des nuages',
    },
  ];

  Future<void> _selectCharacter(Map<String, dynamic> region) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Color themeColor = region['color'] as Color;

        // 2. On enregistre directement les bonnes clés Firestore !
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'currentCity': region['startCity'],
          'characterId': region['id'], // 👈 C'est characterId qu'on met à jour !
          'characterColor': themeColor.toARGB32(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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