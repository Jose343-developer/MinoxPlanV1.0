

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
 
final emailController = TextEditingController();
final passwordController = TextEditingController();

// bolita de carga
bool isLoading = false;

//para registrarse en firebase
Future<void> registerUser() async {
  setState(() {
    isLoading = true;

  });

  try {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text.trim(), 
    password: passwordController.text.trim(),
    );
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cuenta creada con esxito"),
        backgroundColor: Colors.green,
        ),
        );
        Navigator.pop(context);
        //aqui navegacion al home (pagina principal de la app)
    }
  

  } on FirebaseAuthException catch (e){
    // al momento de fallar nos dara esta lista de errores
    if (mounted){
      String mensaje = ("error desconocido");
      if (e.code == 'weak-password') mensaje = "La contraseña es muy débil (usa 6+ caracteres)";
        if (e.code == 'email-already-in-use') mensaje = "Este correo ya está registrado";
        if (e.code == 'invalid-email') mensaje = "El correo no es válido";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("mensaje x dinero"),
            backgroundColor: Colors.red,
            ),
        );
    } 
    }finally{
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }

    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea evita que el diseño choque con la "isla dinámica" o el notch del iPhone
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( // Permite hacer scroll si el teclado tapa la pantalla
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los botones a lo ancho
              children: [
                // 1. EL LOGO (Icono de Fuego Dorado)
                const Icon(
                  Icons.local_fire_department, 
                  size: 80,
                  color: Color(0xFFD4AF37), // Nuestro Dorado
                ),
                
                const SizedBox(height: 20),
                
                // 2. TÍTULOS
                const Text(
                  "REGISTRATE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900, // Letra muy gruesa
                    color: Colors.white,
                    letterSpacing: 2.0, // Espacio entre letras elegante
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Construye tu mejor versión",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 50), // Espacio grande antes de los inputs
                
                // 3. CAJA DE CORREO
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: Colors.white), // Texto blanco al escribir
                  decoration: InputDecoration(
                    labelText: "Correo Electrónico",
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 4. CAJA DE CONTRASEÑA
                TextField(
                  controller: passwordController,
                  obscureText: true, // Oculta las letras con puntitos
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: Icon(Icons.visibility_off, color: Colors.grey), // Icono de ojo
                  ),
                ),
                
            
                
                const SizedBox(height: 30),
                
                // 6. BOTÓN GRANDE DE INICIO
                ElevatedButton(
                  onPressed: isLoading ? null : registerUser, // Si carga, se desactiva
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading 
                      ? const SizedBox( // Si carga, muestra ruedita
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                        )
                      : const Text("CREAR CUENTA"), // Si no, muestra texto
                ),
                
                const SizedBox(height: 20),
                
                // 7. ENLACE PARA REGISTRARSE
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}