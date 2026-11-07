import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/excel_export_service.dart';
import '../services/sync_service.dart';

// ============================================================
// PANTALLA DE INSPECCIONES GUARDADAS
// ============================================================

class InspeccionesGuardadasScreen extends StatefulWidget {
  const InspeccionesGuardadasScreen({super.key});

  @override
  State<InspeccionesGuardadasScreen> createState() =>
      _InspeccionesGuardadasScreenState();
}

class _InspeccionesGuardadasScreenState
    extends State<InspeccionesGuardadasScreen> {
  final DatabaseHelper db = DatabaseHelper.instance;
  final SyncService syncService = SyncService();

  List<Map<String, dynamic>> inspecciones = [];
  List<Map<String, dynamic>> inspeccionesFiltradas = [];

  final TextEditingController buscadorController =
      TextEditingController();

  DateTime? fechaFiltro;

  bool ordenDescendente = true;
  bool sincronizando = false;
  bool exportandoLote = false;

  int? exportandoId;

  // ==========================================================
  // INICIAR
  // ==========================================================

  @override
  void initState() {
    super.initState();

    cargarInspecciones();

    buscadorController.addListener(() {
      aplicarFiltros();
    });
  }

  // ==========================================================
  // CARGAR INSPECCIONES
  // ==========================================================

  Future<void> cargarInspecciones() async {
    final datos = await db.obtenerInspecciones();

    if (!mounted) return;

    setState(() {
      inspecciones = datos;
    });

    aplicarFiltros();
  }

  // ==========================================================
  // SINCRONIZAR CON EL SERVIDOR
  // ==========================================================

  Future<void> sincronizarConServidor() async {
    if (sincronizando) return;

    setState(() {
      sincronizando = true;
    });

    try {
      final conexion = await syncService.comprobarConexion();

      if (!conexion) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo conectar con el servidor CFE.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );

        return;
      }

      final resultado =
          await syncService.sincronizarInspecciones();

      if (!mounted) return;

      final bool exito = resultado['exito'] == true;
      final int enviadas = resultado['enviadas'] ?? 0;
      final int errores = resultado['errores'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exito
                ? 'Sincronización completada.\n'
                    'Inspecciones enviadas: $enviadas'
                : 'Sincronización con errores.\n'
                    'Enviadas: $enviadas | Errores: $errores',
          ),
          backgroundColor: exito
              ? const Color(0xFF007A4D)
              : Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      await cargarInspecciones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrió un error al sincronizar.\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sincronizando = false;
        });
      }
    }
  }

  // ==========================================================
  // CONVERTIR FECHA
  // ==========================================================

  DateTime? convertirFecha(String? fecha) {
    if (fecha == null || fecha.trim().isEmpty) {
      return null;
    }

    final partes = fecha.split('/');

    if (partes.length != 3) {
      return null;
    }

    try {
      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final anio = int.parse(partes[2]);

      return DateTime(anio, mes, dia);
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // APLICAR FILTROS
  // ==========================================================

  void aplicarFiltros() {
    final texto = buscadorController.text.trim().toLowerCase();

    List<Map<String, dynamic>> resultado =
        List<Map<String, dynamic>>.from(inspecciones);

    if (texto.isNotEmpty) {
      resultado = resultado.where((inspeccion) {
        final fecha =
            (inspeccion['fecha_inspeccion'] ?? '')
                .toString()
                .toLowerCase();

        final linea =
            (inspeccion['linea_transmision'] ?? '')
                .toString()
                .toLowerCase();

        final zona =
            (inspeccion['zona_transmision'] ?? '')
                .toString()
                .toLowerCase();

        final tipo =
            (inspeccion['tipo_inspeccion'] ?? '')
                .toString()
                .toLowerCase();

        final tipoTorre =
            (inspeccion['tipo_torre'] ?? '')
                .toString()
                .toLowerCase();

        final tipoCimentacion =
            (inspeccion['tipo_cimentacion'] ?? '')
                .toString()
                .toLowerCase();

        final elaboro =
            (inspeccion['elaboro'] ?? '')
                .toString()
                .toLowerCase();

        final vistoBueno =
            (inspeccion['visto_bueno'] ?? '')
                .toString()
                .toLowerCase();

        return fecha.contains(texto) ||
            linea.contains(texto) ||
            zona.contains(texto) ||
            tipo.contains(texto) ||
            tipoTorre.contains(texto) ||
            tipoCimentacion.contains(texto) ||
            elaboro.contains(texto) ||
            vistoBueno.contains(texto);
      }).toList();
    }

    if (fechaFiltro != null) {
      resultado = resultado.where((inspeccion) {
        final fecha = convertirFecha(
          inspeccion['fecha_inspeccion']?.toString(),
        );

        if (fecha == null) return false;

        return fecha.year == fechaFiltro!.year &&
            fecha.month == fechaFiltro!.month &&
            fecha.day == fechaFiltro!.day;
      }).toList();
    }

    resultado.sort((a, b) {
      final fechaA = convertirFecha(
        a['fecha_inspeccion']?.toString(),
      );

      final fechaB = convertirFecha(
        b['fecha_inspeccion']?.toString(),
      );

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;

      final comparacion = fechaA.compareTo(fechaB);

      return ordenDescendente ? -comparacion : comparacion;
    });

    if (!mounted) return;

    setState(() {
      inspeccionesFiltradas = resultado;
    });
  }

  // ==========================================================
  // EXPORTAR UNA INSPECCIÓN
  // ==========================================================

  Future<void> exportarAExcel(
    Map<String, dynamic> inspeccion,
  ) async {
    final int id = inspeccion['id'];

    if (exportandoId != null || exportandoLote) return;

    setState(() {
      exportandoId = id;
    });

    try {
      await ExcelExportService.exportarInspeccion(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Archivo Excel generado correctamente.',
            ),
            backgroundColor: Color(0xFF007A4D),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo generar el archivo Excel.\n$e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          exportandoId = null;
        });
      }
    }
  }

  // ==========================================================
  // EXPORTAR INSPECCIONES POR DÍA
  // ==========================================================

  Future<void> exportarExcelPorDia() async {
    if (exportandoLote || exportandoId != null) return;

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
      helpText: 'SELECCIONAR DÍA PARA EXPORTAR',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (!mounted || fecha == null) return;

    setState(() {
      exportandoLote = true;
    });

    try {
      await ExcelExportService.exportarInspeccionesPorDia(fecha);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel del día ${formatearFecha(fecha)} generado correctamente.',
          ),
          backgroundColor: const Color(0xFF007A4D),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo generar el Excel del día.\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          exportandoLote = false;
        });
      }
    }
  }

  // ==========================================================
  // EXPORTAR INSPECCIONES POR MES
  // ==========================================================


