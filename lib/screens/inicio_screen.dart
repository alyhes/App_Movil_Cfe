import 'package:flutter/material.dart';
import '../database/database_helper.dart';

// ============================================================
// PANTALLA PRINCIPAL - FORMATO DE INSPECCIÓN CFE
// ============================================================

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

// ============================================================
// MODELO PARA CADA LÍNEA DE TRANSMISIÓN
// ============================================================

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

// ============================================================
// MODELO INTERNO PARA CADA FILA / TORRE
// ============================================================

class _FilaTorre {
  final String torre;

  final TextEditingController fechaRevisionController;
  final TextEditingController anomaliaController;
  final TextEditingController fechaCorreccionController;

  _FilaTorre({
    required this.torre,
  })  : fechaRevisionController = TextEditingController(),
        anomaliaController = TextEditingController(),
        fechaCorreccionController = TextEditingController();

  void dispose() {
    fechaRevisionController.dispose();
    anomaliaController.dispose();
    fechaCorreccionController.dispose();
  }
}

// ============================================================
// ESTADO
// ============================================================

class _InicioScreenState extends State<InicioScreen> {
  // ============================================================
  // DATOS DE LÍNEAS
  // ============================================================

  String? voltajeSeleccionado;
  _LineaTransmision? lineaSeleccionada;

  // ============================================================
  // FECHA DE INSPECCIÓN
  // ============================================================

  DateTime? fechaSeleccionada;

  // ============================================================
  // TIPO DE INSPECCIÓN
  // ============================================================

  final TextEditingController tipoInspeccionController =
      TextEditingController();

  // ============================================================
  // ZONA
  // ============================================================

  String? zonaSeleccionada;

  final List<String> zonasTransmision = [
    'Escárcega',
    'Santa Lucía',
  ];

  // ============================================================
  // BUSCADOR DE TORRES
  // ============================================================

  final TextEditingController buscadorTorreController =
      TextEditingController();

  String busquedaTorre = '';

  final List<String> torresSeleccionadas = [];

  // ============================================================
  // FILAS DINÁMICAS DE TORRES
  // ============================================================

  final List<_FilaTorre> filasTorres = [];

  // ============================================================
  // ELABORÓ
  // ============================================================

  final TextEditingController elaboroNombreController =
      TextEditingController();

  final TextEditingController elaboroRpeController =
      TextEditingController();

  // ============================================================
  // VO. BO.
  // ============================================================

  final TextEditingController voBoNombreController =
      TextEditingController();

  final TextEditingController voBoRpeController =
      TextEditingController();

  // ============================================================
  // ESTADO DE GUARDADO
  // ============================================================

  bool guardando = false;

  // ============================================================
  // VOLTAJES
  // ============================================================

  final List<String> voltajes = [
    '115 kV',
    '230 kV',
    '400 kV',
  ];

  // ============================================================
  // INFORMACIÓN REAL DE LAS LÍNEAS
  // ============================================================

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

  // ============================================================
  // OBTENER LÍNEAS SEGÚN VOLTAJE
  // ============================================================

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

  // ============================================================
  // OBTENER TORRES DE LA LÍNEA SELECCIONADA
  // ============================================================

  List<String> obtenerTorres() {
    if (lineaSeleccionada == null) {
      return [];
    }

    final int inicio = lineaSeleccionada!.torreInicial;
    final int fin = lineaSeleccionada!.torreFinal;

    final int cantidad = fin - inicio + 1;

    return List.generate(
      cantidad,
      (index) {
        final numero = inicio + index;

        return 'T-${numero.toString().padLeft(3, '0')}';
      },
    );
  }

  // ============================================================
  // FILTRAR TORRES
  // ============================================================

  List<String> obtenerTorresFiltradas() {
    final torres = obtenerTorres();

    final texto = busquedaTorre.trim().toLowerCase();

    if (texto.isEmpty) {
      return torres;
    }

    return torres.where((torre) {
      return torre.toLowerCase().contains(texto);
    }).toList();
  }

  // ============================================================
  // ACTUALIZAR FILAS DE LA TABLA
  // ============================================================

