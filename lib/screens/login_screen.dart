import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; 
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  // Contrôleurs pour récupérer les valeurs des champs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Si tu es sur Android, on peut récupérer ton client ID web depuis ton fichier firebase_options.dart 
      // ou initialiser GoogleSignIn avec l'clientId web généré lors du flutterfire configure :
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '866476346837-c1613bd360304873dc015c.apps.googleusercontent.com', // Ton appClientId web extrait de ton firebase_options.dart
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return; 
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'createdAt': Timestamp.now(),
          'characterColor': 'blue',
          'hat': 'Aucun',
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur Google Sign-In : ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }



  // Fonction de soumission connectée à Firebase
  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs.");
      return;
    }

    if (!_isLogin && password != confirmPassword) {
      _showError("Les mots de passe ne correspondent pas.");
      return;
    }

    try {
      if (_isLogin) {
        // Connexion
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Inscription
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Enregistrement des données initiales dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': Timestamp.now(),
          'characterColor': 'blue', // Valeur par défaut
          'hat': 'Aucun',          // Valeur par défaut
        });
      }

      // Redirection vers l'accueil si tout s'est bien passé
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("CODE FIREBASE : ${e.code}");
      print("MESSAGE FIREBASE : ${e.message}");
      _showError(e.message ?? "Une erreur est survenue.");
    } catch (e) {
      print("ERREUR INATTENDUE : $e"); // <-- C'est ça qui va cracher la vérité dans la console
      _showError("Une erreur inattendue s'est produite.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Image de fond floutée
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), 
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fond1.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 2. Contenu centré avec effet Glassmorphism
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- FLÈCHE DE RETOUR ---
                        if (!_isLogin)
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                              onPressed: _toggleMode,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        
                        if (_isLogin) const SizedBox(height: 16),

                        // --- EMPLACEMENT LOGO ---
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_empty, color: darkBlue, size: 36),
                        ),
                        const SizedBox(height: 16),

                        // --- TITRE ET SOUS-TITRE ---
                        const Text(
                          'FocusTime',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Prêt à rester concentré ?' : 'Rejoignez l\'aventure !',
                          style: const TextStyle(
                            fontSize: 15,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- CHAMPS DE TEXTE ---
                        _buildTextField('Email', controller: _emailController),
                        const SizedBox(height: 16),
                        _buildTextField('Mot de passe', isPassword: true, controller: _passwordController),
                        
                        // Champ de confirmation
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField('Confirmer le mot de passe', isPassword: true, controller: _confirmPasswordController),
                        ],

                        // --- MOT DE PASSE OUBLIÉ ---
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: null, 
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 0),
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: darkBlue.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 24),

                        // --- BOUTON PRINCIPAL ---
                        _buildButton(
                          _isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE', 
                          focusOrange, 
                          Colors.white,
                          _submitAuth, // Appelle la fonction Firebase
                        ),
                        const SizedBox(height: 24),

                        // --- SÉPARATEUR ---
                        Row(
                          children: [
                            Expanded(child: Divider(color: darkBlue.withValues(alpha: 0.3), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                "Ou avec",
                                style: TextStyle(color: darkBlue.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: darkBlue.withValues(alpha: 0.3), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- BOUTONS GOOGLE & APPLE (Désactivés) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                'Google', 
                                Colors.white, 
                                Colors.black, 
                                _signInWithGoogle, // <-- On branche la fonction ici
                                isAvailable: true,  // <-- On le rend disponible
                              ),
                            ),                            
                            const SizedBox(width: 16),
                            Expanded(child: _buildSocialButton('Apple', Colors.black, Colors.white, () {}, isAvailable: false)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- LIEN DE BASCULE EN BAS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? "Pas encore de compte ?" : "Déjà un compte ?", 
                              style: TextStyle(color: darkBlue.withValues(alpha: 0.8))
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                              child: Text(
                                _isLogin ? 'S\'inscrire' : 'Se connecter', 
                                style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        )
                      ],
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

  // Méthode pour les champs de texte avec support du contrôleur
  Widget _buildTextField(String hintText, {bool isPassword = false, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 16),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }

  // Méthode pour le bouton principal
  Widget _buildButton(String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: onPressed, 
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Méthode pour les boutons sociaux avec système "isAvailable"
  Widget _buildSocialButton(String text, Color bgColor, Color textColor, VoidCallback onPressed, {bool isAvailable = true}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isAvailable ? bgColor : bgColor.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      onPressed: isAvailable ? onPressed : null, 
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isAvailable ? textColor : textColor.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
        ),
      ),
    );
  }
}