Future<void> exportarExcelPorMes() async {
  final meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  final mesSeleccionado = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Seleccionar mes'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
            ),
            itemBuilder: (context, index) {
              return OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, index + 1);
                },
                child: Text(meses[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );

  if (mesSeleccionado == null) return;

  try {
    final anioActual = DateTime.now().year;

        await ExcelExportService.exportarInspeccionesPorMes(
      anioActual,
      mesSeleccionado,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Excel de ${meses[mesSeleccionado - 1]} '
          'de $anioActual generado correctamente.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al generar Excel: $e'),
      ),
    );
  }
}

  // ==========================================================
  // NOMBRE DEL MES
  // ==========================================================

  String nombreMes(int mes) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return meses[mes - 1];
  }

  // ==========================================================
  // SELECCIONAR DÍA PARA FILTRAR
  // ==========================================================

  Future<void> seleccionarDia() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
      helpText: 'BUSCAR INSPECCIONES DEL DÍA',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (!mounted) return;

    if (fecha != null) {
      setState(() {
        fechaFiltro = fecha;
      });

      aplicarFiltros();
    }
  }

  // ==========================================================
  // LIMPIAR FILTRO
  // ==========================================================

  void limpiarFiltroFecha() {
    setState(() {
      fechaFiltro = null;
    });

    aplicarFiltros();
  }

  // ==========================================================
  // CAMBIAR ORDEN
  // ==========================================================

  void cambiarOrden() {
    setState(() {
      ordenDescendente = !ordenDescendente;
    });

    aplicarFiltros();
  }

  // ==========================================================
  // FORMATO DE FECHA
  // ==========================================================

  String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // ==========================================================
  // ELIMINAR INSPECCIÓN
  // ==========================================================

  Future<void> eliminarInspeccion(
    Map<String, dynamic> inspeccion,
  ) async {
    final int id = inspeccion['id'];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar inspección',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            '¿Deseas eliminar la inspección número $id?\n\n'
            'También se eliminarán las anomalías relacionadas '
            'con esta inspección.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await db.eliminarInspeccion(id);

    if (!mounted) return;

    await cargarInspecciones();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inspección eliminada correctamente.',
        ),
        backgroundColor: Color(0xFF007A4D),
      ),
    );
  }

  // ==========================================================
  // VER DETALLE
  // ==========================================================

  Future<void> verDetalle(
    Map<String, dynamic> inspeccion,
  ) async {
    final int id = inspeccion['id'];

    final datos = await db.obtenerInspeccionCompleta(id);

    if (!mounted) return;

    if (datos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo obtener la información.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final Map<String, dynamic> datosInspeccion =
        datos['inspeccion'] as Map<String, dynamic>;

    final List<dynamic> anomalias =
        datos['anomalias'] as List<dynamic>;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.assignment,
                color: Color(0xFF007A4D),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detalle de inspección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _datoDetalle(
                    'Número de registro',
                    '${datosInspeccion['id']}',
                  ),
                  _datoDetalle(
                    'Fecha de inspección',
                    '${datosInspeccion['fecha_inspeccion'] ?? ''}',
                  ),
                  _datoDetalle(
                    'Línea de transmisión',
                    '${datosInspeccion['linea_transmision'] ?? ''}',
                  ),
                  _datoDetalle(
                    'Zona',
                    '${datosInspeccion['zona_transmision'] ?? ''}',
                  ),
                  _datoDetalle(
                    'Tipo de inspección',
                    '${datosInspeccion['tipo_inspeccion'] ?? ''}',
                  ),
                  _datoDetalle(
                    'Tipo de torre',
                    '${datosInspeccion['tipo_torre'] ?? 'No especificado'}',
                  ),
                  _datoDetalle(
                    'Tipo de cimentación',
                    '${datosInspeccion['tipo_cimentacion'] ?? 'No especificado'}',
                  ),
                  _datoDetalle(
                    'Elaboró',
                    '${datosInspeccion['elaboro'] ?? ''}',
                  ),
                  _datoDetalle(
                    'Vo. Bo.',
                    '${datosInspeccion['visto_bueno'] ?? 'No especificado'}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TORRES / ANOMALÍAS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A4D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (anomalias.isEmpty)
                    const Text(
                      'No hay anomalías registradas.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    )
                  else
                    ...anomalias.map((anomalia) {
                      final Map<String, dynamic> dato =
                          Map<String, dynamic>.from(anomalia);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Torre: ${dato['numero_estacion'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007A4D),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Fecha de revisión: '
                              '${dato['fecha_revision'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Anomalía: ${dato['anomalia'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Fecha de corrección: '
                              '${dato['fecha_correccion'] ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A4D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DATO DEL DETALLE
  // ==========================================================

  Widget _datoDetalle(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EDITAR INSPECCIÓN
  // ==========================================================

  Future<void> editarInspeccion(
    Map<String, dynamic> inspeccion,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarInspeccionScreen(
          inspeccionId: inspeccion['id'] as int,
        ),
      ),
    );

    if (!mounted) return;

    if (resultado == true) {
      await cargarInspecciones();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inspección actualizada correctamente.',
          ),
          backgroundColor: Color(0xFF007A4D),
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A4D),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Inspecciones guardadas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar con el servidor',
            onPressed: sincronizando
                ? null
                : sincronizarConServidor,
            icon: sincronizando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.sync,
                    size: 27,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargarInspecciones,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // BUSCADOR
              // ==================================================

              TextField(
                controller: buscadorController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Buscar inspección',
                  labelStyle: const TextStyle(fontSize: 14),
                  hintText:
                      'Fecha, línea, zona, tipo o nombre...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF007A4D),
                  ),
                  suffixIcon: buscadorController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            buscadorController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFF007A4D),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // FILTROS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: seleccionarDia,
                      icon: const Icon(
                        Icons.calendar_month,
                        size: 20,
                      ),
                      label: Text(
                        fechaFiltro == null
                            ? 'Buscar por día'
                            : formatearFecha(fechaFiltro!),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF007A4D),
                        side: const BorderSide(
                          color: Color(0xFF007A4D),
                        ),
                      ),
                    ),
                  ),
                  if (fechaFiltro != null)
                    IconButton(
                      tooltip: 'Quitar filtro de fecha',
                      onPressed: limpiarFiltroFecha,
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.red,
                      ),
                    ),
                  const SizedBox(width: 5),
                  IconButton(
                    tooltip: ordenDescendente
                        ? 'Más antiguas primero'
                        : 'Más recientes primero',
                    onPressed: cambiarOrden,
                    icon: Icon(
                      ordenDescendente
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: const Color(0xFF007A4D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ==================================================
              // EXPORTACIÓN POR DÍA Y POR MES
              // ==================================================

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  border: Border.all(
                    color: const Color(0xFF007A4D),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.file_download,
                          color: Color(0xFF007A4D),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'EXPORTAR REPORTES A EXCEL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007A4D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: exportandoLote
                                ? null
                                : exportarExcelPorDia,
                            icon: const Icon(
                              Icons.today,
                              size: 19,
                            ),
                            label: const Text(
                              'POR DÍA',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF007A4D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: exportandoLote
                                ? null
                                : exportarExcelPorMes,
                            icon: const Icon(
                              Icons.calendar_month,
                              size: 19,
                            ),
                            label: const Text(
                              'POR MES',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF007A4D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (exportandoLote) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(
                        color: Color(0xFF007A4D),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Generando archivo Excel...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // RESULTADOS
              // ==================================================

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(
                    color: const Color(0xFF007A4D),
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder,
                      color: Color(0xFF007A4D),
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${inspeccionesFiltradas.length} '
                        'inspección(es) encontrada(s)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A4D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // LISTA
              // ==================================================

              if (inspeccionesFiltradas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No se encontraron inspecciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...inspeccionesFiltradas.map(
                  (inspeccion) => _tarjetaInspeccion(inspeccion),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TARJETA DE INSPECCIÓN
  // ==========================================================

  Widget _tarjetaInspeccion(
    Map<String, dynamic> inspeccion,
  ) {
    final int id = inspeccion['id'];

    final String fecha =
        '${inspeccion['fecha_inspeccion'] ?? ''}';

    final String linea =
        '${inspeccion['linea_transmision'] ?? ''}';

    final String zona =
        '${inspeccion['zona_transmision'] ?? ''}';

    final String tipo =
        '${inspeccion['tipo_inspeccion'] ?? ''}';

    final String tipoTorre =
        '${inspeccion['tipo_torre'] ?? 'No especificado'}';

    final String tipoCimentacion =
        '${inspeccion['tipo_cimentacion'] ?? 'No especificado'}';

    final String elaboro =
        '${inspeccion['elaboro'] ?? ''}';

    final bool estaExportando = exportandoId == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Color(0xFF007A4D),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSPECCIÓN #$id',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A4D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        fecha,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // MENÚ

                PopupMenuButton<String>(
                  onSelected: (opcion) {
                    if (opcion == 'ver') {
                      verDetalle(inspeccion);
                    } else if (opcion == 'editar') {
                      editarInspeccion(inspeccion);
                    } else if (opcion == 'eliminar') {
                      eliminarInspeccion(inspeccion);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ver',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 21,
                            color: Color(0xFF007A4D),
                          ),
                          SizedBox(width: 8),
                          Text('Ver detalle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 21,
                            color: Color(0xFF007A4D),
                          ),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 21,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(),

            // INFORMACIÓN

            _filaInformacion(
              Icons.electrical_services,
              'Línea',
              linea,
            ),
            _filaInformacion(
              Icons.location_on_outlined,
              'Zona',
              zona,
            ),
            _filaInformacion(
              Icons.assignment_outlined,
              'Tipo',
              tipo,
            ),
            _filaInformacion(
              Icons.account_tree_outlined,
              'Tipo de torre',
              tipoTorre,
            ),
            _filaInformacion(
              Icons.foundation,
              'Cimentación',
              tipoCimentacion,
            ),
            _filaInformacion(
              Icons.person_outline,
              'Elaboró',
              elaboro,
            ),

            const SizedBox(height: 8),

            // VER INSPECCIÓN

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: estaExportando
                    ? null
                    : () {
                        verDetalle(inspeccion);
                      },
                icon: const Icon(
                  Icons.visibility,
                  size: 19,
                ),
                label: const Text(
                  'VER INSPECCIÓN COMPLETA',
                  style: TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007A4D),
                  side: const BorderSide(
                    color: Color(0xFF007A4D),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // EXPORTAR INDIVIDUAL

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: estaExportando || exportandoLote
                    ? null
                    : () {
                        exportarAExcel(inspeccion);
                      },
                icon: estaExportando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.table_view,
                        size: 19,
                      ),
                label: Text(
                  estaExportando
                      ? 'GENERANDO EXCEL...'
                      : 'EXPORTAR A EXCEL',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A4D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FILA DE INFORMACIÓN
  // ==========================================================

  Widget _filaInformacion(
    IconData icono,
    String titulo,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 18,
            color: const Color(0xFF007A4D),
          ),
          const SizedBox(width: 7),
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// PANTALLA PARA EDITAR UNA INSPECCIÓN
// =================================================================

class EditarInspeccionScreen extends StatefulWidget {
  final int inspeccionId;

  const EditarInspeccionScreen({
    super.key,
    required this.inspeccionId,
  });

  @override
  State<EditarInspeccionScreen> createState() =>
      _EditarInspeccionScreenState();
}

// =================================================================
// MODELO DE FILA EDITABLE
// =================================================================

class _FilaAnomaliaEditar {
  final TextEditingController torreController;
  final TextEditingController fechaRevisionController;
  final TextEditingController anomaliaController;
  final TextEditingController fechaCorreccionController;

  _FilaAnomaliaEditar({
    String torre = '',
    String fechaRevision = '',
    String anomalia = '',
    String fechaCorreccion = '',
  })  : torreController = TextEditingController(text: torre),
        fechaRevisionController =
            TextEditingController(text: fechaRevision),
        anomaliaController = TextEditingController(text: anomalia),
        fechaCorreccionController =
            TextEditingController(text: fechaCorreccion);

  void dispose() {
    torreController.dispose();
    fechaRevisionController.dispose();
    anomaliaController.dispose();
    fechaCorreccionController.dispose();
  }
}

// =================================================================
// ESTADO DEL EDITOR
// =================================================================

class _EditarInspeccionScreenState
    extends State<EditarInspeccionScreen> {
  final DatabaseHelper db = DatabaseHelper.instance;

  final TextEditingController fechaController =
      TextEditingController();

  final TextEditingController lineaController =
      TextEditingController();

  final TextEditingController zonaController =
      TextEditingController();

  final TextEditingController tipoController =
      TextEditingController();

  final TextEditingController elaboroController =
      TextEditingController();

  final TextEditingController vistoBuenoController =
      TextEditingController();

  // NUEVOS CAMPOS

  final List<String> tiposTorre = [
    'Suspensión',
    'Remate',
    'Flexión',
    'Transposición',
  ];

  final List<String> tiposCimentacion = [
    'Acero',
    'Madera',
    'Concreto',
  ];

  String? tipoTorreSeleccionado;
  String? tipoCimentacionSeleccionado;

  List<_FilaAnomaliaEditar> filas = [];

  bool cargando = true;
  bool guardando = false;

  // ==========================================================
  // CARGAR
  // ==========================================================

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final datos = await db.obtenerInspeccionCompleta(
      widget.inspeccionId,
    );

    if (!mounted) return;

    if (datos == null) {
      setState(() {
        cargando = false;
      });
      return;
    }

    final inspeccion = Map<String, dynamic>.from(
      datos['inspeccion'],
    );

    final anomalias = List<Map<String, dynamic>>.from(
      datos['anomalias'],
    );

    fechaController.text =
        '${inspeccion['fecha_inspeccion'] ?? ''}';

    lineaController.text =
        '${inspeccion['linea_transmision'] ?? ''}';

    zonaController.text =
        '${inspeccion['zona_transmision'] ?? ''}';

    tipoController.text =
        '${inspeccion['tipo_inspeccion'] ?? ''}';

    elaboroController.text =
        '${inspeccion['elaboro'] ?? ''}';

    vistoBuenoController.text =
        '${inspeccion['visto_bueno'] ?? ''}';

    final String tipoTorreGuardado =
        '${inspeccion['tipo_torre'] ?? ''}';

    final String tipoCimentacionGuardada =
        '${inspeccion['tipo_cimentacion'] ?? ''}';

    tipoTorreSeleccionado =
        tiposTorre.contains(tipoTorreGuardado)
            ? tipoTorreGuardado
            : null;

    tipoCimentacionSeleccionado =
        tiposCimentacion.contains(tipoCimentacionGuardada)
            ? tipoCimentacionGuardada
            : null;

    filas = anomalias.map((dato) {
      return _FilaAnomaliaEditar(
        torre: '${dato['numero_estacion'] ?? ''}',
        fechaRevision: '${dato['fecha_revision'] ?? ''}',
        anomalia: '${dato['anomalia'] ?? ''}',
        fechaCorreccion: '${dato['fecha_correccion'] ?? ''}',
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      cargando = false;
    });
  }

  // ==========================================================
  // FORMATEAR FECHA
  // ==========================================================

  String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  // ==========================================================
  // CONVERTIR FECHA
  // ==========================================================

  DateTime convertirFecha(String texto) {
    final partes = texto.split('/');

    if (partes.length == 3) {
      try {
        return DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      } catch (_) {}
    }

    return DateTime.now();
  }

  // ==========================================================
  // SELECCIONAR FECHA GENERAL
  // ==========================================================

  Future<void> seleccionarFechaGeneral() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: convertirFecha(fechaController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (fecha != null) {
      fechaController.text = formatearFecha(fecha);
    }
  }

  // ==========================================================
  // FECHA DE REVISIÓN
  // ==========================================================

  Future<void> seleccionarFechaRevision(
    _FilaAnomaliaEditar fila,
  ) async {
    DateTime fechaInicial = DateTime.now();

    if (fila.fechaRevisionController.text.trim().isNotEmpty) {
      fechaInicial = convertirFecha(
        fila.fechaRevisionController.text,
      );
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );

    if (fecha != null) {
      fila.fechaRevisionController.text = formatearFecha(fecha);
      setState(() {});
    }
  }

  // ==========================================================
  // ESTATUS DE CORRECCIÓN
  // ==========================================================

  Future<void> seleccionarCorreccion(
    _FilaAnomaliaEditar fila,
  ) async {
    final opcion = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Estatus de corrección',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _opcionCorreccion(context, fila, 'URGENTE'),
              _opcionCorreccion(context, fila, 'PROG 7 D'),
              _opcionCorreccion(context, fila, 'PROG 30 D'),
              _opcionCorreccion(context, fila, 'HECHO'),
            ],
          ),
        );
      },
    );

    if (opcion != null) {
      fila.fechaCorreccionController.text = opcion;
      setState(() {});
    }
  }

  Widget _opcionCorreccion(
    BuildContext context,
    _FilaAnomaliaEditar fila,
    String texto,
  ) {
    return ListTile(
      leading: Icon(
        Icons.circle,
        size: 14,
        color: texto == 'HECHO'
            ? Colors.green
            : texto == 'URGENTE'
                ? Colors.red
                : Colors.orange,
      ),
      title: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context, texto);
      },
    );
  }

  // ==========================================================
  // AGREGAR TORRE
  // ==========================================================

  void agregarTorre() {
    setState(() {
      filas.add(
        _FilaAnomaliaEditar(
          fechaRevision: fechaController.text,
        ),
      );
    });
  }

  // ==========================================================
  // ELIMINAR TORRE
  // ==========================================================

  void eliminarTorre(int index) {
    final fila = filas[index];
    fila.dispose();

    setState(() {
      filas.removeAt(index);
    });
  }

  // ==========================================================
  // GUARDAR CAMBIOS
  // ==========================================================

  Future<void> guardarCambios() async {
    if (guardando) return;

    if (fechaController.text.trim().isEmpty ||
        lineaController.text.trim().isEmpty ||
        zonaController.text.trim().isEmpty ||
        tipoController.text.trim().isEmpty ||
        tipoTorreSeleccionado == null ||
        tipoCimentacionSeleccionado == null ||
        elaboroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos obligatorios, '
            'incluyendo tipo de torre y cimentación.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final inspeccion = {
        'fecha_inspeccion': fechaController.text.trim(),
        'linea_transmision': lineaController.text.trim(),
        'zona_transmision': zonaController.text.trim(),
        'tipo_inspeccion': tipoController.text.trim(),
        'tipo_torre': tipoTorreSeleccionado,
        'tipo_cimentacion': tipoCimentacionSeleccionado,
        'elaboro': elaboroController.text.trim(),
        'visto_bueno': vistoBuenoController.text.trim(),
        'sincronizado': 0,
      };

      final List<Map<String, dynamic>> anomalias = [];

      for (final fila in filas) {
        if (fila.torreController.text.trim().isEmpty) {
          continue;
        }

        anomalias.add({
          'numero_estacion': fila.torreController.text.trim(),
          'fecha_revision':
              fila.fechaRevisionController.text.trim(),
          'anomalia': fila.anomaliaController.text.trim(),
          'fecha_correccion':
              fila.fechaCorreccionController.text.trim(),
        });
      }

      await db.actualizarInspeccionCompleta(
        inspeccionId: widget.inspeccionId,
        inspeccion: inspeccion,
        anomalias: anomalias,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron guardar los cambios.\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    fechaController.dispose();
    lineaController.dispose();
    zonaController.dispose();
    tipoController.dispose();
    elaboroController.dispose();
    vistoBuenoController.dispose();

    for (final fila in filas) {
      fila.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A4D),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Editar inspección',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007A4D),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // INFORMACIÓN GENERAL

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      border: Border.all(
                        color: const Color(0xFF007A4D),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INFORMACIÓN GENERAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A4D),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _campoTexto(
                    'Fecha de inspección',
                    fechaController,
                    readOnly: true,
                    onTap: seleccionarFechaGeneral,
                    icono: Icons.calendar_month,
                  ),

                  _campoTexto(
                    'Línea de transmisión',
                    lineaController,
                  ),

                  _campoTexto(
                    'Zona',
                    zonaController,
                  ),

                  _campoTexto(
                    'Tipo de inspección',
                    tipoController,
                  ),

                  // TIPO DE TORRE

                  _campoDesplegable(
                    etiqueta: 'Tipo de torre',
                    valor: tipoTorreSeleccionado,
                    opciones: tiposTorre,
                    icono: Icons.account_tree_outlined,
                    alCambiar: (valor) {
                      setState(() {
                        tipoTorreSeleccionado = valor;
                      });
                    },
                  ),

                  // TIPO DE CIMENTACIÓN

                  _campoDesplegable(
                    etiqueta: 'Tipo de cimentación',
                    valor: tipoCimentacionSeleccionado,
                    opciones: tiposCimentacion,
                    icono: Icons.foundation,
                    alCambiar: (valor) {
                      setState(() {
                        tipoCimentacionSeleccionado = valor;
                      });
                    },
                  ),

                  _campoTexto(
                    'Elaboró',
                    elaboroController,
                  ),

                  _campoTexto(
                    'Vo. Bo.',
                    vistoBuenoController,
                  ),

                  const SizedBox(height: 15),

                  // TORRES

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'TORRES / ANOMALÍAS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A4D),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: agregarTorre,
                        icon: const Icon(
                          Icons.add,
                          size: 20,
                        ),
                        label: const Text(
                          'AGREGAR',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF007A4D),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (filas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'No hay torres registradas.\n'
                        'Presiona AGREGAR para añadir una.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      filas.length,
                      (index) {
                        final fila = filas[index];

                        return _tarjetaTorreEditar(
                          fila,
                          index,
                        );
                      },
                    ),

                  const SizedBox(height: 15),

                  // GUARDAR

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: guardando ? null : guardarCambios,
                      icon: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
                            : 'GUARDAR CAMBIOS',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF007A4D),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: guardando
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // CAMPO DE TEXTO
  // ==========================================================

  Widget _campoTexto(
    String etiqueta,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: etiqueta,
          labelStyle: const TextStyle(fontSize: 14),
          suffixIcon: icono == null
              ? null
              : Icon(
                  icono,
                  color: const Color(0xFF007A4D),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFF007A4D),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO DESPLEGABLE
  // ==========================================================

  Widget _campoDesplegable({
    required String etiqueta,
    required String? valor,
    required List<String> opciones,
    required IconData icono,
    required ValueChanged<String?> alCambiar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          labelStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(
            icono,
            color: const Color(0xFF007A4D),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFF007A4D),
              width: 2,
            ),
          ),
        ),
        items: opciones.map((opcion) {
          return DropdownMenuItem<String>(
            value: opcion,
            child: Text(
              opcion,
              style: const TextStyle(fontSize: 15),
            ),
          );
        }).toList(),
        onChanged: alCambiar,
      ),
    );
  }

  // ==========================================================
  // TARJETA DE TORRE
  // ==========================================================

  Widget _tarjetaTorreEditar(
    _FilaAnomaliaEditar fila,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TORRE ${index + 1}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A4D),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar torre',
                  onPressed: () {
                    eliminarTorre(index);
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            // TORRE

            TextField(
              controller: fila.torreController,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Número de torre / estación',
                labelStyle: TextStyle(fontSize: 14),
                prefixIcon: Icon(
                  Icons.electrical_services,
                  color: Color(0xFF007A4D),
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // FECHA DE REVISIÓN

            TextField(
              controller: fila.fechaRevisionController,
              readOnly: true,
              onTap: () {
                seleccionarFechaRevision(fila);
              },
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Fecha de revisión',
                labelStyle: TextStyle(fontSize: 14),
                suffixIcon: Icon(
                  Icons.calendar_month,
                  color: Color(0xFF007A4D),
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // ANOMALÍA

            TextField(
              controller: fila.anomaliaController,
              maxLines: 3,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Anomalía',
                labelStyle: TextStyle(fontSize: 14),
                hintText: 'Escribe la anomalía encontrada...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // CORRECCIÓN

            TextField(
              controller: fila.fechaCorreccionController,
              readOnly: true,
              onTap: () {
                seleccionarCorreccion(fila);
              },
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                labelText: 'Estatus de corrección',
                labelStyle: TextStyle(fontSize: 14),
                hintText: 'Selecciona un estatus',
                suffixIcon: Icon(
                  Icons.fact_check,
                  color: Color(0xFF007A4D),
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}