import 'package:flutter/material.dart';
import '../models/anomalia.dart';
import '../database/database_helper.dart';

class NuevaInspeccionScreen extends StatefulWidget {
  const NuevaInspeccionScreen({super.key});

  @override
  State<NuevaInspeccionScreen> createState() =>
      _NuevaInspeccionScreenState();
}

class _NuevaInspeccionScreenState
    extends State<NuevaInspeccionScreen> {
  final TextEditingController lineaController =
      TextEditingController();

  final TextEditingController zonaController =
      TextEditingController();

  final TextEditingController elaboroController =
      TextEditingController();

  final TextEditingController voBoController =
      TextEditingController();

  DateTime fechaSeleccionada = DateTime.now();

  String? tipoInspeccion;

  final List<Anomalia> anomalias = [
    Anomalia(),
  ];

  @override
  void dispose() {
    lineaController.dispose();
    zonaController.dispose();
    elaboroController.dispose();
    voBoController.dispose();

    for (final anomalia in anomalias) {
      anomalia.dispose();
    }

    super.dispose();
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      setState(() {
        fechaSeleccionada = fecha;
      });
    }
  }

  String formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  void agregarAnomalia() {
    setState(() {
      anomalias.add(Anomalia());
    });
  }

  void eliminarAnomalia(int index) {
    if (anomalias.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe existir al menos un registro.',
          ),
        ),
      );

      return;
    }

    setState(() {
      anomalias[index].dispose();
      anomalias.removeAt(index);
    });
  }

  Future<void> guardarInspeccion() async {
    if (lineaController.text.trim().isEmpty ||
        zonaController.text.trim().isEmpty ||
        tipoInspeccion == null ||
        elaboroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa los campos obligatorios antes de guardar.',
          ),
        ),
      );

      return;
    }

    try {
      final int inspeccionId =
          await DatabaseHelper.instance.insertarInspeccion({
        'fecha_inspeccion': formatoFecha(fechaSeleccionada),
        'linea_transmision': lineaController.text.trim(),
        'zona_transmision': zonaController.text.trim(),
        'tipo_inspeccion': tipoInspeccion,
        'elaboro': elaboroController.text.trim(),
        'visto_bueno': voBoController.text.trim(),
        'sincronizado': 0,
      });

      for (final anomalia in anomalias) {
        await DatabaseHelper.instance.insertarAnomalia({
          'inspeccion_id': inspeccionId,
          'fecha_revision':
              anomalia.fechaRevision.text.trim(),
          'numero_estacion':
              anomalia.numeroEstacion.text.trim(),
          'anomalia':
              anomalia.anomalia.text.trim(),
          'fecha_correccion':
              anomalia.fechaCorreccion.text.trim(),
        });
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Inspección guardada',
            ),
            content: Text(
              'La inspección se guardó correctamente '
              'en el dispositivo.\n\n'
              'Número de registro: $inspeccionId',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar la inspección: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  void cerrarSesion() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A4D),
        foregroundColor: Colors.white,

        title: const Text(
          'Nueva Inspección',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          // BOTÓN CERRAR SESIÓN
          TextButton.icon(
            onPressed: cerrarSesion,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // BOTÓN GUARDAR
          IconButton(
            tooltip: 'Guardar',
            onPressed: guardarInspeccion,
            icon: const Icon(
              Icons.save,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                // ============================================================
                // ENCABEZADO CFE
                // ============================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        const Text(
                          'COMISIÓN FEDERAL DE ELECTRICIDAD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'DIRECCIÓN DE OPERACIÓN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'GERENCIA REGIONAL DE TRANSMISIÓN PENINSULAR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'INSPECCIÓN DE LÍNEAS DE TRANSMISIÓN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A4D),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Divider(),

                        const SizedBox(height: 15),

                        Wrap(
                          spacing: 40,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,

                          children: const [
                            Text(
                              'HOJA: 1 DE 1',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              'CLAVE: P-T150-LT01-R-05',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              'REVISIÓN: 1',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              'FECHA DE ELABORACIÓN: 29.01.2021',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // TÍTULO
                // ============================================================

                Container(
                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: const Color(0xFF007A4D),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Text(
                    'TRABAJOS PENDIENTES EN LA LÍNEA DE TRANSMISIÓN',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // DATOS GENERALES
                // ============================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'DATOS GENERALES',

                          style: TextStyle(
                            color: Color(0xFF007A4D),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'LÍNEA DE TRANSMISIÓN *',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller: lineaController,

                          decoration: const InputDecoration(
                            hintText:
                                'Ingrese la línea de transmisión',

                            prefixIcon: Icon(
                              Icons.electrical_services,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'FECHA *',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        InkWell(
                          onTap: seleccionarFecha,

                          child: InputDecorator(
                            decoration:
                                const InputDecoration(
                              prefixIcon: Icon(
                                Icons.calendar_month,
                              ),
                            ),

                            child: Text(
                              formatoFecha(
                                fechaSeleccionada,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'TIPO DE INSPECCIÓN *',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        DropdownButtonFormField<String>(
                          initialValue: tipoInspeccion,

                          decoration:
                              const InputDecoration(
                            prefixIcon: Icon(
                              Icons.fact_check,
                            ),
                          ),

                          hint: const Text(
                            'Seleccione el tipo de inspección',
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: 'Inspección normal',
                              child: Text(
                                'Inspección normal',
                              ),
                            ),

                            DropdownMenuItem(
                              value: 'Inspección especial',
                              child: Text(
                                'Inspección especial',
                              ),
                            ),

                            DropdownMenuItem(
                              value:
                                  'Inspección de seguimiento',
                              child: Text(
                                'Inspección de seguimiento',
                              ),
                            ),

                            DropdownMenuItem(
                              value:
                                  'Inspección por anomalía',
                              child: Text(
                                'Inspección por anomalía',
                              ),
                            ),
                          ],

                          onChanged: (valor) {
                            setState(() {
                              tipoInspeccion = valor;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'ZONA DE TRANSMISIÓN *',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller: zonaController,

                          decoration: const InputDecoration(
                            hintText:
                                'Ingrese la zona de transmisión',

                            prefixIcon: Icon(
                              Icons.location_on,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // TRABAJOS PENDIENTES
                // ============================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'TRABAJOS PENDIENTES',

                          style: TextStyle(
                            color: Color(0xFF007A4D),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        SingleChildScrollView(
                          scrollDirection:
                              Axis.horizontal,

                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(
                              const Color(0xFF007A4D),
                            ),

                            headingTextStyle:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),

                            columnSpacing: 12,

                            columns: const [
                              DataColumn(
                                label: SizedBox(
                                  width: 130,

                                  child: Text(
                                    'FECHA DE\nREVISIÓN',
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                ),
                              ),

                              DataColumn(
                                label: SizedBox(
                                  width: 90,

                                  child: Text(
                                    'NO. EST.',
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                ),
                              ),

                              DataColumn(
                                label: SizedBox(
                                  width: 280,

                                  child: Text(
                                    'ANOMALÍA ENCONTRADA',
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                ),
                              ),

                              DataColumn(
                                label: SizedBox(
                                  width: 150,

                                  child: Text(
                                    'FECHA DE\nCORRECCIÓN',
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                ),
                              ),

                              DataColumn(
                                label: SizedBox(
                                  width: 50,

                                  child: Text(''),
                                ),
                              ),
                            ],

                            rows: List.generate(
                              anomalias.length,

                              (index) {
                                final anomalia =
                                    anomalias[index];

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 130,

                                        child: TextField(
                                          controller:
                                              anomalia
                                                  .fechaRevision,

                                          decoration:
                                              const InputDecoration(
                                            hintText:
                                                'DD/MM/AAAA',
                                          ),
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      SizedBox(
                                        width: 90,

                                        child: TextField(
                                          controller:
                                              anomalia
                                                  .numeroEstacion,

                                          decoration:
                                              const InputDecoration(
                                            hintText: 'No.',
                                          ),
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      SizedBox(
                                        width: 280,

                                        child: TextField(
                                          controller:
                                              anomalia.anomalia,

                                          maxLines: 2,

                                          decoration:
                                              const InputDecoration(
                                            hintText:
                                                'Describa la anomalía',
                                          ),
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      SizedBox(
                                        width: 150,

                                        child: TextField(
                                          controller:
                                              anomalia
                                                  .fechaCorreccion,

                                          decoration:
                                              const InputDecoration(
                                            hintText:
                                                'DD/MM/AAAA',
                                          ),
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      IconButton(
                                        tooltip: 'Eliminar',

                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),

                                        onPressed: () {
                                          eliminarAnomalia(
                                            index,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,

                          child: OutlinedButton.icon(
                            onPressed: agregarAnomalia,

                            icon: const Icon(
                              Icons.add,
                            ),

                            label: const Text(
                              'AGREGAR ANOMALÍA',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // FIRMAS
                // ============================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'FIRMAS',

                          style: TextStyle(
                            color: Color(0xFF007A4D),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'ELABORÓ:',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller: elaboroController,

                          decoration:
                              const InputDecoration(
                            hintText: 'Nombre y Firma',

                            prefixIcon: Icon(
                              Icons.person,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Vo. Bo.',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller: voBoController,

                          decoration:
                              const InputDecoration(
                            hintText: 'Nombre y Firma',

                            prefixIcon: Icon(
                              Icons.verified_user,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ============================================================
                // BOTÓN GUARDAR
                // ============================================================

                SizedBox(
                  height: 55,

                  child: ElevatedButton.icon(
                    onPressed: guardarInspeccion,

                    icon: const Icon(
                      Icons.save,
                    ),

                    label: const Text(
                      'GUARDAR INSPECCIÓN',

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF007A4D),

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}