import 'package:FocusTime/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart'; // Importe le fichier qui vient d'être généré
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'screens/login_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async{
  // On s'assure que les widgets sont bien initialisés
  WidgetsFlutterBinding.ensureInitialized();
  
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Force Firebase Auth à stocker la session en local sur l'appareil
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  
  // On rend la barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Rend la barre transparente
      statusBarIconBrightness: Brightness.light, // Icônes blanches (heure/batterie)
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FocusTime',
      // On écoute l'état de l'utilisateur en direct
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Pendant que Firebase vérifie le stockage local
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00))),
            );
          }
          
          // Si un utilisateur est déjà connecté en cache, on va direct sur l'accueil
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          
          // Sinon, on affiche l'écran de connexion / inscription
          return const LoginScreen(); 
        },
      ),
    );
  }
}