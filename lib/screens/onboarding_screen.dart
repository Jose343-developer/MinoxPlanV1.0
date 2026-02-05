import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart'; // Importamos el servicio de IA
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- VARIABLES DE RESPUESTA ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  bool? _usesMinoxidil; 
  int _minoxFrequency = 1; 
  List<String> _selectedProducts = [];
  
  // VARIABLES DE TIEMPO (Hora de Despertar y Dormir)
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);

  // Opciones de productos
  final List<Map<String, dynamic>> _productsOptions = [
    {"name": "Acondicionador", "icon": Icons.water_drop},
    {"name": "Aceite para barba", "icon": Icons.opacity},
    {"name": "Bálsamo", "icon": Icons.spa},
    {"name": "Cera", "icon": Icons.face},
    {"name": "Tónico", "icon": Icons.science},
    {"name": "Protector Solar", "icon": Icons.wb_sunny},
    {"name": "Dermaroller", "icon": Icons.grid_on},
  ];

  // --- FUNCIÓN PRINCIPAL: FINALIZAR Y LLAMAR A LA IA ---
  Future<void> _finishOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Mostrar círculo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );

    try {
      // 2. PEDIR LA RUTINA A LA IA 🧠
      final aiService = AIService();
      String aiRoutine = await aiService.createRoutine(
        name: _nameController.text,
        wakeTime: "${_wakeTime.hour}:${_wakeTime.minute}",
        sleepTime: "${_sleepTime.hour}:${_sleepTime.minute}",
        usesMinoxidil: _usesMinoxidil ?? false,
        products: _selectedProducts,
      );

      // 3. GUARDAR TODO EN FIREBASE
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'uses_minoxidil': _usesMinoxidil,
        'minox_frequency': _usesMinoxidil == true ? _minoxFrequency : 0,
        'routine_products': _selectedProducts,
        'wake_time': '${_wakeTime.hour}:${_wakeTime.minute}',
        'sleep_time': '${_sleepTime.hour}:${_sleepTime.minute}',
        'ai_generated_routine': aiRoutine, // Guardamos la respuesta de la IA
        'onboarding_completed': true,
      });

      // 4. CERRAR CARGA E IR AL HOME
      if (mounted) {
        Navigator.pop(context); // Quita el círculo
        Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (context) => const HomeScreen()), 
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Quita el círculo si falla
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Paso ${_currentPage + 1} de 4", style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildCard1_Profile(),
          _buildCard2_Minoxidil(),
          _buildCard3_Products(),
          _buildCard4_Time(), // <--- ESTA ES LA QUE CAMBIÓ
        ],
      ),
    );
  }

  // --- TARJETA 1: DATOS ---
  Widget _buildCard1_Profile() {
    return _baseCard(
      title: "¿Quién eres, Bro?",
      subtitle: "Para personalizar tu plan",
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Tu Nombre o Apodo", prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37))),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Tu Edad", prefixIcon: Icon(Icons.cake, color: Color(0xFFD4AF37))),
          ),
          const Spacer(),
          _nextButton(onPressed: () {
            if (_nameController.text.isNotEmpty) _nextPage();
          }),
        ],
      ),
    );
  }

  // --- TARJETA 2: MINOXIDIL ---
  Widget _buildCard2_Minoxidil() {
    return _baseCard(
      title: "La pregunta del millón",
      subtitle: "¿Usas Minoxidil actualmente?",
      child: Column(
        children: [
          const SizedBox(height: 20),
          _selectionTile(
            text: "Sí, soy del club",
            isSelected: _usesMinoxidil == true,
            onTap: () => setState(() => _usesMinoxidil = true),
          ),
          const SizedBox(height: 10),
          _selectionTile(
            text: "No, solo natural",
            isSelected: _usesMinoxidil == false,
            onTap: () => setState(() => _usesMinoxidil = false),
          ),
          if (_usesMinoxidil == true) ...[
            const SizedBox(height: 30),
            const Text("¿Frecuencia diaria?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _frequencyButton(1),
                const SizedBox(width: 20),
                _frequencyButton(2),
              ],
            )
          ],
          const Spacer(),
          _nextButton(onPressed: () {
            if (_usesMinoxidil != null) _nextPage();
          }),
        ],
      ),
    );
  }

  // --- TARJETA 3: PRODUCTOS ---
  Widget _buildCard3_Products() {
    return _baseCard(
      title: "Tu Arsenal",
      subtitle: "Selecciona tus productos",
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _productsOptions.length,
              itemBuilder: (context, index) {
                final product = _productsOptions[index];
                final isSelected = _selectedProducts.contains(product['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) _selectedProducts.remove(product['name']);
                      else _selectedProducts.add(product['name']);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(product['icon'], color: isSelected ? Colors.black : Colors.white),
                        const SizedBox(width: 8),
                        Text(product['name'], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _nextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  // --- TARJETA 4: HORARIOS (ACTUALIZADA) ---
  Widget _buildCard4_Time() {
    return _baseCard(
      title: "Sincronización",
      subtitle: "La IA necesita tu horario para armar la rutina.",
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Reloj 1: Despertar
          _timeSelector(
            title: "Me levanto a las:",
            time: _wakeTime,
            icon: Icons.wb_sunny_outlined,
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _wakeTime);
              if (picked != null) setState(() => _wakeTime = picked);
            },
          ),
          const SizedBox(height: 20),
          // Reloj 2: Dormir
          _timeSelector(
            title: "Me duermo a las:",
            time: _sleepTime,
            icon: Icons.nights_stay_outlined,
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _sleepTime);
              if (picked != null) setState(() => _sleepTime = picked);
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _finishOnboarding, // <--- Llama a la IA
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("CREAR RUTINA INTELIGENTE 🤖", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE ESTILO ---
  Widget _baseCard({required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _nextButton({required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text("SIGUIENTE", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _selectionTile({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.grey[900],
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _frequencyButton(int times) {
    bool isSelected = _minoxFrequency == times;
    return GestureDetector(
      onTap: () => setState(() => _minoxFrequency = times),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("$times vez", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _timeSelector({required String title, required TimeOfDay time, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}