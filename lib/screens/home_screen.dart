import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart'; // Import para verificación
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, bool> checklistStatus = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Minox Plan",
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.grey),
            onPressed: () async {
              // DEBUG: Imprimir notificaciones pendientes
              await NotificationService().checkPendingNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Revisa la consola para ver las notificaciones pendientes 🔔",
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Cargando perfil...",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // --- DATOS DEL USUARIO ---
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'] ?? "Bro";
          String aiRoutineText =
              userData['ai_generated_routine'] ??
              "Creando tu plan..."; // <--- AQUÍ LEE A LA IA

          // Armamos la lista de checkboxes
          List<dynamic> routineProducts = userData['routine_products'] ?? [];
          bool usesMinox = userData['uses_minoxidil'] ?? false;
          int minoxFreq = userData['minox_frequency'] ?? 0;
          List<String> finalRoutine = List<String>.from(routineProducts);

          /*
          if (usesMinox && !finalRoutine.contains("Minoxidil ($minoxFreq veces)")) {
            finalRoutine.insert(0, "Minoxidil ($minoxFreq al día)");
          }
          */

          // --- LOGICA DE DISPLAY DE RUTINA (JSON vs TEXTO) ---
          List<dynamic> routineSteps = [];
          bool isJsonRoutine = false;
          try {
            routineSteps = jsonDecode(aiRoutineText);
            isJsonRoutine = true;
          } catch (e) {
            // No es JSON, es texto plano antiguo
            isJsonRoutine = false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Qué hay, $userName 🦁",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // --- TARJETA DE INTELIGENCIA ARTIFICIAL ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                          SizedBox(width: 10),
                          Text(
                            "Tu Estrategia Personal",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 5),

                      // RENDERIZADO CONDICIONAL
                      if (isJsonRoutine)
                        ...routineSteps.map((step) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${step['time']} ",
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: "${step['title']}: ",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: step['body'],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      else
                        Text(
                          aiRoutineText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Checklist Diario:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                // --- CHECKLIST ---
                ListView.builder(
                  shrinkWrap:
                      true, // Importante para que funcione dentro del Scroll
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: finalRoutine.length,
                  itemBuilder: (context, index) {
                    String product = finalRoutine[index];
                    bool isDone = checklistStatus[product] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFFD4AF37)
                              : Colors.transparent,
                        ),
                      ),
                      child: CheckboxListTile(
                        activeColor: const Color(0xFFD4AF37),
                        checkColor: Colors.black,
                        title: Text(
                          product,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: isDone
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        secondary: _getIconForProduct(product),
                        value: isDone,
                        onChanged: (bool? value) {
                          setState(() {
                            checklistStatus[product] = value!;
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Icon _getIconForProduct(String productName) {
    if (productName.contains("Minoxidil"))
      return const Icon(Icons.science, color: Color(0xFFD4AF37));
    if (productName.contains("Aceite"))
      return const Icon(Icons.water_drop, color: Colors.amber);
    if (productName.contains("Bálsamo"))
      return const Icon(Icons.spa, color: Colors.green);
    if (productName.contains("Cera"))
      return const Icon(Icons.face, color: Colors.orange);
    if (productName.contains("Protector"))
      return const Icon(Icons.wb_sunny, color: Colors.yellow);
    if (productName.contains("Dermaroller"))
      return const Icon(Icons.grid_on, color: Colors.grey);
    return const Icon(Icons.check_circle_outline, color: Colors.grey);
  }
}
