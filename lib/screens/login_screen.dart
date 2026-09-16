import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; 
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  // ✨ NOUVEAU : Variables pour gérer la visibilité des mots de passe
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
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
          'pseudo': '',
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
        'characterId': 'nuit', // 👈 On met la Nuit par défaut
        'characterColor': Colors.deepPurple.toARGB32(), // 👈 Directement le violet !
        'hat': 'Aucun',
        'pseudo': '',
      });
      }

      if (mounted) {
        TextInput.finishAutofillContext();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("CODE FIREBASE : ${e.code}");
      debugPrint("MESSAGE FIREBASE : ${e.message}");
      _showError(e.message ?? "Une erreur est survenue.");
    } catch (e) {
      debugPrint("ERREUR INATTENDUE : $e");
      _showError("Une erreur inattendue s'est produite.");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
                    child: AutofillGroup(
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
                        _buildTextField(
                          'Email',
                          controller: _emailController,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 16),

                        // ✨ NOUVEAU : Appel du champ mot de passe avec l'état de visibilité
                        _buildTextField(
                          'Mot de passe',
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          controller: _passwordController,
                          autofillHints: const [AutofillHints.password],
                        ),                        
                        // Champ de confirmation
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          // ✨ NOUVEAU : Appel du champ confirmation avec son propre état
                          _buildTextField(
                            'Confirmer le mot de passe', 
                            isPassword: true, 
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            controller: _confirmPasswordController
                          ),
                        ],

                        // --- MOT DE PASSE OUBLIÉ ---
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog, 
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 0),
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: darkBlue.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
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
                          _submitAuth, 
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

                        // --- BOUTONS GOOGLE & APPLE ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                'Google', 
                                Colors.white, 
                                Colors.black, 
                                _signInWithGoogle, 
                                isAvailable: true,  
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
          ),
        ],
      ),
    );
  }

  // ✨ NOUVEAU : La méthode _buildTextField prend maintenant en charge l'œil de visibilité
  Widget _buildTextField(
    String hintText, {
    bool isPassword = false, 
    bool obscureText = false, // Paramètre pour savoir s'il faut cacher le texte
    VoidCallback? onToggleVisibility, // Fonction appelée quand on clique sur l'œil
    required TextEditingController controller, 
    List<String>? autofillHints
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false, // On cache uniquement si c'est un mdp ET que l'œil est fermé
      autofillHints: autofillHints,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
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
        // ✨ NOUVEAU : L'icône suffixe s'affiche uniquement sur les champs de mot de passe
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF143063).withValues(alpha: 0.5),
                ),
                onPressed: onToggleVisibility, // Lance le changement d'état (ouvert/fermé)
              )
            : null,
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre adresse e-mail d\'abord.')),
      );
      return;
    }

    try {
      // ✉️ Envoie l'e-mail de réinitialisation via Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('E-mail envoyé !'),
            content: Text('Un lien de réinitialisation a été envoyé à l\'adresse $email. Vérifie tes spam si tu ne le vois pas.'),
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
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue.';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur ne correspond à cet e-mail.';
      } else if (e.code == 'invalid-email') {
        message = 'L\'adresse e-mail n\'est pas valide.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entre ton adresse e-mail pour recevoir un lien de réinitialisation :'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Adresse e-mail',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(emailController.text);
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
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