  void actualizarFilasTorres() {
    for (final fila in filasTorres) {
      fila.dispose();
    }

    filasTorres.clear();

    for (final torre in torresSeleccionadas) {
      filasTorres.add(
        _FilaTorre(
          torre: torre,
        ),
      );
    }
  }

  // ============================================================
  // SELECCIONAR / DESELECCIONAR TORRE
  // ============================================================

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

  // ============================================================
  // LIMPIAR TORRES SELECCIONADAS
  // ============================================================

  void limpiarTorresSeleccionadas() {
    setState(() {
      torresSeleccionadas.clear();
      actualizarFilasTorres();
    });
  }

  // ============================================================
  // LIMPIAR TODO EL FORMULARIO
  // ============================================================
  //
  // IMPORTANTE:
  // Esta función solamente limpia los campos de la pantalla.
  // Los datos que ya se guardaron en SQLite NO se eliminan.
  //
  // ============================================================

  void limpiarFormulario() {
    setState(() {
      // --------------------------------------------------------
      // DATOS GENERALES
      // --------------------------------------------------------

      voltajeSeleccionado = null;
      lineaSeleccionada = null;
      fechaSeleccionada = null;
      zonaSeleccionada = null;

      // --------------------------------------------------------
      // TIPO DE INSPECCIÓN
      // --------------------------------------------------------

      tipoInspeccionController.clear();

      // --------------------------------------------------------
      // BUSCADOR DE TORRES
      // --------------------------------------------------------

      buscadorTorreController.clear();
      busquedaTorre = '';

      // --------------------------------------------------------
      // TORRES
      // --------------------------------------------------------

      torresSeleccionadas.clear();

      // --------------------------------------------------------
      // ELABORÓ
      // --------------------------------------------------------

      elaboroNombreController.clear();
      elaboroRpeController.clear();

      // --------------------------------------------------------
      // VO. BO.
      // --------------------------------------------------------

      voBoNombreController.clear();
      voBoRpeController.clear();

      // --------------------------------------------------------
      // ELIMINAR FILAS DE LA TABLA
      // --------------------------------------------------------

      actualizarFilasTorres();
    });
  }

  // ============================================================
  // SELECCIONAR FECHA GENERAL
  // ============================================================

