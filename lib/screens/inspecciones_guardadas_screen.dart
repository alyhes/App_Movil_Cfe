import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/excel_export_service.dart';

// ============================================================
// PANTALLA DE INSPECCIONES GUARDADAS
// ============================================================

class InspeccionesGuardadasScreen extends StatefulWidget {
  const InspeccionesGuardadasScreen({super.key});

  @override
  State<InspeccionesGuardadasScreen> createState() =>
      _InspeccionesGuardadasScreenState();
}

// ============================================================
// ESTADO
// ============================================================

class _InspeccionesGuardadasScreenState
    extends State<InspeccionesGuardadasScreen> {
  // ==========================================================
  // BASE DE DATOS
  // ==========================================================

  final DatabaseHelper db = DatabaseHelper.instance;

  // ==========================================================
  // DATOS
  // ==========================================================

  List<Map<String, dynamic>> inspecciones = [];
  List<Map<String, dynamic>> inspeccionesFiltradas = [];

  // ==========================================================
  // BUSCADOR
  // ==========================================================

  final TextEditingController buscadorController =
      TextEditingController();

  // ==========================================================
  // FILTRO POR FECHA
  // ==========================================================

  DateTime? fechaFiltro;

  // ==========================================================
  // ORDEN
  // ==========================================================

  bool ordenDescendente = true;

  // ==========================================================
  // EXPORTACIÓN A EXCEL
  // ==========================================================

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
    final texto =
        buscadorController.text.trim().toLowerCase();

    List<Map<String, dynamic>> resultado =
        List<Map<String, dynamic>>.from(inspecciones);

    // ========================================================
    // BUSCADOR
    // ========================================================

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
            elaboro.contains(texto) ||
            vistoBueno.contains(texto);
      }).toList();
    }

    // ========================================================
    // FILTRO POR DÍA
    // ========================================================

    if (fechaFiltro != null) {
      resultado = resultado.where((inspeccion) {
        final fecha = convertirFecha(
          inspeccion['fecha_inspeccion']?.toString(),
        );

        if (fecha == null) {
          return false;
        }

        return fecha.year == fechaFiltro!.year &&
            fecha.month == fechaFiltro!.month &&
            fecha.day == fechaFiltro!.day;
      }).toList();
    }

    // ========================================================
    // ORDENAR
    // ========================================================

    resultado.sort((a, b) {
      final fechaA = convertirFecha(
        a['fecha_inspeccion']?.toString(),
      );

      final fechaB = convertirFecha(
        b['fecha_inspeccion']?.toString(),
      );

      if (fechaA == null && fechaB == null) {
        return 0;
      }

      if (fechaA == null) {
        return 1;
      }

      if (fechaB == null) {
        return -1;
      }

      final comparacion =
          fechaA.compareTo(fechaB);

      return ordenDescendente
          ? -comparacion
          : comparacion;
    });

    // ========================================================
    // ACTUALIZAR RESULTADOS
    // ========================================================

    if (!mounted) return;

    setState(() {
      inspeccionesFiltradas = resultado;
    });
  }

  // ==========================================================
  // EXPORTAR A EXCEL
  // ==========================================================

  Future<void> exportarAExcel(
    Map<String, dynamic> inspeccion,
  ) async {
    final int id = inspeccion['id'];

    if (exportandoId != null) {
      return;
    }

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
            backgroundColor:
                Color(0xFF007A4D),
            duration:
                Duration(seconds: 3),
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
            duration:
                const Duration(seconds: 5),
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
  // SELECCIONAR DÍA
  // ==========================================================

  Future<void> seleccionarDia() async {
    final DateTime? fecha =
        await showDatePicker(
      context: context,
      initialDate:
          fechaFiltro ?? DateTime.now(),
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2100),
      locale:
          const Locale('es', 'MX'),
      helpText:
          'BUSCAR INSPECCIONES DEL DÍA',
      cancelText:
          'CANCELAR',
      confirmText:
          'ACEPTAR',
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
      ordenDescendente =
          !ordenDescendente;
    });

    aplicarFiltros();
  }

  // ==========================================================
  // FORMATO DE FECHA
  // ==========================================================

  String formatearFecha(
    DateTime fecha,
  ) {
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
    final int id =
        inspeccion['id'];

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar inspección',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Deseas eliminar la inspección número $id?\n\n'
            'También se eliminarán las anomalías '
            'relacionadas con esta inspección.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'ELIMINAR',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await db.eliminarInspeccion(id);

    if (!mounted) return;

    await cargarInspecciones();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Inspección eliminada correctamente.',
        ),
        backgroundColor:
            Color(0xFF007A4D),
      ),
    );
  }

  // ==========================================================
  // VER DETALLE
  // ==========================================================

  Future<void> verDetalle(
    Map<String, dynamic> inspeccion,
  ) async {
    final int id =
        inspeccion['id'];

    final datos =
        await db.obtenerInspeccionCompleta(
      id,
    );

    if (!mounted) return;

    if (datos == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo obtener la información.',
          ),
          backgroundColor:
              Colors.red,
        ),
      );

      return;
    }

    final Map<String, dynamic>
        datosInspeccion =
        datos['inspeccion']
            as Map<String, dynamic>;

    final List<dynamic>
        anomalias =
        datos['anomalias']
            as List<dynamic>;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.assignment,
                color:
                    Color(0xFF007A4D),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detalle de inspección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width:
                double.maxFinite,
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
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
                    'Elaboró',
                    '${datosInspeccion['elaboro'] ?? ''}',
                  ),

                  _datoDetalle(
                    'Vo. Bo.',
                    '${datosInspeccion['visto_bueno'] ?? 'No especificado'}',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'TORRES / ANOMALÍAS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF007A4D),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (anomalias.isEmpty)
                    const Text(
                      'No hay anomalías registradas.',
                      style: TextStyle(
                        color:
                            Colors.grey,
                      ),
                    )
                  else
                    ...anomalias.map(
                      (anomalia) {
                        final Map<String,
                                dynamic>
                            dato =
                            Map<String,
                                dynamic>.from(
                          anomalia,
                        );

                        return Container(
                          width:
                              double.infinity,
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 8,
                          ),
                          padding:
                              const EdgeInsets
                                  .all(8),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF5F5F5,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.grey,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Torre: ${dato['numero_estacion'] ?? ''}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Color(
                                    0xFF007A4D,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Fecha de revisión: '
                                '${dato['fecha_revision'] ?? ''}',
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                'Anomalía: '
                                '${dato['anomalia'] ?? ''}',
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                'Fecha de corrección: '
                                '${dato['fecha_correccion'] ?? ''}',
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF007A4D,
                ),
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'CERRAR',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DATO DEL DETALLE
  // ==========================================================

  Widget _datoDetalle(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            valor,
            style:
                const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF007A4D),
        foregroundColor:
            Colors.white,
        centerTitle: true,
        title: const Text(
          'Inspecciones guardadas',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      // ========================================================
      // CONTENIDO
      // ========================================================

      body: RefreshIndicator(
        onRefresh:
            cargarInspecciones,
        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              // ==================================================
              // BUSCADOR
              // ==================================================

              TextField(
                controller:
                    buscadorController,
                decoration:
                    InputDecoration(
                  labelText:
                      'Buscar inspección',
                  hintText:
                      'Fecha, línea, zona, tipo o nombre...',
                  prefixIcon:
                      const Icon(
                    Icons.search,
                    color:
                        Color(0xFF007A4D),
                  ),
                  suffixIcon:
                      buscadorController
                              .text
                              .isNotEmpty
                          ? IconButton(
                              icon:
                                  const Icon(
                                Icons.clear,
                              ),
                              onPressed:
                                  () {
                                buscadorController
                                    .clear();
                              },
                            )
                          : null,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      6,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      6,
                    ),
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
                height: 10,
              ),

              // ==================================================
              // BOTONES DE FILTRO
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton
                            .icon(
                      onPressed:
                          seleccionarDia,
                      icon:
                          const Icon(
                        Icons
                            .calendar_month,
                        size: 19,
                      ),
                      label: Text(
                        fechaFiltro ==
                                null
                            ? 'Buscar por día'
                            : formatearFecha(
                                fechaFiltro!,
                              ),
                        style:
                            const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            const Color(
                          0xFF007A4D,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFF007A4D,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (fechaFiltro !=
                      null)
                    IconButton(
                      tooltip:
                          'Quitar filtro de fecha',
                      onPressed:
                          limpiarFiltroFecha,
                      icon:
                          const Icon(
                        Icons.clear,
                        color:
                            Colors.red,
                      ),
                    ),

                  const SizedBox(
                    width: 5,
                  ),

                  IconButton(
                    tooltip:
                        ordenDescendente
                            ? 'Más antiguas primero'
                            : 'Más recientes primero',
                    onPressed:
                        cambiarOrden,
                    icon: Icon(
                      ordenDescendente
                          ? Icons
                              .arrow_downward
                          : Icons
                              .arrow_upward,
                      color:
                          const Color(
                        0xFF007A4D,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // INFORMACIÓN DE RESULTADOS
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F5E9,
                  ),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFF007A4D,
                    ),
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder,
                      color:
                          Color(
                        0xFF007A4D,
                      ),
                      size: 20,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        '${inspeccionesFiltradas.length} '
                        'inspección(es) encontrada(s)',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xFF007A4D,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // LISTA
              // ==================================================

              if (inspeccionesFiltradas
                  .isEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(
                    30,
                  ),
                  decoration:
                      BoxDecoration(
                    border:
                        Border.all(
                      color:
                          Colors.grey,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      6,
                    ),
                  ),
                  child:
                      const Column(
                    children: [
                      Icon(
                        Icons
                            .folder_open,
                        size: 50,
                        color:
                            Colors.grey,
                      ),

                      SizedBox(
                        height: 10,
                      ),

                      Text(
                        'No se encontraron inspecciones.',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...inspeccionesFiltradas
                    .map(
                  (inspeccion) =>
                      _tarjetaInspeccion(
                    inspeccion,
                  ),
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
    Map<String, dynamic>
        inspeccion,
  ) {
    final int id =
        inspeccion['id'];

    final String fecha =
        '${inspeccion['fecha_inspeccion'] ?? ''}';

    final String linea =
        '${inspeccion['linea_transmision'] ?? ''}';

    final String zona =
        '${inspeccion['zona_transmision'] ?? ''}';

    final String tipo =
        '${inspeccion['tipo_inspeccion'] ?? ''}';

    final String elaboro =
        '${inspeccion['elaboro'] ?? ''}';

    final bool estaExportando =
        exportandoId == id;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          7,
        ),
        side:
            const BorderSide(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          10,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // ==================================================
            // ENCABEZADO
            // ==================================================

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .all(8),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE8F5E9,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      5,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.assignment,
                    color:
                        Color(
                      0xFF007A4D,
                    ),
                    size: 22,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'INSPECCIÓN #$id',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              Color(
                            0xFF007A4D,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        fecha,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<
                    String>(
                  onSelected:
                      (opcion) {
                    if (opcion ==
                        'ver') {
                      verDetalle(
                        inspeccion,
                      );
                    }

                    if (opcion ==
                        'eliminar') {
                      eliminarInspeccion(
                        inspeccion,
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                    const PopupMenuItem(
                      value: 'ver',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .visibility,
                            size: 20,
                            color:
                                Color(
                              0xFF007A4D,
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Ver detalle',
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem(
                      value:
                          'eliminar',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete,
                            size: 20,
                            color:
                                Colors
                                    .red,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Eliminar',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(),

            // ==================================================
            // INFORMACIÓN
            // ==================================================

            _filaInformacion(
              Icons
                  .electrical_services,
              'Línea',
              linea,
            ),

            _filaInformacion(
              Icons
                  .location_on_outlined,
              'Zona',
              zona,
            ),

            _filaInformacion(
              Icons
                  .assignment_outlined,
              'Tipo',
              tipo,
            ),

            _filaInformacion(
              Icons
                  .person_outline,
              'Elaboró',
              elaboro,
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // BOTÓN 1
            // VER INSPECCIÓN COMPLETA
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    estaExportando
                        ? null
                        : () {
                            verDetalle(
                              inspeccion,
                            );
                          },
                icon:
                    const Icon(
                  Icons.visibility,
                  size: 18,
                ),
                label:
                    const Text(
                  'VER INSPECCIÓN COMPLETA',
                ),
                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF007A4D,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFF007A4D,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // BOTÓN 2
            // EXPORTAR A EXCEL
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    estaExportando
                        ? null
                        : () {
                            exportarAExcel(
                              inspeccion,
                            );
                          },
                icon:
                    estaExportando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .table_view,
                            size: 18,
                          ),
                label: Text(
                  estaExportando
                      ? 'GENERANDO EXCEL...'
                      : 'EXPORTAR A EXCEL',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF007A4D,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
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
      padding:
          const EdgeInsets.only(
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Icon(
            icono,
            size: 17,
            color:
                const Color(
              0xFF007A4D,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            '$titulo: ',
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(
              valor,
              style:
                  const TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}