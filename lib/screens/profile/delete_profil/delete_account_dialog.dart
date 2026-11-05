import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:focus_time/screens/auth/login_screen.dart';
import 'package:focus_time/services/user_data_deletion_service.dart';

class DeleteAccountDialog {
  static const String _googleWebClientId =
      '866476346837-765b8ovlcodsq25n3k6e87435q9ni4qo.apps.googleusercontent.com';

  static bool _usesPasswordProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  static bool _usesGoogleProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  static Future<void> show(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Récupération préalable de toutes les données
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userDoc = await userRef.get();
    final travelDoc = await userRef.collection('travel').doc('status').get();
    final historySnap = await userRef.collection('travel_history').get();
    final visitedSnap = await userRef.collection('visited_cities').get();
    final stoppedSnap = await userRef.collection('stopped_cities').get();

    final userData = userDoc.data() ?? {};
    final travelData = travelDoc.data() ?? {};
    final historyCount = historySnap.docs.length;
    final visitedCities = visitedSnap.docs.map((d) => d.id).toList();
    final stoppedCitiesCount = stoppedSnap.docs.length;
    final requiresPassword = _usesPasswordProvider(user);

    if (!context.mounted) return;

    final passwordController = TextEditingController();

    // 2. Boîte de dialogue récapitulative
    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        String? errorText;

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
                          _buildInfoRow('Position actuelle', userData['currentCity'] ?? 'Le village de Néris'),
                          _buildInfoRow('Personnage', userData['characterId'] ?? 'nuit'),
                          _buildInfoRow('Villes visitées', visitedCities.isEmpty ? 'Aucune' : visitedCities.join(', ')),
                          _buildInfoRow('Villes où tu t\'es arrêté', '$stoppedCitiesCount'),
                          _buildInfoRow('Trajets archivés', '$historyCount trajet(s)'),
                          if (travelData.isNotEmpty)
                            _buildInfoRow('Statut de voyage en cours', travelData['isFocusActive'] == true ? 'Actif' : 'Inactif'),
                        ],
                      ),
                    ),
                    if (requiresPassword) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        enabled: !isDeleting,
                        decoration: InputDecoration(
                          labelText: 'Confirme ton mot de passe',
                          errorText: errorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ] else if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
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
                          if (requiresPassword && passwordController.text.trim().isEmpty) {
                            setDialogState(() {
                              errorText = 'Saisis ton mot de passe pour confirmer.';
                            });
                            return;
                          }
                          setDialogState(() {
                            isDeleting = true;
                            errorText = null;
                          });
                          final failureMessage = await _executeFullDeletion(
                            context,
                            dialogContext,
                            user,
                            password: passwordController.text.trim(),
                          );
                          if (failureMessage != null && dialogContext.mounted) {
                            setDialogState(() {
                              isDeleting = false;
                              errorText = failureMessage;
                            });
                          }
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

    passwordController.dispose();
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

  /// Ré-authentifie l'utilisateur AVANT d'effacer les données Firestore afin
  /// d'éviter toute perte de données si `user.delete()` exige une connexion récente.
  static Future<void> _reauthenticateBeforeDeletion(
    User user, {
    required String password,
  }) async {
    if (_usesPasswordProvider(user) && user.email != null) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return;
    }

    final lastSignIn = user.metadata.lastSignInTime;
    final isRecentSession = lastSignIn != null &&
        DateTime.now().difference(lastSignIn) < const Duration(minutes: 4);
    if (isRecentSession) return;

    if (_usesGoogleProvider(user)) {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(GoogleAuthProvider());
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: _googleWebClientId,
        );
        final googleUser = await GoogleSignIn.instance.authenticate();
        final credential = GoogleAuthProvider.credential(
          idToken: googleUser.authentication.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }
    }
  }

  // 3. Traitement de la suppression en cascade (ré-authentification -> Firestore -> Firebase Auth)
  static Future<String?> _executeFullDeletion(
    BuildContext context,
    BuildContext dialogContext,
    User user, {
    required String password,
  }) async {
    try {
      await _reauthenticateBeforeDeletion(user, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Mot de passe incorrect.';
      }
      if (e.code == 'too-many-requests') {
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      }
      return 'Impossible de vérifier ton identité. Reconnecte-toi puis réessaie.';
    } catch (_) {
      return 'Vérification annulée ou impossible. Tes données n\'ont pas été supprimées.';
    }

    try {
      await UserDataDeletionService().deleteUserData(user.uid);
      await user.delete();

      if (dialogContext.mounted) Navigator.pop(dialogContext);

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Session expirée. Reconnecte-toi puis relance la suppression pour finaliser la fermeture du compte.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de supprimer le compte pour le moment.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur suppression compte : $e');
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Une erreur imprévue est survenue lors de la suppression.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return null;
    }
  }
}
