import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'inspecciones_guardadas_screen.dart';
import 'login_screen.dart';
import 'admin_usuarios_screen.dart';

const Color verdeCfe = Color(0xFF007A4D);

String _fechaHoyFormateada() {
  final fecha = DateTime.now();
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

String _formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _LineaTransmision {
  final String codigo;
  final String tramo;
  final int torreInicial;
  final int torreFinal;

  const _LineaTransmision({
    required this.codigo,
    required this.tramo,
    required this.torreInicial,
    required this.torreFinal,
  });

  String get nombreCompleto => '$codigo ($tramo)';
}

/// Una fila representa UNA anomalía.
class _FilaAnomalia {
  final String torre;
  final TextEditingController fechaRevisionController;
  final TextEditingController anomaliaController;
  final TextEditingController fechaCorreccionController;

  _FilaAnomalia({required this.torre})
      : fechaRevisionController =
            TextEditingController(text: _fechaHoyFormateada()),
        anomaliaController = TextEditingController(),
        fechaCorreccionController = TextEditingController();

  void dispose() {
    fechaRevisionController.dispose();
    anomaliaController.dispose();
    fechaCorreccionController.dispose();
  }
}

class _InicioScreenState extends State<InicioScreen> {
  DateTime? fechaSeleccionada = DateTime.now();

  String? voltajeSeleccionado;
  _LineaTransmision? lineaSeleccionada;
  String? zonaSeleccionada;

  // Nuevos campos de características de la torre.
  String? tipoTorreSeleccionado;
  String? tipoCimentacionSeleccionado;

  final List<String> tiposTorre = const [
    'Suspensión',
    'Remate',
    'Flexión',
    'Transposición',
  ];

  final List<String> tiposCimentacion = const [
    'Acero',
    'Madera',
    'Concreto',
  ];

  final TextEditingController tipoInspeccionController =
      TextEditingController();
  final TextEditingController buscadorTorreController =
      TextEditingController();
  final TextEditingController elaboroNombreController =
      TextEditingController();
  final TextEditingController elaboroRpeController =
      TextEditingController();
  final TextEditingController voBoNombreController =
      TextEditingController();
  final TextEditingController voBoRpeController =
      TextEditingController();

  final List<String> tiposInspeccion = const [
    'Inspección Mayor',
    'Inspección Menor',
    'Patrullaje',
    'Aéreo',
  ];

  final List<String> zonasTransmision = const [
    'Escárcega',
    'Santa Lucía',
  ];

  final List<String> voltajes = const [
    '115 kV',
    '230 kV',
    '400 kV',
  ];

  final List<String> torresSeleccionadas = [];

  // Ahora puede haber varias filas para una misma torre.
  final List<_FilaAnomalia> filasAnomalias = [];

  String busquedaTorre = '';
  bool guardando = false;

  bool get esAdministrador {
    final usuario = SesionUsuario.usuarioActual;
    if (usuario == null) return false;

    return usuario['usuario']?.toString().toUpperCase() ==
            'ADMIN_CFE' &&
        usuario['rol']?.toString() == 'administrador';
  }

  final List<_LineaTransmision> lineas115 = const [
    _LineaTransmision(
      codigo: '73120',
      tramo: 'ESA-CMO',
      torreInicial: 1,
      torreFinal: 326,
    ),
    _LineaTransmision(
      codigo: '73130',
      tramo: 'CMO-SBY',
      torreInicial: 1,
      torreFinal: 198,
    ),
    _LineaTransmision(
      codigo: '73150',
      tramo: 'ESA-SBY',
      torreInicial: 1,
      torreFinal: 180,
    ),
    _LineaTransmision(
      codigo: '73160',
      tramo: 'SBY-CRE',
      torreInicial: 1,
      torreFinal: 219,
    ),
    _LineaTransmision(
      codigo: '73170',
      tramo: 'SBY-CRE',
      torreInicial: 1,
      torreFinal: 219,
    ),
    _LineaTransmision(
      codigo: '73180',
      tramo: 'CNR-LTE',
      torreInicial: 1,
      torreFinal: 19,
    ),
    _LineaTransmision(
      codigo: '73190',
      tramo: 'ESA-SBY',
      torreInicial: 1,
      torreFinal: 134,
    ),
    _LineaTransmision(
      codigo: '73A10',
      tramo: 'CRE-LTE',
      torreInicial: 1,
      torreFinal: 45,
    ),
    _LineaTransmision(
      codigo: '73A40',
      tramo: 'ESA-XPU',
      torreInicial: 1,
      torreFinal: 455,
    ),
    _LineaTransmision(
      codigo: '73A70',
      tramo: 'CNR-CRE',
      torreInicial: 1,
      torreFinal: 63,
    ),
    _LineaTransmision(
      codigo: '73A90',
      tramo: 'CAS-ESA',
      torreInicial: 1,
      torreFinal: 394,
    ),
  ];

  final List<_LineaTransmision> lineas230 = const [
    _LineaTransmision(
      codigo: '93010',
      tramo: 'ESA-LRA',
      torreInicial: 1,
      torreFinal: 215,
    ),
    _LineaTransmision(
      codigo: '93100',
      tramo: 'ESA-XUL',
      torreInicial: 1,
      torreFinal: 455,
    ),
    _LineaTransmision(
      codigo: '93210',
      tramo: 'KAH-ESA',
      torreInicial: 31,
      torreFinal: 374,
    ),
    _LineaTransmision(
      codigo: '93200',
      tramo: 'SLC-KAH',
      torreInicial: 1,
      torreFinal: 32,
    ),
    _LineaTransmision(
      codigo: '93220',
      tramo: 'SLC-ESA',
      torreInicial: 1,
      torreFinal: 374,
    ),
  ];

  final List<_LineaTransmision> lineas400 = const [
    _LineaTransmision(
      codigo: 'A3Q00',
      tramo: 'TSP-ESA',
      torreInicial: 369,
      torreFinal: 712,
    ),
    _LineaTransmision(
      codigo: 'A3Q10',
      tramo: 'TSP-ESA',
      torreInicial: 369,
      torreFinal: 712,
    ),
    _LineaTransmision(
      codigo: 'A3Q20',
      tramo: 'ESA-TIC',
      torreInicial: 1,
      torreFinal: 223,
    ),
    _LineaTransmision(
      codigo: 'A3Q30',
      tramo: 'ESA-TIC',
      torreInicial: 1,
      torreFinal: 223,
    ),
  ];

  List<_LineaTransmision> obtenerLineas() {
    switch (voltajeSeleccionado) {
      case '115 kV':
        return lineas115;
      case '230 kV':
        return lineas230;
      case '400 kV':
        return lineas400;
      default:
        return [];
    }
  }

  List<String> obtenerTorres() {
    if (lineaSeleccionada == null) return [];

    final inicio = lineaSeleccionada!.torreInicial;
    final fin = lineaSeleccionada!.torreFinal;

    return List.generate(
      fin - inicio + 1,
      (index) => 'T-${(inicio + index).toString().padLeft(3, '0')}',
    );
  }

  List<String> obtenerTorresFiltradas() {
    final texto = busquedaTorre.trim().toLowerCase();

    if (texto.isEmpty) return obtenerTorres();

    return obtenerTorres()
        .where((torre) => torre.toLowerCase().contains(texto))
        .toList();
  }

  void actualizarFilasTorres() {
    for (final fila in filasAnomalias) {
      fila.dispose();
    }

    filasAnomalias.clear();

    // Cada torre seleccionada empieza con una sola anomalía.
    for (final torre in torresSeleccionadas) {
      filasAnomalias.add(_FilaAnomalia(torre: torre));
    }
  }

  void cambiarSeleccionTorre(String torre) {
    setState(() {
      if (torresSeleccionadas.contains(torre)) {
        torresSeleccionadas.remove(torre);
      } else {
        torresSeleccionadas.add(torre);
      }

      actualizarFilasTorres();
    });
  }

  void limpiarTorresSeleccionadas() {
    setState(() {
      torresSeleccionadas.clear();
      actualizarFilasTorres();
    });
  }

  /// Agrega una anomalía nueva a la misma torre.
  void agregarAnomalia(String torre) {
    setState(() {
      final nuevaFila = _FilaAnomalia(torre: torre);

      // Insertar debajo de la última fila de esa torre.
      final indices = <int>[];

      for (int i = 0; i < filasAnomalias.length; i++) {
        if (filasAnomalias[i].torre == torre) {
          indices.add(i);
        }
      }

      if (indices.isEmpty) {
        filasAnomalias.add(nuevaFila);
      } else {
        filasAnomalias.insert(indices.last + 1, nuevaFila);
      }
    });

    _mostrarMensaje('Se agregó otra anomalía a $torre.');
  }

  void eliminarAnomalia(_FilaAnomalia fila) {
    final filasDeEstaTorre =
        filasAnomalias.where((item) => item.torre == fila.torre).length;

    if (filasDeEstaTorre <= 1) {
      _mostrarMensaje(
        'Cada torre debe conservar al menos una fila.',
        esError: true,
      );
      return;
    }

    setState(() {
      filasAnomalias.remove(fila);
      fila.dispose();
    });
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null && mounted) {
      setState(() => fechaSeleccionada = fecha);
    }
  }

  Future<void> seleccionarFechaRevision(_FilaAnomalia fila) async {
    DateTime fechaInicial = DateTime.now();
    final partes = fila.fechaRevisionController.text.split('/');

    if (partes.length == 3) {
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final anio = int.tryParse(partes[2]);

      if (dia != null && mes != null && anio != null) {
        fechaInicial = DateTime(anio, mes, dia);
      }
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null && mounted) {
      setState(() {
        fila.fechaRevisionController.text = _formatearFecha(fecha);
      });
    }
  }

  Future<void> seleccionarFechaCorreccion(_FilaAnomalia fila) async {
    const opciones = [
      'URGENTE',
      'PROG 7 D',
      'PROG 30 D',
      'HECHO',
    ];

    final opcion = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Estatus de corrección'),
        content: const Text('Seleccione el estatus de la anomalía:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          ...opciones.map(
            (texto) => TextButton(
              onPressed: () => Navigator.pop(dialogContext, texto),
              child: Text(
                texto,
                style: const TextStyle(
                  color: verdeCfe,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (opcion != null && mounted) {
      setState(() {
        fila.fechaCorreccionController.text = opcion;
      });
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : verdeCfe,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> guardarInspeccion() async {
    if (voltajeSeleccionado == null) {
      _mostrarMensaje('Seleccione el voltaje.', esError: true);
      return;
    }

    if (lineaSeleccionada == null) {
      _mostrarMensaje(
        'Seleccione la línea de transmisión.',
        esError: true,
      );
      return;
    }

    if (torresSeleccionadas.isEmpty) {
      _mostrarMensaje(
        'Seleccione al menos una torre.',
        esError: true,
      );
      return;
    }

    if (fechaSeleccionada == null) {
      _mostrarMensaje(
        'Seleccione la fecha de inspección.',
        esError: true,
      );
      return;
    }

    if (tipoTorreSeleccionado == null) {
      _mostrarMensaje('Seleccione el tipo de torre.', esError: true);
      return;
    }

    if (tipoCimentacionSeleccionado == null) {
      _mostrarMensaje('Seleccione el tipo de cimentación.', esError: true);
      return;
    }

    if (tipoInspeccionController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Seleccione el tipo de inspección.',
        esError: true,
      );
      return;
    }

    if (zonaSeleccionada == null) {
      _mostrarMensaje(
        'Seleccione la zona de transmisión.',
        esError: true,
      );
      return;
    }

    if (elaboroNombreController.text.trim().isEmpty ||
        elaboroRpeController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Complete el nombre y RPE de quien elaboró.',
        esError: true,
      );
      return;
    }

    // No guardar filas vacías creadas por accidente.
    final filasValidas = filasAnomalias
        .where((fila) => fila.anomaliaController.text.trim().isNotEmpty)
        .toList();

    if (filasValidas.isEmpty) {
      _mostrarMensaje(
        'Escriba al menos una anomalía antes de guardar.',
        esError: true,
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final inspeccion = <String, dynamic>{
        'fecha_inspeccion': _formatearFecha(fechaSeleccionada!),
        'linea_transmision':
            '$voltajeSeleccionado - ${lineaSeleccionada!.nombreCompleto}',
        'zona_transmision': zonaSeleccionada!,
        'tipo_inspeccion': tipoInspeccionController.text.trim(),
        'tipo_torre': tipoTorreSeleccionado!,
        'tipo_cimentacion': tipoCimentacionSeleccionado!,
        'elaboro':
            '${elaboroNombreController.text.trim()} '
            '(RPE: ${elaboroRpeController.text.trim()})',
        'visto_bueno':
            voBoNombreController.text.trim().isEmpty &&
                    voBoRpeController.text.trim().isEmpty
                ? null
                : '${voBoNombreController.text.trim()} '
                    '(RPE: ${voBoRpeController.text.trim()})',
        'sincronizado': 0,
      };

      // Cada fila se guarda como una anomalía independiente.
      final List<Map<String, dynamic>> anomalias = [];

      for (final fila in filasValidas) {
        anomalias.add({
          'fecha_revision': fila.fechaRevisionController.text.trim(),
          'numero_estacion': fila.torre,
          'anomalia': fila.anomaliaController.text.trim(),
          'fecha_correccion':
              fila.fechaCorreccionController.text.trim(),
        });
      }

      final id = await DatabaseHelper.instance.guardarInspeccionCompleta(
        inspeccion: inspeccion,
        anomalias: anomalias,
      );

      if (!mounted) return;

      setState(() => guardando = false);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: verdeCfe),
              SizedBox(width: 8),
              Expanded(child: Text('Inspección guardada')),
            ],
          ),
          content: Text(
            'La inspección se guardó en el dispositivo.\n\n'
            'Número de registro: $id\n'
            'Línea: ${lineaSeleccionada!.nombreCompleto}\n'
            'Torres seleccionadas: ${torresSeleccionadas.length}\n'
            'Anomalías guardadas: ${anomalias.length}',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: verdeCfe,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
      );

      if (mounted) limpiarFormulario();
    } catch (e) {
      if (!mounted) return;

      setState(() => guardando = false);
      _mostrarMensaje(
        'Error al guardar la inspección:\n$e',
        esError: true,
      );
    }
  }

  void limpiarFormulario() {
    for (final fila in filasAnomalias) {
      fila.dispose();
    }

    setState(() {
      voltajeSeleccionado = null;
      lineaSeleccionada = null;
      zonaSeleccionada = null;
      tipoTorreSeleccionado = null;
      tipoCimentacionSeleccionado = null;
      fechaSeleccionada = DateTime.now();

      busquedaTorre = '';
      buscadorTorreController.clear();

      torresSeleccionadas.clear();
      filasAnomalias.clear();

      tipoInspeccionController.clear();
      elaboroNombreController.clear();
      elaboroRpeController.clear();
      voBoNombreController.clear();
      voBoRpeController.clear();
    });
  }

  void cerrarSesion() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: verdeCfe,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              SesionUsuario.usuarioActual = null;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    buscadorTorreController.dispose();
    tipoInspeccionController.dispose();
    elaboroNombreController.dispose();
    elaboroRpeController.dispose();
    voBoNombreController.dispose();
    voBoRpeController.dispose();

    for (final fila in filasAnomalias) {
      fila.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: verdeCfe,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Inspecciones CFE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          if (esAdministrador)
            IconButton(
              tooltip: 'Administrar usuarios',
              icon: const Icon(Icons.manage_accounts, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUsuariosScreen(),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Inspecciones guardadas',
            icon: const Icon(Icons.folder_open, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InspeccionesGuardadasScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, size: 24),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: const Column(
                children: [
                  Text(
                    'COMISIÓN FEDERAL DE ELECTRICIDAD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'DIRECCIÓN DE OPERACIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'GERENCIA REGIONAL DE TRANSMISIÓN PENINSULAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(color: Colors.black),
                  Text(
                    'INSPECCIÓN DE LÍNEAS DE TRANSMISIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoja: 1 de 1'),
                  SizedBox(height: 4),
                  Text('CLAVE: P-T150-LT01-R-05'),
                  SizedBox(height: 4),
                  Text('REVISIÓN: 1'),
                  SizedBox(height: 4),
                  Text('FECHA DE ELABORACIÓN: 29.01.2021'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: const Text(
                'TRABAJOS PENDIENTES EN LA LÍNEA DE TRANSMISIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Selección de línea y torres.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LÍNEA DE TRANSMISIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: voltajeSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccione el voltaje',
                      prefixIcon: Icon(Icons.bolt, color: verdeCfe),
                      border: OutlineInputBorder(),
                    ),
                    items: voltajes
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() {
                        voltajeSeleccionado = valor;
                        lineaSeleccionada = null;
                        torresSeleccionadas.clear();
                        busquedaTorre = '';
                        buscadorTorreController.clear();
                        actualizarFilasTorres();
                      });
                    },
                  ),
                  if (voltajeSeleccionado != null) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<_LineaTransmision>(
                      initialValue: lineaSeleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Seleccione la línea',
                        prefixIcon: Icon(
                          Icons.electrical_services,
                          color: verdeCfe,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: obtenerLineas()
                          .map(
                            (linea) => DropdownMenuItem(
                              value: linea,
                              child: Text(
                                linea.nombreCompleto,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setState(() {
                          lineaSeleccionada = valor;
                          torresSeleccionadas.clear();
                          busquedaTorre = '';
                          buscadorTorreController.clear();
                          actualizarFilasTorres();
                        });
                      },
                    ),
                  ],
                  if (lineaSeleccionada != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(color: verdeCfe),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Línea: ${lineaSeleccionada!.nombreCompleto}\n'
                        'Torres: T-${lineaSeleccionada!.torreInicial.toString().padLeft(3, '0')} '
                        'a T-${lineaSeleccionada!.torreFinal.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          color: verdeCfe,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TORRES A INSPECCIONAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: buscadorTorreController,
                      decoration: InputDecoration(
                        hintText: 'Buscar número de torre...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: verdeCfe,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              buscadorTorreController.clear();
                              busquedaTorre = '';
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setState(() => busquedaTorre = valor);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${torresSeleccionadas.length} TORRES SELECCIONADAS',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: verdeCfe,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: limpiarTorresSeleccionadas,
                          child: const Text('LIMPIAR'),
                        ),
                      ],
                    ),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListView.builder(
                        itemCount: obtenerTorresFiltradas().length,
                        itemBuilder: (context, index) {
                          final torre = obtenerTorresFiltradas()[index];
                          final seleccionada =
                              torresSeleccionadas.contains(torre);

                          return CheckboxListTile(
                            title: Text(torre),
                            value: seleccionada,
                            activeColor: verdeCfe,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            onChanged: (_) => cambiarSeleccionTorre(torre),
                          );
                        },
                      ),
                    ),
                    if (torresSeleccionadas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: torresSeleccionadas
                            .map(
                              (torre) => Chip(
                                label: Text(torre),
                                backgroundColor: const Color(0xFFE8F5E9),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                                onDeleted: () =>
                                    cambiarSeleccionTorre(torre),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'FECHA:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatearFecha(
                            fechaSeleccionada ?? DateTime.now(),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Seleccionar fecha',
                        onPressed: seleccionarFecha,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: verdeCfe,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tipoTorreSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de torre',
                      prefixIcon: Icon(
                        Icons.cell_tower,
                        color: verdeCfe,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: tiposTorre
                        .map(
                          (tipo) => DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => tipoTorreSeleccionado = valor);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tipoCimentacionSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de cimentación',
                      prefixIcon: Icon(
                        Icons.foundation,
                        color: verdeCfe,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: tiposCimentacion
                        .map(
                          (tipo) => DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => tipoCimentacionSeleccionado = valor);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tiposInspeccion.contains(
                      tipoInspeccionController.text,
                    )
                        ? tipoInspeccionController.text
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de inspección',
                      prefixIcon: Icon(
                        Icons.assignment_outlined,
                        color: verdeCfe,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: tiposInspeccion
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() {
                        tipoInspeccionController.text = valor ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: zonaSeleccionada,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Zona de transmisión',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: verdeCfe,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: zonasTransmision
                        .map(
                          (zona) => DropdownMenuItem(
                            value: zona,
                            child: Text(zona),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => zonaSeleccionada = valor);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tabla de anomalías: cada fila tiene su propio estatus.
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'ANOMALÍAS POR TORRE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black),
                  if (filasAnomalias.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        'Seleccione una o más torres para mostrar las filas.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...filasAnomalias.map(
                      (fila) => _tarjetaAnomalia(fila),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Elaboró y Vo. Bo.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ELABORÓ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: elaboroNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: elaboroRpeController,
                    decoration: const InputDecoration(
                      labelText: 'RPE',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vo. Bo.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: voBoNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: voBoRpeController,
                    decoration: const InputDecoration(
                      labelText: 'RPE',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarInspeccion,
                icon: guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  guardando ? 'GUARDANDO...' : 'GUARDAR INSPECCIÓN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdeCfe,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Sistema de Inspecciones CFE',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAnomalia(_FilaAnomalia fila) {
    final cantidadDeEstaTorre =
        filasAnomalias.where((item) => item.torre == fila.torre).length;

    final numeroDeFila = filasAnomalias
            .where((item) => item.torre == fila.torre)
            .toList()
            .indexOf(fila) +
        1;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.electrical_services,
                color: verdeCfe,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${fila.torre} · Anomalía $numeroDeFila',
                  style: const TextStyle(
                    color: verdeCfe,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Agregar anomalía a ${fila.torre}',
                onPressed: () => agregarAnomalia(fila.torre),
                icon: const Icon(
                  Icons.add_circle,
                  color: verdeCfe,
                  size: 28,
                ),
              ),
              if (cantidadDeEstaTorre > 1)
                IconButton(
                  tooltip: 'Eliminar esta anomalía',
                  onPressed: () => eliminarAnomalia(fila),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => seleccionarFechaRevision(fila),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de revisión',
                prefixIcon: Icon(
                  Icons.calendar_month,
                  color: verdeCfe,
                ),
                border: OutlineInputBorder(),
              ),
              child: Text(fila.fechaRevisionController.text),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: fila.anomaliaController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Anomalía encontrada',
              hintText: 'Ej. Nido de aves, corrosión...',
              prefixIcon: Icon(
                Icons.warning_amber_outlined,
                color: verdeCfe,
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => seleccionarFechaCorreccion(fila),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Estatus de corrección',
                prefixIcon: Icon(
                  Icons.fact_check_outlined,
                  color: verdeCfe,
                ),
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fila.fechaCorreccionController.text.isEmpty
                          ? 'Seleccione estatus'
                          : fila.fechaCorreccionController.text,
                      style: TextStyle(
                        color:
                            fila.fechaCorreccionController.text.isEmpty
                                ? Colors.grey
                                : verdeCfe,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
