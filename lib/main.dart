import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart'; // Importe le fichier qui vient d'être généré
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'screens/login_screen.dart'; 


void main() async{
  // On s'assure que les widgets sont bien initialisés
  WidgetsFlutterBinding.ensureInitialized();
  
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}