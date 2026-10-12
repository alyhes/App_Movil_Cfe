
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'inicio_screen.dart';

// ============================================================
// SESIÓN DEL USUARIO
// ============================================================

class SesionUsuario {
  static Map<String, dynamic>? usuarioActual;
}

// ============================================================
// SERVICIO PARA GENERAR Y COMPROBAR CONTRASEÑAS
// ============================================================

class ServicioContrasenas {
  static const int _iteraciones = 210000;

  static final Pbkdf2 _algoritmo = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iteraciones,
    bits: 256,
  );

  static Future<String> generarHash(String contrasena) async {
    final random = Random.secure();

    final salt = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    final clave = await _algoritmo.deriveKey(
      secretKey: SecretKey(utf8.encode(contrasena)),
      nonce: salt,
    );

    final bytes = await clave.extractBytes();

    return 'pbkdf2'
        '\$$_iteraciones'
        '\$${base64Encode(salt)}'
        '\$${base64Encode(bytes)}';
  }

  static Future<bool> verificar(
    String contrasena,
    String hashGuardado,
  ) async {
    try {
      final partes = hashGuardado.split(r'$');

      if (partes.length != 4 || partes[0] != 'pbkdf2') {
        return false;
      }

      final iteraciones = int.parse(partes[1]);
      final salt = base64Decode(partes[2]);
      final hashOriginal = base64Decode(partes[3]);

      final algoritmo = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iteraciones,
        bits: hashOriginal.length * 8,
      );

      final clave = await algoritmo.deriveKey(
        secretKey: SecretKey(utf8.encode(contrasena)),
        nonce: salt,
      );

      final bytesCalculados = await clave.extractBytes();

      return _compararBytes(bytesCalculados, hashOriginal);
    } catch (_) {
      return false;
    }
  }

  static bool _compararBytes(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    int diferencia = 0;

    for (int i = 0; i < a.length; i++) {
      diferencia |= a[i] ^ b[i];
    }

    return diferencia == 0;
  }
}

