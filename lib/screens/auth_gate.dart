import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha en tiempo real el estado de la autenticación
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // CASO 1: Firebase está pensando (Cargando inicial)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
          );
        }

        // CASO 2: No hay usuario (Nadie ha iniciado sesión)
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // CASO 3: ¡Hay un usuario! (La sesión persiste)
        // Ahora necesitamos verificar en Firestore si ya hizo el Onboarding
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            
            // Mientras descarga el documento de Firestore...
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
              );
            }

            // Si ya descargó los datos, revisamos la etiqueta 'onboarding_completed'
            if (userSnapshot.hasData && 
                userSnapshot.data!.exists && 
                userSnapshot.data!.get('onboarding_completed') == true) {
              return const HomeScreen(); // Todo en orden -> HOME
            } else {
              return const OnboardingScreen(); // Falta configurar -> ONBOARDING
            }
          },
        );
      },
    );
  }
}

