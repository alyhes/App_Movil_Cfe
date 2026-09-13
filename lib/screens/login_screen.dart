import 'package:flutter/material.dart';
import 'inicio_screen.dart';

// ============================================================
// PANTALLA DE INICIO DE SESIÓN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores
  final TextEditingController usuarioController =
      TextEditingController();

  final TextEditingController contrasenaController =
      TextEditingController();

  // Para mostrar u ocultar la contraseña
  bool mostrarContrasena = false;

  // ============================================================
  // INICIAR SESIÓN
  // ============================================================

  void iniciarSesion() {
    final usuario = usuarioController.text.trim();
    final contrasena = contrasenaController.text;

    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa usuario y contraseña'),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // USUARIO DE PRUEBA
    // ----------------------------------------------------------
    // Más adelante esto se conectará con la API y PostgreSQL.
    if (usuario == 'admin' && contrasena == '123456') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InicioScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrectos'),
        ),
      );
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ------------------------------------------------
                // ENCABEZADO
                // ------------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A4D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.electrical_services,
                        color: Colors.white,
                        size: 55,
                      ),

                      SizedBox(height: 12),

                      Text(
                        'INSPECCIONES CFE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Sistema de Gestión de Inspecciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ------------------------------------------------
                // TÍTULO
                // ------------------------------------------------

                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Ingresa tus datos para continuar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // USUARIO
                // ------------------------------------------------

                TextField(
                  controller: usuarioController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    hintText: 'Ingresa tu usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // CONTRASEÑA
                // ------------------------------------------------

                TextField(
                  controller: contrasenaController,
                  obscureText: !mostrarContrasena,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => iniciarSesion(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        mostrarContrasena
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          mostrarContrasena = !mostrarContrasena;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // BOTÓN INICIAR SESIÓN
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A4D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ------------------------------------------------
                // PIE
                // ------------------------------------------------

                const Text(
                  'Sistema de Inspecciones CFE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
