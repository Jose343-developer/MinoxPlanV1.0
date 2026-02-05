import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/login_screen.dart'; // Esta la crearemos en un momento
import 'screens/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await dotenv.load(fileName: ".env");
  // AHORA NO INICIAMOS FIREBASE AÚN (Solo diseño)
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
 );

  runApp(const MinoxPlanApp());
}

class MinoxPlanApp extends StatelessWidget {
  const MinoxPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minox Plan',
      debugShowCheckedModeBanner: false, // Adiós etiqueta roja
      
      // --- TEMA GENERAL DE DISEÑO ---
      theme: ThemeData(
        brightness: Brightness.dark, // Modo oscuro base
        scaffoldBackgroundColor: Colors.black, // Fondo totalmente negro
        primaryColor: const Color(0xFFD4AF37), // Nuestro Dorado
        
        // Diseño de todos los Inputs (Cajas de texto)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900], // Fondo gris oscuro
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        
        // Diseño de todos los Botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37), // Dorado
            foregroundColor: Colors.black, // Texto negro
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        useMaterial3: true,
      ),
      
      // Nuestra primera pantalla
      home: const AuthGate(),
    );
  }
}