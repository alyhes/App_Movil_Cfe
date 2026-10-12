
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'login_screen.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() =>
      _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  static const Color verdeCfe = Color(0xFF007A4D);

  bool cargando = true;
  List<Map<String, dynamic>> usuarios = [];

  // La cuenta autorizada para administrar usuarios.
  bool get esAdministradorAutorizado {
    final sesion = SesionUsuario.usuarioActual;

    if (sesion == null) return false;

    return sesion['usuario']
                ?.toString()
                .trim()
                .toUpperCase() ==
            'ADMIN_CFE' &&
        sesion['rol']?.toString() == 'administrador';
  }

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    if (!esAdministradorAutorizado) {
      if (mounted) {
        setState(() {
          cargando = false;
          usuarios = [];
        });
      }
      return;
    }

    try {
      final resultado =
          await DatabaseHelper.instance.obtenerUsuarios();

      if (!mounted) return;

      setState(() {
        usuarios = resultado;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: $e'),
        ),
      );
    }
  }

  // Genera el hash compatible con el formato PBKDF2
  // utilizado por el inicio de sesión de la aplicación.
  Future<String> generarHash(String contrasena) async {
    final aleatorio = Random.secure();

    final salt = List<int>.generate(
      16,
      (_) => aleatorio.nextInt(256),
    );

    const iteraciones = 210000;

    final algoritmo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iteraciones,
      bits: 256,
    );

    final clave = await algoritmo.deriveKey(
      secretKey: SecretKey(utf8.encode(contrasena)),
      nonce: salt,
    );

    final hash = await clave.extractBytes();

    return 'pbkdf2\$'
        '$iteraciones\$'
        '${base64Encode(salt)}\$'
        '${base64Encode(hash)}';
  }

  Future<void> mostrarFormulario({
    Map<String, dynamic>? usuarioExistente,
  }) async {
    if (!esAdministradorAutorizado) return;

    final esEdicion = usuarioExistente != null;

    final nombreController = TextEditingController(
      text: usuarioExistente?['nombre']?.toString() ?? '',
    );

    final usuarioController = TextEditingController(
      text: usuarioExistente?['usuario']?.toString() ?? '',
    );

    final rpeController = TextEditingController(
      text: usuarioExistente?['rpe']?.toString() ?? '',
    );

    final contrasenaController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool mostrarContrasena = false;
    bool guardando = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (contextDialogo, actualizarDialogo) {
              return AlertDialog(
                title: Text(
                  esEdicion
                      ? 'Editar usuario'
                      : 'Agregar usuario',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Escribe el nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: usuarioController,
                          textCapitalization:
                              TextCapitalization.characters,
                          enabled: !esEdicion,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                            prefixIcon: Icon(Icons.account_circle),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            if (valor == null ||
                                valor.trim().isEmpty) {
                              return 'Escribe el usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: rpeController,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'RPE',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (!esEdicion) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: contrasenaController,
                            obscureText: !mostrarContrasena,
                            decoration: InputDecoration(
                              labelText: 'Contraseña inicial',
                              helperText:
                                  'El usuario deberá cambiarla al entrar.',
                              prefixIcon:
                                  const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  actualizarDialogo(() {
                                    mostrarContrasena =
                                        !mostrarContrasena;
                                  });
                                },
                                icon: Icon(
                                  mostrarContrasena
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (valor) {
                              if (valor == null ||
                                  valor.length < 8) {
                                return 'Mínimo 8 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          'Permiso asignado: Usuario normal. '
                          'La administración queda reservada '
                          'a ADMIN_CFE.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: guardando
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: verdeCfe,
                    ),
                    onPressed: guardando
                        ? null
                        : () async {
                            if (!formKey.currentState!
                                .validate()) {
                              return;
                            }

                            actualizarDialogo(() {
                              guardando = true;
                            });

                            try {
                              final nombre =
                                  nombreController.text.trim();
                              final usuario =
                                  usuarioController.text.trim();
                              final rpe =
                                  rpeController.text.trim();

                              if (esEdicion) {
                                await DatabaseHelper.instance
                                    .actualizarUsuario(
                                  usuarioExistente['id'] as int,
                                  {
                                    'nombre': nombre,
                                    'rpe': rpe,
                                  },
                                );
                              } else {
                                final hash = await generarHash(
                                  contrasenaController.text,
                                );

                                await DatabaseHelper.instance
                                    .crearUsuario({
                                  'usuario': usuario,
                                  'nombre': nombre,
                                  'rpe': rpe,
                                  'contrasena_hash': hash,
                                  'rol': 'usuario',
                                  'activo': 1,
                                  'debe_cambiar_contrasena': 1,
                                });
                              }

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.pop(dialogContext);

                              await cargarUsuarios();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    esEdicion
                                        ? 'Usuario actualizado'
                                        : 'Usuario creado correctamente',
                                  ),
                                ),
                              );
                            } catch (e) {
                              actualizarDialogo(() {
                                guardando = false;
                              });

                              if (!dialogContext.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(dialogContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No se pudo guardar. '
                                    'Verifica que el usuario no exista. '
                                    'Detalle: $e',
                                  ),
                                ),
                              );
                            }
                          },
                    child: guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            esEdicion ? 'Guardar' : 'Crear usuario',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nombreController.dispose();
      usuarioController.dispose();
      rpeController.dispose();
      contrasenaController.dispose();
    }
  }

  Future<void> cambiarEstado(
    Map<String, dynamic> usuario,
  ) async {
    if (!esAdministradorAutorizado) return;

    final nombreUsuario =
        usuario['usuario']?.toString().toUpperCase();

    if (nombreUsuario == 'ADMIN_CFE') {
      mostrarMensaje(
        'La cuenta ADMIN_CFE no se puede desactivar desde aquí.',
      );
      return;
    }

    final activo = usuario['activo'] == 1;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          activo ? 'Desactivar usuario' : 'Activar usuario',
        ),
        content: Text(
          activo
              ? '¿Deseas impedir que ${usuario['nombre']} inicie sesión?'
              : '¿Deseas permitir que ${usuario['nombre']} inicie sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await DatabaseHelper.instance.cambiarEstadoUsuario(
      usuario['id'] as int,
      !activo,
    );

    await cargarUsuarios();

    if (!mounted) return;

    mostrarMensaje(
      activo ? 'Usuario desactivado' : 'Usuario activado',
    );
  }

  Future<void> eliminarUsuario(
    Map<String, dynamic> usuario,
  ) async {
    if (!esAdministradorAutorizado) return;

    final nombreUsuario =
        usuario['usuario']?.toString().toUpperCase();

    if (nombreUsuario == 'ADMIN_CFE') {
      mostrarMensaje(
        'No puedes eliminar la cuenta ADMIN_CFE.',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que deseas eliminar la cuenta '
          '${usuario['usuario']}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await DatabaseHelper.instance.eliminarUsuario(
      usuario['id'] as int,
    );

    await cargarUsuarios();

    if (!mounted) return;

    mostrarMensaje('Usuario eliminado');
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!esAdministradorAutorizado) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso restringido'),
          backgroundColor: verdeCfe,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'No tienes permiso para administrar usuarios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de usuarios'),
        backgroundColor: verdeCfe,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: () {
              setState(() => cargando = true);
              cargarUsuarios();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: verdeCfe,
        foregroundColor: Colors.white,
        onPressed: () => mostrarFormulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar usuario'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: cargarUsuarios,
              child: usuarios.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 130),
                        Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Todavía no hay usuarios registrados.',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        12, 12, 12, 100,
                      ),
                      children: [
                        Card(
                          color: const Color(0xFFE8F5EE),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: verdeCfe,
                                  size: 38,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Perfil administrador',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Sesión: ADMIN_CFE',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Usuarios registrados: ${usuarios.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...usuarios.map((usuario) {
                          final esCuentaAdmin =
                              usuario['usuario']
                                      ?.toString()
                                      .toUpperCase() ==
                                  'ADMIN_CFE';

                          final activo = usuario['activo'] == 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: esCuentaAdmin
                                            ? verdeCfe
                                            : Colors.blueGrey,
                                        child: Icon(
                                          esCuentaAdmin
                                              ? Icons.admin_panel_settings
                                              : Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              usuario['nombre']
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Usuario: ${usuario['usuario']}',
                                            ),
                                            Text(
                                              'RPE: ${usuario['rpe'] ?? 'No registrado'}',
                                            ),
                                            const SizedBox(height: 5),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                Chip(
                                                  label: Text(
                                                    esCuentaAdmin
                                                        ? 'Administradora'
                                                        : 'Usuario',
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text(
                                                    activo
                                                        ? 'Activo'
                                                        : 'Inactivo',
                                                  ),
                                                  backgroundColor: activo
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: esCuentaAdmin
                                            ? null
                                            : () => mostrarFormulario(
                                                  usuarioExistente:
                                                      usuario,
                                                ),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Editar'),
                                      ),
                                      TextButton.icon(
                                        onPressed: esCuentaAdmin
                                            ? null
                                            : () => cambiarEstado(
                                                  usuario,
                                                ),
                                        icon: Icon(
                                          activo
                                              ? Icons.person_off
                                              : Icons.person_add_alt_1,
                                        ),
                                        label: Text(
                                          activo
                                              ? 'Desactivar'
                                              : 'Activar',
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: esCuentaAdmin
                                            ? null
                                            : () => eliminarUsuario(
                                                  usuario,
                                                ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Eliminar',
                                          style: TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