  Future<void> seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        fechaSeleccionada = fecha;
      });
    }
  }

  // ============================================================
  // SELECCIONAR FECHA DE UNA FILA
  // ============================================================

  Future<void> seleccionarFechaFila(
    TextEditingController controller, {
    bool permitirPendiente = true,
  }) async {
    final String? opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  'Seleccionar fecha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ==================================================
              // OPCIÓN CALENDARIO
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF007A4D),
                ),
                title: const Text(
                  'Seleccionar una fecha',
                ),
                subtitle: const Text(
                  'Elegir la fecha desde el calendario',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    'calendario',
                  );
                },
              ),

              // ==================================================
              // OPCIÓN PENDIENTE
              // ==================================================

              if (permitirPendiente)
                ListTile(
                  leading: const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'PENDIENTE',
                  ),
                  subtitle: const Text(
                    'Todavía no se ha realizado o terminado',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'pendiente',
                    );
                  },
                ),

              // ==================================================
              // CANCELAR
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
                title: const Text(
                  'Cancelar',
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );

    if (!mounted || opcion == null) {
      return;
    }

    // ==========================================================
    // SELECCIONAR CALENDARIO
    // ==========================================================

    if (opcion == 'calendario') {
      DateTime fechaInicial = DateTime.now();

      final textoActual = controller.text.trim();

      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(textoActual)) {
        try {
          final partes = textoActual.split('/');

          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);
          final anio = int.parse(partes[2]);

          fechaInicial = DateTime(
            anio,
            mes,
            dia,
          );
        } catch (_) {
          fechaInicial = DateTime.now();
        }
      }

      final DateTime? fecha = await showDatePicker(
        context: context,
        initialDate: fechaInicial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('es', 'MX'),
        helpText: 'SELECCIONE LA FECHA',
        cancelText: 'CANCELAR',
        confirmText: 'ACEPTAR',
      );

      if (fecha != null) {
        setState(() {
          controller.text = formatearFecha(fecha);
        });
      }
    }

    // ==========================================================
    // MARCAR COMO PENDIENTE
    // ==========================================================

    if (opcion == 'pendiente') {
      setState(() {
        controller.text = 'PENDIENTE';
      });
    }
  }

  // ============================================================
  // FORMATO DE FECHA
  // ============================================================

  String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // ============================================================
  // GUARDAR INSPECCIÓN COMPLETA
  // ============================================================

  Future<void> guardarInspeccion() async {
    // ==========================================================
    // VALIDACIONES
    // ==========================================================

    if (voltajeSeleccionado == null) {
      _mostrarMensaje(
        'Seleccione el voltaje.',
        esError: true,
      );
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

    if (tipoInspeccionController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Escriba el tipo de inspección.',
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

    if (elaboroNombreController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Escriba el nombre de quien elaboró.',
        esError: true,
      );
      return;
    }

    if (elaboroRpeController.text.trim().isEmpty) {
      _mostrarMensaje(
        'Escriba el RPE de quien elaboró.',
        esError: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      // ========================================================
      // INFORMACIÓN GENERAL
      // ========================================================

      final inspeccion = <String, dynamic>{
        'fecha_inspeccion':
            formatearFecha(fechaSeleccionada!),

        'linea_transmision':
            '$voltajeSeleccionado - ${lineaSeleccionada!.nombreCompleto}',

        'zona_transmision':
            zonaSeleccionada!,

        'tipo_inspeccion':
            tipoInspeccionController.text.trim(),

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

      // ========================================================
      // DATOS DE CADA TORRE
      // ========================================================

      final List<Map<String, dynamic>> anomalias = [];

      for (final fila in filasTorres) {
        anomalias.add({
          'fecha_revision':
              fila.fechaRevisionController.text.trim(),

          'numero_estacion':
              fila.torre,

          'anomalia':
              fila.anomaliaController.text.trim(),

          'fecha_correccion':
              fila.fechaCorreccionController.text.trim(),
        });
      }

      // ========================================================
      // GUARDAR TODO EN UNA SOLA TRANSACCIÓN
      // ========================================================

      final int id =
          await DatabaseHelper.instance.guardarInspeccionCompleta(
        inspeccion: inspeccion,
        anomalias: anomalias,
      );

      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      // ========================================================
      // MENSAJE DE ÉXITO
      // ========================================================

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF007A4D),
                ),
                SizedBox(width: 8),
                Text(
                  'Inspección guardada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'La inspección se guardó correctamente '
              'en el dispositivo.\n\n'
              'Número de registro: $id\n'
              'Línea: ${lineaSeleccionada!.nombreCompleto}\n'
              'Torres guardadas: ${torresSeleccionadas.length}',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF007A4D),
                  foregroundColor: Colors.white,
                ),

                // ==================================================
                // AQUÍ SE LIMPIA EL FORMULARIO
                // ==================================================

                onPressed: () {
                  Navigator.of(context).pop();

                  // Después de cerrar el mensaje,
                  // dejamos la pantalla lista para
                  // registrar una nueva inspección.
                  limpiarFormulario();
                },

                child: const Text('ACEPTAR'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mostrarMensaje(
        'Ocurrió un error al guardar:\n$e',
        esError: true,
      );
    }
  }

  // ============================================================
  // MOSTRAR MENSAJE
  // ============================================================

  void _mostrarMensaje(
    String mensaje, {
    bool esError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? Colors.red : const Color(0xFF007A4D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  void cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF007A4D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('CERRAR SESIÓN'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    buscadorTorreController.dispose();
    tipoInspeccionController.dispose();

    for (final fila in filasTorres) {
      fila.dispose();
    }

    elaboroNombreController.dispose();
    elaboroRpeController.dispose();
    voBoNombreController.dispose();
    voBoRpeController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // BARRA SUPERIOR
      // ========================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF007A4D),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Inspecciones CFE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout,
              size: 23,
            ),
            onPressed: cerrarSesion,
          ),
        ],
      ),

      // ========================================================
      // CONTENIDO
      // ========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // ENCABEZADO CFE
            // ==================================================

            Container(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                children: const [
                  Text(
                    'COMISIÓN FEDERAL DE ELECTRICIDAD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'DIRECCIÓN DE OPERACIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'GERENCIA REGIONAL DE TRANSMISIÓN PENINSULAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Colors.black,
                    height: 1,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'INSPECCIÓN DE LÍNEAS DE TRANSMISIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DATOS DEL DOCUMENTO
            // ==================================================

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hoja: 1 de 1',
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CLAVE: P-T150-LT01-R-05',
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'REVISIÓN: 1',
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'FECHA DE ELABORACIÓN: 29.01.2021',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TÍTULO
            // ==================================================

            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: const Text(
                'TRABAJOS PENDIENTES EN LA LÍNEA DE TRANSMISIÓN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // INFORMACIÓN DE INSPECCIÓN
            // ==================================================

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LÍNEA DE TRANSMISIÓN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // VOLTAJE
                  // ==================================================

                  DropdownButtonFormField<String>(
                    initialValue: voltajeSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Seleccione el voltaje',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      prefixIcon: const Icon(
                        Icons.bolt,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    items: voltajes.map((voltaje) {
                      return DropdownMenuItem<String>(
                        value: voltaje,
                        child: Text(voltaje),
                      );
                    }).toList(),
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

                  // ==================================================
                  // LÍNEA
                  // ==================================================

                  if (voltajeSeleccionado != null) ...[
                    const SizedBox(height: 10),

                    Text(
                      'LÍNEA $voltajeSeleccionado:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    DropdownButtonFormField<_LineaTransmision>(
                      initialValue: lineaSeleccionada,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Seleccione la línea',
                        labelStyle:
                            const TextStyle(fontSize: 11),
                        prefixIcon: const Icon(
                          Icons.electrical_services,
                          color: Color(0xFF007A4D),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(
                            color: Color(0xFF007A4D),
                            width: 2,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      items: obtenerLineas().map((linea) {
                        return DropdownMenuItem<
                            _LineaTransmision>(
                          value: linea,
                          child: Text(
                            linea.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
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

                  // ==================================================
                  // INFORMACIÓN DEL RANGO DE TORRES
                  // ==================================================

                  if (lineaSeleccionada != null) ...[
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(
                          color: const Color(0xFF007A4D),
                        ),
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_tree,
                            color: Color(0xFF007A4D),
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Línea: ${lineaSeleccionada!.nombreCompleto}\n'
                              'Torres disponibles: '
                              'T-${lineaSeleccionada!.torreInicial.toString().padLeft(3, '0')} '
                              'a '
                              'T-${lineaSeleccionada!.torreFinal.toString().padLeft(3, '0')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007A4D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ==================================================
                  // TORRES
                  // ==================================================

                  if (lineaSeleccionada != null) ...[
                    const SizedBox(height: 14),

                    const Text(
                      'TORRES A INSPECCIONAR:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ==================================================
                    // BUSCADOR
                    // ==================================================

                    TextField(
                      controller:
                          buscadorTorreController,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar número de torre...',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF007A4D),
                          size: 20,
                        ),
                        suffixIcon:
                            buscadorTorreController.text
                                    .isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        buscadorTorreController
                                            .clear();
                                        busquedaTorre = '';
                                      });
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(
                            color: Color(0xFF007A4D),
                            width: 2,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (valor) {
                        setState(() {
                          busquedaTorre = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // CONTADOR
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: torresSeleccionadas
                                .isNotEmpty
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF2F2F2),
                        borderRadius:
                            BorderRadius.circular(5),
                        border: Border.all(
                          color: torresSeleccionadas
                                  .isNotEmpty
                              ? const Color(0xFF007A4D)
                              : Colors.grey,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            torresSeleccionadas
                                    .isNotEmpty
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 19,
                            color:
                                torresSeleccionadas
                                        .isNotEmpty
                                    ? const Color(0xFF007A4D)
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${torresSeleccionadas.length} TORRES SELECCIONADAS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    torresSeleccionadas
                                            .isNotEmpty
                                        ? const Color(
                                            0xFF007A4D)
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                          if (torresSeleccionadas
                              .isNotEmpty)
                            TextButton(
                              onPressed:
                                  limpiarTorresSeleccionadas,
                              child: const Text(
                                'LIMPIAR',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // LISTA DE TORRES
                    // ==================================================

                    if (obtenerTorres().isNotEmpty)
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        child: ListView.builder(
                          itemCount:
                              obtenerTorresFiltradas()
                                  .length,
                          itemBuilder:
                              (context, index) {
                            final torres =
                                obtenerTorresFiltradas();

                            final torre = torres[index];

                            final seleccionada =
                                torresSeleccionadas
                                    .contains(torre);

                            return CheckboxListTile(
                              dense: true,
                              visualDensity:
                                  const VisualDensity(
                                vertical: -2,
                              ),
                              title: Text(
                                torre,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                              value: seleccionada,
                              activeColor:
                                  const Color(0xFF007A4D),
                              controlAffinity:
                                  ListTileControlAffinity
                                      .leading,
                              onChanged: (valor) {
                                cambiarSeleccionTorre(
                                  torre,
                                );
                              },
                            );
                          },
                        ),
                      ),

                    // ==================================================
                    // SIN RESULTADOS
                    // ==================================================

                    if (obtenerTorresFiltradas().isEmpty)
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'No se encontraron torres.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    // ==================================================
                    // TORRES SELECCIONADAS
                    // ==================================================

                    if (torresSeleccionadas
                        .isNotEmpty) ...[
                      const SizedBox(height: 10),

                      const Text(
                        'TORRES SELECCIONADAS:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children:
                            torresSeleccionadas
                                .map((torre) {
                          return Chip(
                            backgroundColor:
                                const Color(
                              0xFFE8F5E9,
                            ),
                            label: Text(
                              torre,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color: Color(
                                  0xFF007A4D,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            deleteIcon:
                                const Icon(
                              Icons.close,
                              size: 15,
                              color:
                                  Color(0xFF007A4D),
                            ),
                            onDeleted: () {
                              cambiarSeleccionTorre(
                                torre,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),

                  // ==================================================
                  // FECHA GENERAL
                  // ==================================================

                  _campoFecha(),

                  const SizedBox(height: 14),

                  // ==================================================
                  // TIPO DE INSPECCIÓN
                  // ==================================================

                  const Text(
                    'TIPO DE INSPECCIÓN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller:
                        tipoInspeccionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Escriba el tipo de inspección...',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.all(10),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // ZONA
                  // ==================================================

                  const Text(
                    'ZONA DE TRANSMISIÓN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    initialValue: zonaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Seleccione la zona',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    items:
                        zonasTransmision.map((zona) {
                      return DropdownMenuItem<String>(
                        value: zona,
                        child: Text(zona),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        zonaSeleccionada = valor;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ========================================================
            // TABLA DE ANOMALÍAS
            // ========================================================

            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // ENCABEZADO
                  // ==================================================

                  Table(
                    border: TableBorder.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(0.8),
                      2: FlexColumnWidth(1.8),
                      3: FlexColumnWidth(1.3),
                    },
                    children: const [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Color(0xFFE8E8E8),
                        ),
                        children: [
                          _EncabezadoTabla(
                            'FECHA DE\nREVISIÓN',
                          ),
                          _EncabezadoTabla(
                            'NO.\nEST.',
                          ),
                          _EncabezadoTabla(
                            'ANOMALÍA\nENCONTRADA',
                          ),
                          _EncabezadoTabla(
                            'FECHA DE\nCORRECCIÓN',
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ==================================================
                  // FILAS SEGÚN TORRES SELECCIONADAS
                  // ==================================================

                  if (filasTorres.isEmpty)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),
                      child: const Text(
                        'Seleccione una o más torres para '
                        'mostrar las filas de inspección.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...filasTorres.map(
                      (fila) => Table(
                        border: TableBorder.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.3),
                          1: FlexColumnWidth(0.8),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(1.3),
                        },
                        children: [
                          _filaTablaEditable(fila),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // ELABORÓ
            // ========================================================

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ELABORÓ:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        elaboroNombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText:
                          'Escriba el nombre completo',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      hintStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        elaboroRpeController,
                    decoration: InputDecoration(
                      labelText: 'RPE',
                      hintText: 'Escriba el RPE',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      hintStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Vo. Bo.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        voBoNombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText:
                          'Escriba el nombre completo',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      hintStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller:
                        voBoRpeController,
                    decoration: InputDecoration(
                      labelText: 'RPE',
                      hintText: 'Escriba el RPE',
                      labelStyle:
                          const TextStyle(fontSize: 11),
                      hintStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF007A4D),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
                        borderSide: const BorderSide(
                          color: Color(0xFF007A4D),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ========================================================
            // BOTÓN GUARDAR
            // ========================================================

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    guardando ? null : guardarInspeccion,
                icon: guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                        size: 22,
                      ),
                label: Text(
                  guardando
                      ? 'GUARDANDO...'
                      : 'GUARDAR INSPECCIÓN',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF007A4D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ========================================================
            // PIE
            // ========================================================

            const Center(
              child: Text(
                'Sistema de Inspecciones CFE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO FECHA GENERAL
  // ============================================================

  Widget _campoFecha() {
    return InkWell(
      onTap: seleccionarFecha,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            const Text(
              'FECHA:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 5),

            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 2,
                ),
                decoration:
                    const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  fechaSeleccionada == null
                      ? 'Seleccione una fecha'
                      : formatearFecha(
                          fechaSeleccionada!,
                        ),
                  style: TextStyle(
                    fontSize: 11,
                    color: fechaSeleccionada == null
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.calendar_month,
              size: 19,
              color: Color(0xFF007A4D),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILA DE LA TABLA
  // ============================================================

  TableRow _filaTablaEditable(
    _FilaTorre fila,
  ) {
    return TableRow(
      children: [
        // ======================================================
        // FECHA DE REVISIÓN
        // ======================================================

        _celdaFecha(
          controller: fila.fechaRevisionController,
        ),

        // ======================================================
        // NÚMERO DE ESTACIÓN / TORRE
        // ======================================================

        Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(3),
          child: Text(
            fila.torre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A4D),
            ),
          ),
        ),

        // ======================================================
        // ANOMALÍA
        // ======================================================

        _celdaEditable(
          fila.anomaliaController,
          'Escriba la anomalía',
          maxLines: 3,
          keyboardType:
              TextInputType.multiline,
        ),

        // ======================================================
        // FECHA DE CORRECCIÓN
        // ======================================================

        _celdaFecha(
          controller: fila.fechaCorreccionController,
        ),
      ],
    );
  }

  // ============================================================
  // CELDA DE FECHA CON CALENDARIO
  // ============================================================

  Widget _celdaFecha({
    required TextEditingController controller,
  }) {
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: () {
          seleccionarFechaFila(
            controller,
            permitirPendiente: true,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  controller.text.isEmpty
                      ? 'Seleccione'
                      : controller.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: controller.text.isEmpty
                        ? Colors.grey
                        : controller.text ==
                                'PENDIENTE'
                            ? Colors.orange[800]
                            : Colors.black,
                    fontWeight:
                        controller.text == 'PENDIENTE'
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),

              const SizedBox(width: 2),

              Icon(
                controller.text == 'PENDIENTE'
                    ? Icons.pending_actions
                    : Icons.calendar_month,
                size: 15,
                color: controller.text == 'PENDIENTE'
                    ? Colors.orange[700]
                    : const Color(0xFF007A4D),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CELDA EDITABLE
  // ============================================================

  Widget _celdaEditable(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return SizedBox(
      height: maxLines > 1 ? 65 : 48,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.all(3),
          ),
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ENCABEZADO DE TABLA
// ============================================================

class _EncabezadoTabla extends StatelessWidget {
  final String texto;

  const _EncabezadoTabla(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}