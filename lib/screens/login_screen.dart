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
  // ==========================================================
  // CONTROLADORES
  // ==========================================================

  final TextEditingController usuarioController =
      TextEditingController();

  final TextEditingController contrasenaController =
      TextEditingController();

  // ==========================================================
  // MOSTRAR / OCULTAR CONTRASEÑA
  // ==========================================================

  bool mostrarContrasena = false;

  // ==========================================================
  // USUARIOS AUTORIZADOS
  // ==========================================================
  //
  // Estos son los usuarios que podrán entrar a la aplicación.
  //
  // Usuario 1: 9AW7P
  // Usuario 2: 9AW8B
  // Usuario 3: 9AWAA
  //
  // Los tres utilizan la misma contraseña:
  // Transmision1
  //
  // ==========================================================

  final Map<String, String> usuariosAutorizados = {
    '9AW7P': 'Transmision1',
    '9AW8B': 'Transmision1',
    '9AWAA': 'Transmision1',
  };

  // ==========================================================
  // INICIAR SESIÓN
  // ==========================================================

  void iniciarSesion() {
    final usuario =
        usuarioController.text.trim().toUpperCase();

    final contrasena =
        contrasenaController.text;

    // ========================================================
    // COMPROBAR CAMPOS VACÍOS
    // ========================================================

    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa usuario y contraseña',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // ========================================================
    // COMPROBAR USUARIO Y CONTRASEÑA
    // ========================================================

    final usuarioValido =
        usuariosAutorizados.containsKey(usuario);

    final contrasenaValida =
        usuarioValido &&
        usuariosAutorizados[usuario] == contrasena;

    // ========================================================
    // ACCESO CORRECTO
    // ========================================================

    if (contrasenaValida) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const InicioScreen(),
        ),
      );

      return;
    }

    // ========================================================
    // ACCESO INCORRECTO
    // ========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Usuario o contraseña incorrectos',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ==========================================================
  // LIBERAR CONTROLADORES
  // ==========================================================

  @override
  void dispose() {
    usuarioController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // INTERFAZ
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                // ==================================================
                // ENCABEZADO CFE
                // ==================================================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFF007A4D),

                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: Column(
                    children: [

                      // ==================================================
                      // TORRE ELÉCTRICA
                      // ==================================================

                      SizedBox(
                        width: 100,
                        height: 100,

                        child: CustomPaint(
                          painter:
                              TorreCfePainter(),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // TÍTULO
                      // ==================================================

                      const Text(
                        'INSPECCIONES CFE',

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      const Text(
                        'Sistema de Gestión de Inspecciones',

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                // ==================================================
                // TÍTULO
                // ==================================================

                const Text(
                  'Iniciar sesión',

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Ingresa tus datos para continuar',

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // USUARIO
                // ==================================================

                TextField(
                  controller:
                      usuarioController,

                  keyboardType:
                      TextInputType.text,

                  textInputAction:
                      TextInputAction.next,

                  textCapitalization:
                      TextCapitalization.characters,

                  decoration:
                      InputDecoration(
                    labelText:
                        'Usuario',

                    hintText:
                        'Ingresa tu usuario',

                    prefixIcon:
                        const Icon(
                      Icons.person_outline,
                      color:
                          Color(0xFF007A4D),
                    ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF007A4D),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // CONTRASEÑA
                // ==================================================

                TextField(
                  controller:
                      contrasenaController,

                  obscureText:
                      !mostrarContrasena,

                  textInputAction:
                      TextInputAction.done,

                  onSubmitted: (_) =>
                      iniciarSesion(),

                  decoration:
                      InputDecoration(
                    labelText:
                        'Contraseña',

                    hintText:
                        'Ingresa tu contraseña',

                    prefixIcon:
                        const Icon(
                      Icons.lock_outline,
                      color:
                          Color(0xFF007A4D),
                    ),

                    suffixIcon:
                        IconButton(
                      icon: Icon(
                        mostrarContrasena
                            ? Icons
                                .visibility_off
                            : Icons
                                .visibility,
                        color:
                            const Color(
                          0xFF007A4D,
                        ),
                      ),

                      onPressed: () {
                        setState(() {
                          mostrarContrasena =
                              !mostrarContrasena;
                        });
                      },
                    ),

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF007A4D),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==================================================
                // BOTÓN INICIAR SESIÓN
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  height: 52,

                  child:
                      ElevatedButton(
                    onPressed:
                        iniciarSesion,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF007A4D,
                      ),

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),

                    child:
                        const Text(
                      'Iniciar sesión',

                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // PIE
                // ==================================================

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

// ============================================================
// DIBUJO DE TORRE ELÉCTRICA CFE
// ============================================================

class TorreCfePainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap =
              StrokeCap.round;

    final double centro =
        size.width / 2;

    final double arriba = 8;
    final double abajo =
        size.height - 8;

    // ========================================================
    // CUERPO PRINCIPAL DE LA TORRE
    // ========================================================

    final Path torre =
        Path();

    torre.moveTo(
      centro - 10,
      arriba,
    );

    torre.lineTo(
      centro - 38,
      abajo,
    );

    torre.moveTo(
      centro + 10,
      arriba,
    );

    torre.lineTo(
      centro + 38,
      abajo,
    );

    canvas.drawPath(
      torre,
      paint,
    );

    // ========================================================
    // PARTE SUPERIOR
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 10,
        arriba,
      ),
      Offset(
        centro - 25,
        22,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro + 10,
        arriba,
      ),
      Offset(
        centro + 25,
        22,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro - 25,
        22,
      ),
      Offset(
        centro + 25,
        22,
      ),
      paint,
    );

    // ========================================================
    // BRAZOS DE LA TORRE
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 25,
        22,
      ),
      Offset(
        centro - 45,
        32,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro + 25,
        22,
      ),
      Offset(
        centro + 45,
        32,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro - 45,
        32,
      ),
      Offset(
        centro + 45,
        32,
      ),
      paint,
    );

    // ========================================================
    // NIVEL MEDIO
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 20,
        43,
      ),
      Offset(
        centro + 20,
        43,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro - 27,
        55,
      ),
      Offset(
        centro + 27,
        55,
      ),
      paint,
    );

    // ========================================================
    // NIVEL INFERIOR
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 32,
        68,
      ),
      Offset(
        centro + 32,
        68,
      ),
      paint,
    );

    // ========================================================
    // REFUERZOS DIAGONALES
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 38,
        abajo,
      ),
      Offset(
        centro + 20,
        43,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro + 38,
        abajo,
      ),
      Offset(
        centro - 20,
        43,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro - 30,
        65,
      ),
      Offset(
        centro + 28,
        65,
      ),
      paint,
    );

    // ========================================================
    // BASE
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 38,
        abajo,
      ),
      Offset(
        centro + 38,
        abajo,
      ),
      paint,
    );

    // ========================================================
    // CABLES SUPERIORES
    // ========================================================

    canvas.drawLine(
      Offset(
        centro - 45,
        32,
      ),
      Offset(
        centro - 48,
        40,
      ),
      paint,
    );

    canvas.drawLine(
      Offset(
        centro + 45,
        32,
      ),
      Offset(
        centro + 48,
        40,
      ),
      paint,
    );

    // ========================================================
    // PEQUEÑOS AISLADORES
    // ========================================================

    canvas.drawCircle(
      Offset(
        centro - 48,
        40,
      ),
      3,
      paint,
    );

    canvas.drawCircle(
      Offset(
        centro + 48,
        40,
      ),
      3,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}