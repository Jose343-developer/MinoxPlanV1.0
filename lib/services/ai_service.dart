import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // 2. LEER LA CLAVE DEL ENV
  // Si no encuentra la clave, usa un string vacío para evitar errores de compilación,
  // pero lanzará error si intentas usarlo.
  static String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  Future<String> createRoutine({
    // ... (El resto de tus parámetros siguen igual)
    required String name,
    required String wakeTime,
    required String sleepTime,
    required bool usesMinoxidil,
    required List<dynamic> products,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey, // Aquí usa la variable segura
      );

      // 2. Preparamos los datos del usuario para enviarlos
      String productsList = products.join(", ");
      String minoxText = usesMinoxidil
          ? "Sí usa Minoxidil"
          : "No usa Minoxidil";

      // 3. EL PROMPT (Las instrucciones al cerebro)
      final prompt = Content.text('''
        Eres un experto dermatólogo y barbero profesional llamado "MinoxBot".
        Tu cliente se llama $name.
        
        Datos del cliente:
        - Hora de despertar: $wakeTime
        - Hora de dormir: $sleepTime
        - $minoxText
        - Productos que tiene: $productsList
        
        Misión:
        Crea una rutina detallada y cronológica para el cuidado de su barba.
        
        Reglas estrictas:
        1. El Minoxidil debe aplicarse con la cara limpia y dejarse secar 4 horas antes de poner otros productos o dormir.
        2. Si usa Minoxidil 2 veces, la segunda debe ser 8-12 horas después de la primera, pero al menos 1 hora antes de dormir.
        3. Sé motivador, usa un tono de "Coach" o "Hermano mayor" en el campo "body". Usa emojis.
        4. IMPORTANTE: Tu respuesta debe ser ÚNICAMENTE un JSON válido. No uses Markdown, no uses bloques de código ```json ... ```, solo el JSON puro.
        5. La estructura del JSON debe ser una lista de objetos: [{ "time": "HH:mm", "title": "Nombre actividad", "body": "Instrucción breve" }]
        6. IMPORTANTE: En el campo "time", usa DOS PUNTOS (:) como separador, ejemplo: "08:00", NO uses guiones.
      ''');

      // 4. Enviamos y esperamos respuesta
      final response = await model.generateContent([prompt]);

      return response.text ??
          "Hubo un error generando tu rutina, bro. Intenta de nuevo.";
    } catch (e) {
      return "Error de conexión con la IA: $e";
    }
  }
}
