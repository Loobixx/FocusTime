import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
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
                  image: AssetImage('fond1.png'), 
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
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
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
                            color: Colors.white.withOpacity(0.6),
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
                        _buildTextField('Email'),
                        const SizedBox(height: 16),
                        _buildTextField('Mot de passe', isPassword: true),
                        
                        // Champ de confirmation
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildTextField('Confirmer le mot de passe', isPassword: true),
                        ],

                        // --- MOT DE PASSE OUBLIÉ ---
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: null, // null désactive le clic car non développé
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 0),
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: darkBlue.withOpacity(0.5), // Couleur estompée
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough, // Texte barré
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
                          _navigateToHome,
                        ),
                        const SizedBox(height: 24),

                        // --- SÉPARATEUR ---
                        Row(
                          children: [
                            Expanded(child: Divider(color: darkBlue.withOpacity(0.3), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                "Ou avec",
                                style: TextStyle(color: darkBlue.withOpacity(0.8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Divider(color: darkBlue.withOpacity(0.3), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- BOUTONS GOOGLE & APPLE (Désactivés) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildSocialButton('Google', Colors.white, Colors.black, _navigateToHome, isAvailable: false)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSocialButton('Apple', Colors.black, Colors.white, _navigateToHome, isAvailable: false)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- LIEN DE BASCULE EN BAS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin ? "Pas encore de compte ?" : "Déjà un compte ?", 
                              style: TextStyle(color: darkBlue.withOpacity(0.8))
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

  // Méthode pour les champs de texte
  Widget _buildTextField(String hintText, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
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
        // Fond rendu un peu transparent si indisponible
        backgroundColor: isAvailable ? bgColor : bgColor.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      onPressed: isAvailable ? onPressed : null, // Clic désactivé si indisponible
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          // Couleur estompée et texte barré si indisponible
          color: isAvailable ? textColor : textColor.withOpacity(0.5),
          fontWeight: FontWeight.bold,
          decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}