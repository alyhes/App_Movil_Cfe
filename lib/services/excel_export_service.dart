import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExcelExportService {
  static Future<String> exportarInspeccion(
    int inspeccionId,
  ) async {
    // ==========================================================
    // OBTENER DATOS DE LA BASE DE DATOS
    // ==========================================================

    final datos =
        await DatabaseHelper.instance.obtenerInspeccionCompleta(
      inspeccionId,
    );

    if (datos == null) {
      throw Exception(
        'No se encontró la inspección seleccionada.',
      );
    }

    final inspeccion =
        Map<String, dynamic>.from(datos['inspeccion']);

    final anomalias =
        List<Map<String, dynamic>>.from(
      datos['anomalias'],
    );

    // ==========================================================
    // CREAR ARCHIVO EXCEL
    // ==========================================================

    final excel = Excel.createExcel();

    final sheet = excel['Inspección CFE'];

    // ==========================================================
    // ESTILOS
    // ==========================================================

    final estiloTitulo = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final estiloEncabezado = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final estiloNormal = CellStyle(
      verticalAlign: VerticalAlign.Center,
    );

    // ==========================================================
    // TÍTULO
    // ==========================================================

    sheet
        .cell(CellIndex.indexByString('A1'))
        .value = TextCellValue(
      'COMISIÓN FEDERAL DE ELECTRICIDAD',
    );

    sheet
        .cell(CellIndex.indexByString('A1'))
        .cellStyle = estiloTitulo;

    sheet
        .cell(CellIndex.indexByString('A2'))
        .value = TextCellValue(
      'SISTEMA DE INSPECCIONES CFE',
    );

    sheet
        .cell(CellIndex.indexByString('A2'))
        .cellStyle = estiloTitulo;

    // ==========================================================
    // DATOS GENERALES
    // ==========================================================

    final datosGenerales = <List<String>>[
      [
        'ID de inspección',
        '${inspeccion['id'] ?? ''}',
      ],
      [
        'Fecha de inspección',
        '${inspeccion['fecha_inspeccion'] ?? ''}',
      ],
      [
        'Línea de transmisión',
        '${inspeccion['linea_transmision'] ?? ''}',
      ],
      [
        'Zona de transmisión',
        '${inspeccion['zona_transmision'] ?? ''}',
      ],
      [
        'Tipo de inspección',
        '${inspeccion['tipo_inspeccion'] ?? ''}',
      ],
      [
        'Elaboró',
        '${inspeccion['elaboro'] ?? ''}',
      ],
      [
        'Vo. Bo.',
        '${inspeccion['visto_bueno'] ?? ''}',
      ],
    ];

    int fila = 4;

    for (final dato in datosGenerales) {
      final celdaA =
          sheet.cell(CellIndex.indexByString('A$fila'));

      final celdaB =
          sheet.cell(CellIndex.indexByString('B$fila'));

      celdaA.value = TextCellValue(dato[0]);
      celdaB.value = TextCellValue(dato[1]);

      celdaA.cellStyle = estiloEncabezado;
      celdaB.cellStyle = estiloNormal;

      fila++;
    }

    // ==========================================================
    // ESPACIO
    // ==========================================================

    fila += 1;

    // ==========================================================
    // TÍTULO DE ANOMALÍAS
    // ==========================================================

    sheet
        .cell(CellIndex.indexByString('A$fila'))
        .value = TextCellValue(
      'DETALLE DE TORRES Y ANOMALÍAS',
    );

    sheet
        .cell(CellIndex.indexByString('A$fila'))
        .cellStyle = estiloTitulo;

    fila += 2;

    // ==========================================================
    // ENCABEZADOS DE LA TABLA
    // ==========================================================

    final encabezados = [
      'No.',
      'Fecha de revisión',
      'Torre / Estación',
      'Anomalía',
      'Fecha de corrección',
    ];

    for (int columna = 0;
        columna < encabezados.length;
        columna++) {
      final letra = String.fromCharCode(
        65 + columna,
      );

      final celda = sheet.cell(
        CellIndex.indexByString(
          '$letra$fila',
        ),
      );

      celda.value = TextCellValue(
        encabezados[columna],
      );

      celda.cellStyle = estiloEncabezado;
    }

    fila++;

    // ==========================================================
    // DATOS DE LAS ANOMALÍAS
    // ==========================================================

    if (anomalias.isEmpty) {
      sheet
          .cell(CellIndex.indexByString('A$fila'))
          .value = TextCellValue(
        'No hay anomalías registradas.',
      );
    } else {
      for (int i = 0;
          i < anomalias.length;
          i++) {
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
          final letra = String.fromCharCode(
            65 + columna,
          );

          final celda = sheet.cell(
            CellIndex.indexByString(
              '$letra$fila',
            ),
          );

          celda.value = TextCellValue(
            valores[columna],
          );

          celda.cellStyle = estiloNormal;
        }

        fila++;
      }
    }

    // ==========================================================
    // AJUSTAR ANCHO DE COLUMNAS
    // ==========================================================

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 45);
    sheet.setColumnWidth(4, 22);

    // ==========================================================
    // GENERAR ARCHIVO
    // ==========================================================

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception(
        'No se pudo generar el archivo Excel.',
      );
    }

    // ==========================================================
    // BUSCAR CARPETA DOWNLOADS
    // ==========================================================

    Directory? directorio;

    try {
      directorio = await getDownloadsDirectory();
    } catch (_) {
      directorio = null;
    }

    // Si Downloads no está disponible,
    // utilizamos la carpeta de documentos de la aplicación.
    directorio ??=
        await getApplicationDocumentsDirectory();

    if (!await directorio.exists()) {
      await directorio.create(
        recursive: true,
      );
    }

    // ==========================================================
    // NOMBRE DEL ARCHIVO
    // ==========================================================

    final nombreArchivo =
        'Inspeccion_CFE_${inspeccion['id'] ?? inspeccionId}.xlsx';

    final archivo = File(
      '${directorio.path}/$nombreArchivo',
    );

    await archivo.writeAsBytes(
      bytes,
      flush: true,
    );

    // ==========================================================
    // ABRIR OPCIONES PARA COMPARTIR / GUARDAR
    // ==========================================================

    await SharePlus.instance.share(
      ShareParams(
        title: 'Inspección CFE',
        text:
            'Archivo de inspección CFE en formato Excel.',
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
}