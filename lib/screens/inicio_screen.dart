import 'package:flutter/material.dart';

// ============================================================
// PANTALLA PRINCIPAL - FORMATO DE INSPECCIÓN CFE
// ============================================================

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // ============================================================
  // DATOS DE LÍNEAS DE TRANSMISIÓN
  // ============================================================

  String? voltajeSeleccionado;
  String? lineaSeleccionada;

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
  // ZONA DE TRANSMISIÓN
  // ============================================================

  String? zonaSeleccionada;

  final List<String> zonasTransmision = [
    'Escárcega',
    'Santa Lucía',
  ];

  // ============================================================
  // DATOS PARA BUSCAR Y SELECCIONAR TORRES
  // ============================================================

  final TextEditingController buscadorTorreController =
      TextEditingController();

  String busquedaTorre = '';

  // Torres seleccionadas para la inspección actual
  final List<String> torresSeleccionadas = [];

  // ============================================================
  // OPCIONES DE VOLTAJE
  // ============================================================

  final List<String> voltajes = [
    '115 kV',
    '230 kV',
    '400 kV',
  ];

  // ============================================================
  // LÍNEAS DISPONIBLES SEGÚN EL VOLTAJE
  // ============================================================

  List<String> obtenerLineas() {
    switch (voltajeSeleccionado) {
      case '115 kV':
        return [];

      case '230 kV':
        return [
          '93210',
          '93220',
        ];

      case '400 kV':
        return [
          'A3Q00',
          'A3Q10',
        ];

      default:
        return [];
    }
  }

  // ============================================================
  // TORRES
  // ============================================================
  //
  // Por ahora cada línea tiene 50 torres de prueba:
  // T-001 hasta T-050.
  //
  // Posteriormente podemos sustituirlas por los números
  // reales de las torres.
  //
  // ============================================================

  List<String> obtenerTorres() {
    if (voltajeSeleccionado == null ||
        lineaSeleccionada == null) {
      return [];
    }

    // ==========================================================
    // 230 kV
    // ==========================================================

    if (voltajeSeleccionado == '230 kV' &&
        (lineaSeleccionada == '93210' ||
            lineaSeleccionada == '93220')) {
      return List.generate(
        50,
        (index) =>
            'T-${(index + 1).toString().padLeft(3, '0')}',
      );
    }

    // ==========================================================
    // 400 kV
    // ==========================================================

    if (voltajeSeleccionado == '400 kV' &&
        (lineaSeleccionada == 'A3Q00' ||
            lineaSeleccionada == 'A3Q10')) {
      return List.generate(
        50,
        (index) =>
            'T-${(index + 1).toString().padLeft(3, '0')}',
      );
    }

    return [];
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
  // SELECCIONAR / DESELECCIONAR TORRE
  // ============================================================

  void cambiarSeleccionTorre(String torre) {
    setState(() {
      if (torresSeleccionadas.contains(torre)) {
        torresSeleccionadas.remove(torre);
      } else {
        torresSeleccionadas.add(torre);
      }
    });
  }

  // ============================================================
  // LIMPIAR TORRES
  // ============================================================

  void limpiarTorresSeleccionadas() {
    setState(() {
      torresSeleccionadas.clear();
    });
  }

  // ============================================================
  // SELECCIONAR FECHA
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    buscadorTorreController.dispose();
    tipoInspeccionController.dispose();
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
      ),

      // ========================================================
      // CONTENIDO DEL FORMATO
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [

                  Text(
                    'Hoja: 1 de 1',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'CLAVE: P-T150-LT01-R-05',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'REVISIÓN: 1',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'FECHA DE ELABORACIÓN: 29.01.2021',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TÍTULO DEL FORMATO
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
            // INFORMACIÓN DE LA INSPECCIÓN
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'LÍNEA DE TRANSMISIÓN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // VOLTAJE

                  DropdownButtonFormField<String>(
                    initialValue: voltajeSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Seleccione el voltaje',
                      labelStyle: const TextStyle(
                        fontSize: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(5),
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
                      });
                    },
                  ),

                  // LÍNEA

                  if (voltajeSeleccionado != null) ...[
                    const SizedBox(height: 10),

                    Text(
                      'LÍNEA ${voltajeSeleccionado!}:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (obtenerLineas().isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: lineaSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Seleccione la línea',
                          labelStyle: const TextStyle(
                            fontSize: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(5),
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
                          return DropdownMenuItem<String>(
                            value: linea,
                            child: Text(linea),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            lineaSeleccionada = valor;
                            torresSeleccionadas.clear();
                            busquedaTorre = '';
                            buscadorTorreController.clear();
                          });
                        },
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Líneas pendientes de configurar',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],

                  // TORRES

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

                    // BUSCADOR

                    TextField(
                      controller:
                          buscadorTorreController,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar número de torre...',
                        hintStyle:
                            const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        prefixIcon:
                            const Icon(
                          Icons.search,
                          size: 20,
                        ),
                        suffixIcon:
                            buscadorTorreController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    icon:
                                        const Icon(
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
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  5),
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                      keyboardType:
                          TextInputType.text,
                      onChanged: (valor) {
                        setState(() {
                          busquedaTorre = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    // CONTADOR

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            torresSeleccionadas
                                    .isNotEmpty
                                ? const Color(
                                    0xFFE8F5E9)
                                : const Color(
                                    0xFFF2F2F2),
                        borderRadius:
                            BorderRadius.circular(
                                5),
                        border: Border.all(
                          color:
                              torresSeleccionadas
                                      .isNotEmpty
                                  ? const Color(
                                      0xFF007A4D)
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
                                    ? const Color(
                                        0xFF007A4D)
                                    : Colors.grey,
                          ),

                          const SizedBox(width: 7),

                          Expanded(
                            child: Text(
                              '${torresSeleccionadas.length} TORRES SELECCIONADAS',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    torresSeleccionadas
                                            .isNotEmpty
                                        ? const Color(
                                            0xFF007A4D)
                                        : Colors
                                            .grey[700],
                              ),
                            ),
                          ),

                          if (torresSeleccionadas
                              .isNotEmpty)
                            TextButton(
                              onPressed:
                                  limpiarTorresSeleccionadas,
                              child:
                                  const Text(
                                'LIMPIAR',
                                style:
                                    TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // LISTA DE TORRES

                    if (obtenerTorres()
                        .isNotEmpty)
                      Container(
                        height: 230,
                        decoration:
                            BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  5),
                        ),
                        child:
                            ListView.builder(
                          itemCount:
                              obtenerTorresFiltradas()
                                  .length,
                          itemBuilder:
                              (context, index) {

                            final torres =
                                obtenerTorresFiltradas();

                            final torre =
                                torres[index];

                            final seleccionada =
                                torresSeleccionadas
                                    .contains(
                                        torre);

                            return CheckboxListTile(
                              dense: true,
                              visualDensity:
                                  const VisualDensity(
                                vertical: -2,
                              ),
                              title: Text(
                                torre,
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                              value:
                                  seleccionada,
                              activeColor:
                                  const Color(
                                      0xFF007A4D),
                              controlAffinity:
                                  ListTileControlAffinity
                                      .leading,
                              onChanged:
                                  (valor) {
                                cambiarSeleccionTorre(
                                    torre);
                              },
                            );
                          },
                        ),
                      ),

                    // CUANDO NO HAY RESULTADOS

                    if (obtenerTorresFiltradas()
                        .isEmpty)
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets
                                .all(12),
                        decoration:
                            BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  5),
                        ),
                        child:
                            const Text(
                          'No se encontraron torres.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    // TORRES SELECCIONADAS

                    if (torresSeleccionadas
                        .isNotEmpty) ...[
                      const SizedBox(height: 10),

                      const Text(
                        'TORRES SELECCIONADAS:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
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
                            label: Text(
                              torre,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                            deleteIcon:
                                const Icon(
                              Icons.close,
                              size: 15,
                            ),
                            onDeleted: () {
                              cambiarSeleccionTorre(
                                  torre);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),

                  // FECHA

                  _campoFecha(),

                  const SizedBox(height: 14),

                  // TIPO DE INSPECCIÓN

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
                    decoration:
                        InputDecoration(
                      hintText:
                          'Escriba el tipo de inspección...',
                      hintStyle:
                          const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                5),
                      ),
                      contentPadding:
                          const EdgeInsets.all(
                              10),
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ZONA DE TRANSMISIÓN

                  const Text(
                    'ZONA DE TRANSMISIÓN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    initialValue:
                        zonaSeleccionada,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Seleccione la zona',
                      labelStyle:
                          const TextStyle(
                        fontSize: 11,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                                5),
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                    items:
                        zonasTransmision
                            .map((zona) {
                      return DropdownMenuItem<
                          String>(
                        value: zona,
                        child: Text(zona),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        zonaSeleccionada =
                            valor;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // TABLA DE ANOMALÍAS
            // ==================================================

            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Table(
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

                  TableRow(
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFE8E8E8),
                    ),
                    children: const [

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

                  _filaTabla(),
                  _filaTabla(),
                  _filaTabla(),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // ELABORÓ
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(10),
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
                    'ELABORÓ:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 18),

                  Divider(
                    color: Colors.black,
                    height: 1,
                  ),

                  SizedBox(height: 4),

                  Center(
                    child: Text(
                      '(Nombre y RPE)',
                      style:
                          TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    'Vo. Bo.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 18),

                  Divider(
                    color: Colors.black,
                    height: 1,
                  ),

                  SizedBox(height: 4),

                  Center(
                    child: Text(
                      '(Nombre y RPE)',
                      style:
                          TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PIE

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
  // CAMPO FECHA
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
                      : '${fechaSeleccionada!.day.toString().padLeft(2, '0')}/'
                        '${fechaSeleccionada!.month.toString().padLeft(2, '0')}/'
                        '${fechaSeleccionada!.year}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        fechaSeleccionada == null
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

// ============================================================
// FILA DE TABLA
// ============================================================

TableRow _filaTabla() {
  return const TableRow(
    children: [

      SizedBox(
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(
            '',
            style: TextStyle(fontSize: 9),
          ),
        ),
      ),

      SizedBox(
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(
            '',
            style: TextStyle(fontSize: 9),
          ),
        ),
      ),

      SizedBox(
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(
            '',
            style: TextStyle(fontSize: 9),
          ),
        ),
      ),

      SizedBox(
        height: 42,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(
            '',
            style: TextStyle(fontSize: 9),
          ),
        ),
      ),
    ],
  );
}