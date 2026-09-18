import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/screens/login_screen.dart';

class DeleteAccountDialog {
  static Future<void> show(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Récupération préalable de toutes les données
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userDoc = await userRef.get();
    final travelDoc = await userRef.collection('travel').doc('status').get();
    final historySnap = await userRef.collection('travel_history').get();
    final visitedSnap = await userRef.collection('visited_cities').get();

    final userData = userDoc.data() ?? {};
    final travelData = travelDoc.data() ?? {};
    final historyCount = historySnap.docs.length;
    final visitedCities = visitedSnap.docs.map((d) => d.id).toList();

    if (!context.mounted) return;

    // 2. Boîte de dialogue récapitulative
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 8),
                  Text('Supprimer mon compte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Voici l\'ensemble des informations associées à ton compte sur nos serveurs :',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Identifiant (UID)', user.uid),
                          _buildInfoRow('E-mail', user.email ?? userData['email'] ?? 'Non renseigné'),
                          _buildInfoRow('Pseudo', userData['pseudo']?.toString().isNotEmpty == true ? userData['pseudo'] : 'Aucun'),
                          _buildInfoRow('Position actuelle', userData['currentCity'] ?? 'Valenciennes'),
                          _buildInfoRow('Personnage', userData['characterId'] ?? 'nuit'),
                          _buildInfoRow('Villes visitées', visitedCities.isEmpty ? 'Aucune' : visitedCities.join(', ')),
                          _buildInfoRow('Trajets archivés', '$historyCount trajet(s)'),
                          if (travelData.isNotEmpty)
                            _buildInfoRow('Statut de voyage en cours', travelData['isFocusActive'] == true ? 'Actif' : 'Inactif'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '⚠️ Cette action est irréversible. Toutes ces données ainsi que tes identifiants de connexion seront définitivement effacés.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          await _executeFullDeletion(context, dialogContext, user);
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Tout supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: '$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // 3. Traitement de la suppression en cascade
  static Future<void> _executeFullDeletion(BuildContext context, BuildContext dialogContext, User user) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // A. Suppression des documents des sous-collections
      final travelDocs = await userRef.collection('travel').get();
      for (var doc in travelDocs.docs) {
        await doc.reference.delete();
      }

      final historyDocs = await userRef.collection('travel_history').get();
      for (var doc in historyDocs.docs) {
        await doc.reference.delete();
      }

      final visitedDocs = await userRef.collection('visited_cities').get();
      for (var doc in visitedDocs.docs) {
        await doc.reference.delete();
      }

      // B. Suppression du document racine utilisateur
      await userRef.delete();

      // C. Suppression du compte Firebase Auth
      await user.delete();

      if (dialogContext.mounted) Navigator.pop(dialogContext);

      // Redirection immédiate vers l'écran de connexion
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);

      // Cas où la dernière connexion remonte à trop longtemps (sécurité Firebase)
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pour des raisons de sécurité, veuillez vous reconnecter avant de supprimer votre compte.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.message}'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur imprévue : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}