// ============================================================
// PANTALLA DE INICIO DE SESIÓN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioController =
      TextEditingController();

  final TextEditingController _contrasenaController =
      TextEditingController();

  bool _cargando = false;
  bool _mostrarContrasena = false;

  static const Color verdeCfe = Color(0xFF007A4D);

  @override
  void initState() {
    super.initState();
    prepararUsuariosIniciales();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PREPARAR CUENTAS INICIALES
  // ==========================================================

  Future<void> prepararUsuariosIniciales() async {
    try {
      final db = DatabaseHelper.instance;

      final habiaUsuarios = await db.existenUsuarios();

      if (habiaUsuarios) {
        // Si ya existen usuarios, no se recrean las cuentas.
        // Tampoco se modifica ninguna contraseña.
        final adminCfe =
            await db.obtenerUsuarioPorNombre('ADMIN_CFE');

        if (adminCfe == null) {
          final hayAdministrador = await db.existeAdministrador();

          if (!hayAdministrador) {
            await _crearAdministradorInicial();
          }
        }

        return;
      }

      // Solo se crean las cuentas iniciales si la tabla está vacía.
      await _crearAdministradorInicial();

      final cuentasAnteriores = [
        '9AW7P',
        '9AW8B',
        '9AWAA',
      ];

      for (final usuario in cuentasAnteriores) {
        final hash =
            await ServicioContrasenas.generarHash(usuario);

        await db.crearUsuario({
          'usuario': usuario,
          'nombre': usuario,
          'rpe': usuario,
          'contrasena_hash': hash,
          'rol': 'usuario',
          'activo': 1,
          'debe_cambiar_contrasena': 1,
        });
      }
    } catch (e) {
      debugPrint('Error al preparar usuarios: $e');
    }
  }

  // ==========================================================
  // CREAR ADMINISTRADOR INICIAL
  // ==========================================================

  Future<void> _crearAdministradorInicial() async {
    final db = DatabaseHelper.instance;

    final hash = await ServicioContrasenas.generarHash(
      'CFE_Admin_2026!',
    );

    await db.crearUsuario({
      'usuario': 'ADMIN_CFE',
      'nombre': 'Administradora inicial',
      'rpe': 'ADMIN_CFE',
      'contrasena_hash': hash,
      'rol': 'administrador',
      'activo': 1,
      'debe_cambiar_contrasena': 1,
    });
  }

  // ==========================================================
  // MOSTRAR MENSAJES
  // ==========================================================

  void _mostrarMensaje(
    String mensaje,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // INICIAR SESIÓN
  // ==========================================================

  Future<void> iniciarSesion() async {
    final usuario =
        _usuarioController.text.trim().toUpperCase();

    final contrasena = _contrasenaController.text;

    if (usuario.isEmpty || contrasena.isEmpty) {
      _mostrarMensaje(
        'Escribe tu usuario y contraseña.',
        Colors.orange.shade800,
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      await prepararUsuariosIniciales();

      final db = DatabaseHelper.instance;

      final cuenta =
          await db.obtenerUsuarioPorNombre(usuario);

      if (cuenta == null) {
        _mostrarMensaje(
          'El usuario o la contraseña son incorrectos.',
          Colors.red,
        );
        return;
      }

      final activo = cuenta['activo'];

      if (activo != 1) {
        _mostrarMensaje(
          'Esta cuenta está desactivada. '
          'Contacta a la administradora.',
          Colors.red,
        );
        return;
      }

      final hashGuardado =
          cuenta['contrasena_hash']?.toString() ?? '';

      final contrasenaValida =
          await ServicioContrasenas.verificar(
        contrasena,
        hashGuardado,
      );

      if (!contrasenaValida) {
        _mostrarMensaje(
          'El usuario o la contraseña son incorrectos.',
          Colors.red,
        );
        return;
      }

      // ------------------------------------------------------
      // ASIGNAR ADMINISTRADOR A LA CUENTA EXISTENTE
      // ------------------------------------------------------
      // La contraseña ya fue comprobada.
      // No se genera ni se cambia ningún hash.
      // Solo se actualizan el rol y el estado de ADMIN_CFE.

      if (usuario == 'ADMIN_CFE') {
        final actualizados =
            await db.asignarRolAdministradorCfe();

        if (actualizados != 1) {
          _mostrarMensaje(
            'No se pudo actualizar el perfil administrador.',
            Colors.red,
          );
          return;
        }
      }

      // Consultar nuevamente para recuperar el rol actualizado.
      final datosSesion =
          await db.obtenerUsuarioPorNombre(usuario);

      if (datosSesion == null) {
        _mostrarMensaje(
          'No se pudieron recuperar los datos de la cuenta.',
          Colors.red,
        );
        return;
      }

      // Guardar los datos reales de la cuenta en la sesión.
      SesionUsuario.usuarioActual =
          Map<String, dynamic>.from(datosSesion);

      final debeCambiar =
          datosSesion['debe_cambiar_contrasena'] == 1;

      if (!mounted) return;

      if (debeCambiar) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CambiarContrasenaScreen(
              usuario: Map<String, dynamic>.from(datosSesion),
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const InicioScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');

      _mostrarMensaje(
        'Ocurrió un error al iniciar sesión. '
        'Verifica la conexión con la base de datos.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  // ==========================================================
  // INTERFAZ DEL INICIO DE SESIÓN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      24,
                    ),
                    decoration: BoxDecoration(
                      color: verdeCfe,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 115,
                          width: 115,
                          child: CustomPaint(
                            painter: TorreCfePainter(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'INSPECCIONES CFE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inspección de Líneas de Transmisión',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Dirección de Operación',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Iniciar sesión',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: verdeCfe,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingresa tus datos para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _usuarioController,
                            textCapitalization:
                                TextCapitalization.characters,
                            autocorrect: false,
                            enabled: !_cargando,
                            onSubmitted: (_) => iniciarSesion(),
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              hintText: 'Escribe tu usuario',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: verdeCfe,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: verdeCfe,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _contrasenaController,
                            obscureText: !_mostrarContrasena,
                            enabled: !_cargando,
                            onSubmitted: (_) => iniciarSesion(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Escribe tu contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: verdeCfe,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _mostrarContrasena
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () {
                                  setState(() {
                                    _mostrarContrasena =
                                        !_mostrarContrasena;
                                  });
                                },
                                icon: Icon(
                                  _mostrarContrasena
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: verdeCfe,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _cargando ? null : iniciarSesion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: verdeCfe,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _cargando
                                  ? const SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'ENTRAR',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sistema de Inspecciones CFE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerencia Regional de Transmisión Peninsular',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CAMBIAR CONTRASEÑA
// ============================================================

class CambiarContrasenaScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const CambiarContrasenaScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends State<CambiarContrasenaScreen> {
  final TextEditingController _nuevaController =
      TextEditingController();

  final TextEditingController _confirmarController =
      TextEditingController();

  bool _cargando = false;
  bool _mostrarContrasenas = false;

  static const Color verdeCfe = Color(0xFF007A4D);

  @override
  void dispose() {
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _mensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
        ),
      );
  }

  Future<void> guardarNuevaContrasena() async {
    final nueva = _nuevaController.text;
    final confirmar = _confirmarController.text;

    if (nueva.isEmpty || confirmar.isEmpty) {
      _mensaje(
        'Completa los dos campos de contraseña.',
        Colors.orange.shade800,
      );
      return;
    }

    if (nueva.length < 8) {
      _mensaje(
        'La contraseña debe tener al menos 8 caracteres.',
        Colors.orange.shade800,
      );
      return;
    }

    if (nueva != confirmar) {
      _mensaje(
        'Las contraseñas no coinciden.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final id = widget.usuario['id'];

      final hash =
          await ServicioContrasenas.generarHash(nueva);

      await DatabaseHelper.instance.cambiarContrasenaUsuario(
        id,
        hash,
      );

      final cuentaActualizada =
          await DatabaseHelper.instance.obtenerUsuarioPorNombre(
        widget.usuario['usuario'].toString(),
      );

      if (cuentaActualizada == null) {
        _mensaje(
          'La contraseña se guardó, pero no se pudieron '
          'recuperar los datos de la cuenta.',
          Colors.orange.shade800,
        );
        return;
      }

      SesionUsuario.usuarioActual =
          Map<String, dynamic>.from(cuentaActualizada);

      if (!mounted) return;

      _mensaje(
        'Contraseña actualizada correctamente.',
        verdeCfe,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const InicioScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error al cambiar contraseña: $e');

      _mensaje(
        'No se pudo actualizar la contraseña.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: verdeCfe,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Cambiar contraseña'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 65,
                      color: verdeCfe,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Actualiza tu contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: verdeCfe,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Usuario: ${widget.usuario['usuario']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nuevaController,
                      obscureText: !_mostrarContrasenas,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmarController,
                      obscureText: !_mostrarContrasenas,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _mostrarContrasenas,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Mostrar contraseñas',
                        style: TextStyle(fontSize: 15),
                      ),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      activeColor: verdeCfe,
                      onChanged: (valor) {
                        setState(() {
                          _mostrarContrasenas = valor ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando
                            ? null
                            : guardarNuevaContrasena,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verdeCfe,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'GUARDAR CONTRASEÑA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIBUJO DECORATIVO DE UNA TORRE ELÉCTRICA
// ============================================================

class TorreCfePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centro = size.width / 2;

    final punta = Offset(centro, size.height * 0.08);
    final pieIzquierdo = Offset(size.width * 0.17, size.height * 0.92);
    final pieDerecho = Offset(size.width * 0.83, size.height * 0.92);

    final torre = Path()
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(pieIzquierdo.dx, pieIzquierdo.dy)
      ..moveTo(punta.dx, punta.dy)
      ..lineTo(pieDerecho.dx, pieDerecho.dy)
      ..moveTo(size.width * 0.31, size.height * 0.55)
      ..lineTo(size.width * 0.69, size.height * 0.55)
      ..moveTo(size.width * 0.24, size.height * 0.73)
      ..lineTo(size.width * 0.76, size.height * 0.73)
      ..moveTo(size.width * 0.37, size.height * 0.36)
      ..lineTo(size.width * 0.63, size.height * 0.36)
      ..moveTo(size.width * 0.30, size.height * 0.55)
      ..lineTo(size.width * 0.70, size.height * 0.73)
      ..moveTo(size.width * 0.70, size.height * 0.55)
      ..lineTo(size.width * 0.30, size.height * 0.73)
      ..moveTo(size.width * 0.24, size.height * 0.73)
      ..lineTo(size.width * 0.76, size.height * 0.92)
      ..moveTo(size.width * 0.76, size.height * 0.73)
      ..lineTo(size.width * 0.24, size.height * 0.92)
      ..moveTo(size.width * 0.40, size.height * 0.36)
      ..lineTo(size.width * 0.60, size.height * 0.55)
      ..moveTo(size.width * 0.60, size.height * 0.36)
      ..lineTo(size.width * 0.40, size.height * 0.55)
      ..moveTo(size.width * 0.10, size.height * 0.27)
      ..lineTo(size.width * 0.90, size.height * 0.27)
      ..moveTo(size.width * 0.03, size.height * 0.32)
      ..lineTo(size.width * 0.97, size.height * 0.32)
      ..moveTo(size.width * 0.10, size.height * 0.27)
      ..lineTo(size.width * 0.22, size.height * 0.32)
      ..moveTo(size.width * 0.90, size.height * 0.27)
      ..lineTo(size.width * 0.78, size.height * 0.32);

    canvas.drawPath(torre, pintura);

    final aislador = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final x in [
      size.width * 0.10,
      size.width * 0.30,
      size.width * 0.70,
      size.width * 0.90,
    ]) {
      canvas.drawCircle(
        Offset(x, size.height * 0.35),
        2.5,
        aislador,
      );
    }

    final suelo = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.94),
      Offset(size.width * 0.92, size.height * 0.94),
      suelo,
    );
  }

  @override
  bool shouldRepaint(covariant TorreCfePainter oldDelegate) {
    return false;
  }
}
