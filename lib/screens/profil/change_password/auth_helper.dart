import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  static Future<void> resetPassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun utilisateur connecte.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('E-mail envoyé !'),
            content: Text('Un lien de réinitialisation a été envoyé à ton adresse : ${user.email}. Vérifie tes spams si tu ne le vois pas.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}