import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; 
import 'package:flutter/services.dart';

void main() {
  // On s'assure que les widgets sont bien initialisés
  WidgetsFlutterBinding.ensureInitialized();
  
  // On rend la barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Rend la barre transparente
      statusBarIconBrightness: Brightness.light, // Icônes blanches (heure/batterie)
    ),
  );

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