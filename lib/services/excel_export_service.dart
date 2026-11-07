
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class ExcelExportService {
  static const String _nombreInstitucion =
      'COMISIÓN FEDERAL DE ELECTRICIDAD';

  static const String _nombreSistema =
      'SISTEMA DE INSPECCIONES CFE';

  static final CellStyle _estiloTitulo = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('FF007A4D'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _estiloSubtitulo = CellStyle(
    bold: true,
    fontSize: 12,
    fontColorHex: ExcelColor.fromHexString('FF007A4D'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _estiloEncabezado = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
    backgroundColorHex: ExcelColor.fromHexString('FF007A4D'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _estiloNormal = CellStyle(
    fontSize: 10,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _estiloEtiqueta = CellStyle(
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('FF007A4D'),
    backgroundColorHex: ExcelColor.fromHexString('FFE8F5E9'),
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _estiloUrgente = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('FFFF0000'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _estiloProgramado = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('FFFF8C00'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _estiloHecho = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.fromHexString('FF008000'),
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  // ============================================================
  // EXPORTAR UNA INSPECCIÓN
  // ============================================================

  static Future<String> exportarInspeccion(
    int inspeccionId,
  ) async {
    final datos = await DatabaseHelper.instance
        .obtenerInspeccionCompleta(inspeccionId);

    if (datos == null) {
      throw Exception(
        'No se encontró la inspección seleccionada.',
      );
    }

    final inspeccion =
        Map<String, dynamic>.from(datos['inspeccion']);

    final anomalias =
        List<Map<String, dynamic>>.from(datos['anomalias']);

    final excel = Excel.createExcel();
    final sheet = excel['Inspección CFE'];

    _crearHojaInspeccion(
      sheet,
      inspeccion,
      anomalias,
    );

    return _guardarYCompartir(
      excel,
      'Inspeccion_CFE_${inspeccion['id'] ?? inspeccionId}.xlsx',
      'Inspección CFE',
    );
  }

  // ============================================================
  // EXPORTAR INSPECCIONES DE UN DÍA
  // ============================================================

  static Future<String> exportarInspeccionesPorDia(
    DateTime fecha,
  ) async {
    final todas =
        await DatabaseHelper.instance.obtenerInspecciones();

    final inspeccionesDelDia = todas.where((inspeccion) {
      final fechaInspeccion = _convertirFecha(
        inspeccion['fecha_inspeccion']?.toString(),
      );

      return fechaInspeccion != null &&
          fechaInspeccion.year == fecha.year &&
          fechaInspeccion.month == fecha.month &&
          fechaInspeccion.day == fecha.day;
    }).toList();

    if (inspeccionesDelDia.isEmpty) {
      throw Exception(
        'No hay inspecciones registradas para el día ${_formatearFecha(fecha)}.',
      );
    }

    final excel = Excel.createExcel();
    final sheet = excel['Inspecciones del día'];

    await _crearHojaVariasInspecciones(
      sheet,
      inspeccionesDelDia,
      'INSPECCIONES DEL DÍA ${_formatearFecha(fecha)}',
    );

    return _guardarYCompartir(
      excel,
      'Inspecciones_CFE_${_nombreFechaArchivo(fecha)}.xlsx',
      'Inspecciones CFE del día',
    );
  }

  // ============================================================
  // EXPORTAR INSPECCIONES DE UN MES
  // UN SOLO ARCHIVO CON UNA HOJA POR CADA DÍA
  // ============================================================

  static Future<String> exportarInspeccionesPorMes(
    int anio,
    int mes,
  ) async {
    if (mes < 1 || mes > 12) {
      throw Exception('El mes seleccionado no es válido.');
    }

    final todas =
        await DatabaseHelper.instance.obtenerInspecciones();

    // Filtrar todas las inspecciones del mes seleccionado.
    final inspeccionesDelMes = todas.where((inspeccion) {
      final fecha = _convertirFecha(
        inspeccion['fecha_inspeccion']?.toString(),
      );

      return fecha != null &&
          fecha.year == anio &&
          fecha.month == mes;
    }).toList();

    if (inspeccionesDelMes.isEmpty) {
      throw Exception(
        'No hay inspecciones registradas para ${_nombreMes(mes)} de $anio.',
      );
    }

    // Ordenar las inspecciones por fecha.
    inspeccionesDelMes.sort((a, b) {
      final fechaA = _convertirFecha(
        a['fecha_inspeccion']?.toString(),
      );

      final fechaB = _convertirFecha(
        b['fecha_inspeccion']?.toString(),
      );

      return fechaA!.compareTo(fechaB!);
    });

    // Agrupar todas las inspecciones por día.
    final Map<int, List<Map<String, dynamic>>> porDia = {};

    for (final inspeccion in inspeccionesDelMes) {
      final fecha = _convertirFecha(
        inspeccion['fecha_inspeccion']?.toString(),
      );

      if (fecha == null) continue;

      porDia.putIfAbsent(fecha.day, () => []);
      porDia[fecha.day]!.add(inspeccion);
    }

    final excel = Excel.createExcel();

    final diasOrdenados = porDia.keys.toList()..sort();

    // Crear una hoja independiente por cada día con registros.
    for (final dia in diasOrdenados) {
      final fecha = DateTime(anio, mes, dia);

      final nombreHoja =
          '${dia.toString().padLeft(2, '0')}-'
          '${mes.toString().padLeft(2, '0')}';

      // Crear directamente la hoja con su nombre.
      final sheet = excel[nombreHoja];

      // Escribir todas las inspecciones de ese día.
      await _crearHojaVariasInspecciones(
        sheet,
        porDia[dia]!,
        'INSPECCIONES DEL ${_formatearFecha(fecha)}',
      );
    }

    // Eliminar la hoja predeterminada vacía.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return _guardarYCompartir(
      excel,
      'Inspecciones_CFE_${_nombreMes(mes)}_$anio.xlsx',
      'Inspecciones CFE del mes',
    );
  }

  // ============================================================
  // CREAR HOJA PARA UNA INSPECCIÓN
  // ============================================================

  static void _crearHojaInspeccion(
    Sheet sheet,
    Map<String, dynamic> inspeccion,
    List<Map<String, dynamic>> anomalias,
  ) {
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('E1'),
    );

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('E2'),
    );

    _ponerTexto(
      sheet,
      'A1',
      _nombreInstitucion,
      _estiloTitulo,
    );

    _ponerTexto(
      sheet,
      'A2',
      _nombreSistema,
      _estiloSubtitulo,
    );

    int fila = 4;

    fila = _escribirDatosGenerales(
      sheet,
      inspeccion,
      fila,
    );

    fila += 1;

    sheet.merge(
      CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: fila - 1,
      ),
      CellIndex.indexByColumnRow(
        columnIndex: 4,
        rowIndex: fila - 1,
      ),
    );

    _ponerTexto(
      sheet,
      'A$fila',
      'DETALLE DE TORRES Y ANOMALÍAS',
      _estiloSubtitulo,
    );

    fila += 2;

    _escribirTablaAnomalias(
      sheet,
      anomalias,
      fila,
    );

    _ajustarColumnas(sheet);
  }

  // ============================================================
  // CREAR HOJA CON VARIAS INSPECCIONES
  // ============================================================

  static Future<void> _crearHojaVariasInspecciones(
    Sheet sheet,
    List<Map<String, dynamic>> inspecciones,
    String titulo,
  ) async {
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('N1'),
    );

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('N2'),
    );

    _ponerTexto(
      sheet,
      'A1',
      _nombreInstitucion,
      _estiloTitulo,
    );

    _ponerTexto(
      sheet,
      'A2',
      titulo,
      _estiloSubtitulo,
    );

    final encabezados = [
      'No.',
      'ID',
      'Fecha de inspección',
      'Línea de transmisión',
      'Zona',
      'Tipo de inspección',
      'Tipo de torre',
      'Tipo de cimentación',
      'Elaboró',
      'Vo. Bo.',
      'Fecha de revisión',
      'Torre / Estación',
      'Anomalía',
      'Estatus de corrección',
    ];

    int fila = 4;

    for (int columna = 0;
        columna < encabezados.length;
        columna++) {
      final celda = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columna,
          rowIndex: fila - 1,
        ),
      );

      celda.value = TextCellValue(encabezados[columna]);
      celda.cellStyle = _estiloEncabezado;
    }

    fila++;

    int consecutivo = 1;

    for (final inspeccion in inspecciones) {
      final id = inspeccion['id'] as int;

      final datos = await DatabaseHelper.instance
          .obtenerInspeccionCompleta(id);

      if (datos == null) continue;

      final anomalias =
          List<Map<String, dynamic>>.from(datos['anomalias']);

      if (anomalias.isEmpty) {
        final valores = [
          '$consecutivo',
          '$id',
          '${inspeccion['fecha_inspeccion'] ?? ''}',
          '${inspeccion['linea_transmision'] ?? ''}',
          '${inspeccion['zona_transmision'] ?? ''}',
          '${inspeccion['tipo_inspeccion'] ?? ''}',
          '${inspeccion['tipo_torre'] ?? ''}',
          '${inspeccion['tipo_cimentacion'] ?? ''}',
          '${inspeccion['elaboro'] ?? ''}',
          '${inspeccion['visto_bueno'] ?? ''}',
          '',
          '',
          'Sin anomalías registradas',
          '',
        ];

        _escribirFila(
          sheet,
          fila,
          valores,
          encabezados.length,
        );

        fila++;
        consecutivo++;
        continue;
      }

      for (final anomalia in anomalias) {
        final valores = [
          '$consecutivo',
          '$id',
          '${inspeccion['fecha_inspeccion'] ?? ''}',
          '${inspeccion['linea_transmision'] ?? ''}',
          '${inspeccion['zona_transmision'] ?? ''}',
          '${inspeccion['tipo_inspeccion'] ?? ''}',
          '${inspeccion['tipo_torre'] ?? ''}',
          '${inspeccion['tipo_cimentacion'] ?? ''}',
          '${inspeccion['elaboro'] ?? ''}',
          '${inspeccion['visto_bueno'] ?? ''}',
          '${anomalia['fecha_revision'] ?? ''}',
          '${anomalia['numero_estacion'] ?? ''}',
          '${anomalia['anomalia'] ?? ''}',
          '${anomalia['fecha_correccion'] ?? ''}',
        ];

        _escribirFila(
          sheet,
          fila,
          valores,
          encabezados.length,
          estado: '${anomalia['fecha_correccion'] ?? ''}',
        );

        fila++;
        consecutivo++;
      }
    }

    _ajustarColumnasVarias(sheet);
  }

  // ============================================================
  // ESCRIBIR DATOS GENERALES
  // ============================================================

  static int _escribirDatosGenerales(
    Sheet sheet,
    Map<String, dynamic> inspeccion,
    int fila,
  ) {
    final datos = <List<String>>[
      ['ID de inspección', '${inspeccion['id'] ?? ''}'],
      ['Fecha de inspección', '${inspeccion['fecha_inspeccion'] ?? ''}'],
      ['Línea de transmisión', '${inspeccion['linea_transmision'] ?? ''}'],
      ['Zona de transmisión', '${inspeccion['zona_transmision'] ?? ''}'],
      ['Tipo de inspección', '${inspeccion['tipo_inspeccion'] ?? ''}'],
      ['Tipo de torre', '${inspeccion['tipo_torre'] ?? 'No especificado'}'],
      ['Tipo de cimentación', '${inspeccion['tipo_cimentacion'] ?? 'No especificado'}'],
      ['Elaboró', '${inspeccion['elaboro'] ?? ''}'],
      ['Vo. Bo.', '${inspeccion['visto_bueno'] ?? ''}'],
    ];

    for (final dato in datos) {
      final celdaA = sheet.cell(
        CellIndex.indexByString('A$fila'),
      );

      final celdaB = sheet.cell(
        CellIndex.indexByString('B$fila'),
      );

      celdaA.value = TextCellValue(dato[0]);
      celdaB.value = TextCellValue(dato[1]);

      celdaA.cellStyle = _estiloEtiqueta;
      celdaB.cellStyle = _estiloNormal;

      fila++;
    }

    return fila;
  }

  // ============================================================
  // ESCRIBIR TABLA DE ANOMALÍAS
  // ============================================================

  static int _escribirTablaAnomalias(
    Sheet sheet,
    List<Map<String, dynamic>> anomalias,
    int fila,
  ) {
    final encabezados = [
      'No.',
      'Fecha de revisión',
      'Torre / Estación',
      'Anomalía',
      'Estatus de corrección',
    ];

    for (int columna = 0;
        columna < encabezados.length;
        columna++) {
      final celda = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columna,
          rowIndex: fila - 1,
        ),
      );

      celda.value = TextCellValue(encabezados[columna]);
      celda.cellStyle = _estiloEncabezado;
    }

    fila++;

    if (anomalias.isEmpty) {
      _ponerTexto(
        sheet,
        'A$fila',
        'No hay anomalías registradas.',
        _estiloNormal,
      );

      return fila + 1;
    }

    for (int i = 0; i < anomalias.length; i++) {
      final anomalia = anomalias[i];

      final valores = [
        '${i + 1}',
        '${anomalia['fecha_revision'] ?? ''}',
        '${anomalia['numero_estacion'] ?? ''}',
        '${anomalia['anomalia'] ?? ''}',
        '${anomalia['fecha_correccion'] ?? ''}',
      ];

      for (int columna = 0;
          columna < valores.length;
          columna++) {
        final celda = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: columna,
            rowIndex: fila - 1,
          ),
        );

        celda.value = TextCellValue(valores[columna]);
        celda.cellStyle = _estiloNormal;

        if (columna == 4) {
          celda.cellStyle = _estiloEstado(valores[4]);
        }
      }

      fila++;
    }

    return fila;
  }

  // ============================================================
  // ESCRIBIR UNA FILA
  // ============================================================

  static void _escribirFila(
    Sheet sheet,
    int fila,
    List<String> valores,
    int cantidadColumnas, {
    String estado = '',
  }) {
    for (int columna = 0;
        columna < cantidadColumnas;
        columna++) {
      final celda = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columna,
          rowIndex: fila - 1,
        ),
      );

      celda.value = TextCellValue(valores[columna]);
      celda.cellStyle = _estiloNormal;

      if (columna == 13) {
        celda.cellStyle = _estiloEstado(estado);
      }
    }
  }

  // ============================================================
  // ESTILO SEGÚN ESTATUS
  // ============================================================

  static CellStyle _estiloEstado(String estado) {
    final texto = estado.trim().toUpperCase();

    if (texto == 'URGENTE') {
      return _estiloUrgente;
    }

    if (texto == 'HECHO') {
      return _estiloHecho;
    }

    if (texto.startsWith('PROG')) {
      return _estiloProgramado;
    }

    return _estiloNormal;
  }

  // ============================================================
  // COLOCAR TEXTO EN UNA CELDA
  // ============================================================

  static void _ponerTexto(
    Sheet sheet,
    String referencia,
    String texto,
    CellStyle estilo,
  ) {
    final celda = sheet.cell(
      CellIndex.indexByString(referencia),
    );

    celda.value = TextCellValue(texto);
    celda.cellStyle = estilo;
  }

  // ============================================================
  // AJUSTAR COLUMNAS DE INSPECCIÓN INDIVIDUAL
  // ============================================================

  static void _ajustarColumnas(Sheet sheet) {
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 45);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 55);
    sheet.setColumnWidth(4, 25);
  }

  // ============================================================
  // AJUSTAR COLUMNAS DE EXPORTACIÓN DIARIA Y MENSUAL
  // ============================================================

  static void _ajustarColumnasVarias(Sheet sheet) {
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 10);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 25);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 22);
    sheet.setColumnWidth(6, 20);
    sheet.setColumnWidth(7, 22);
    sheet.setColumnWidth(8, 25);
    sheet.setColumnWidth(9, 22);
    sheet.setColumnWidth(10, 20);
    sheet.setColumnWidth(11, 20);
    sheet.setColumnWidth(12, 45);
    sheet.setColumnWidth(13, 23);
  }

  // ============================================================
  // GUARDAR Y COMPARTIR ARCHIVO
  // ============================================================

  static Future<String> _guardarYCompartir(
    Excel excel,
    String nombreArchivo,
    String tituloCompartir,
  ) async {
    final bytes = excel.save();

    if (bytes == null) {
      throw Exception(
        'No se pudo generar el archivo Excel.',
      );
    }

    Directory? directorio;

    try {
      directorio = await getDownloadsDirectory();
    } catch (_) {
      directorio = null;
    }

    directorio ??=
        await getApplicationDocumentsDirectory();

    if (!await directorio.exists()) {
      await directorio.create(recursive: true);
    }

    final archivo = File(
      '${directorio.path}/$nombreArchivo',
    );

    await archivo.writeAsBytes(
      bytes,
      flush: true,
    );

    await SharePlus.instance.share(
      ShareParams(
        title: tituloCompartir,
        text: 'Archivo generado por el Sistema de Inspecciones CFE.',
        files: [
          XFile(
            archivo.path,
            name: nombreArchivo,
          ),
        ],
        fileNameOverrides: [
          nombreArchivo,
        ],
      ),
    );

    return archivo.path;
  }

  // ============================================================
  // CONVERTIR FECHA
  // ACEPTA dd/MM/yyyy Y yyyy-MM-dd
  // ============================================================

  static DateTime? _convertirFecha(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return null;
    }

    final valor = texto.trim();

    try {
      if (valor.contains('/')) {
        final partes = valor.split('/');

        if (partes.length == 3) {
          return DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );
        }
      }

      if (valor.contains('-')) {
        final partes = valor.split('-');

        if (partes.length >= 3) {
          return DateTime(
            int.parse(partes[0]),
            int.parse(partes[1]),
            int.parse(partes[2].substring(0, 2)),
          );
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // ============================================================
  // FORMATO DE FECHA
  // ============================================================

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  static String _nombreFechaArchivo(DateTime fecha) {
    return '${fecha.year}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
  }

  static String _nombreMes(int mes) {
    const meses = [
      '',
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

    if (mes < 1 || mes > 12) {
      return 'Mes';
    }

    return meses[mes];
  }
}
