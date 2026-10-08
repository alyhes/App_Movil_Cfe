import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // ============================================================
  // OBTENER BASE DE DATOS
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('inspecciones_cfe.db');

    return _database!;
  }

  // ============================================================
  // INICIAR BASE DE DATOS
  // ============================================================

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREAR BASE DE DATOS
  // ============================================================

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE inspecciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_inspeccion TEXT NOT NULL,
        linea_transmision TEXT NOT NULL,
        zona_transmision TEXT NOT NULL,
        tipo_inspeccion TEXT NOT NULL,
        elaboro TEXT NOT NULL,
        visto_bueno TEXT,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE anomalias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspeccion_id INTEGER NOT NULL,
        fecha_revision TEXT,
        numero_estacion TEXT,
        anomalia TEXT,
        fecha_correccion TEXT,
        FOREIGN KEY (inspeccion_id)
          REFERENCES inspecciones (id)
          ON DELETE CASCADE
      )
    ''');
  }

  // ============================================================
  // ACTUALIZAR BASE DE DATOS
  // ============================================================

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS anomalias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          inspeccion_id INTEGER NOT NULL,
          fecha_revision TEXT,
          numero_estacion TEXT,
          anomalia TEXT,
          fecha_correccion TEXT,
          FOREIGN KEY (inspeccion_id)
            REFERENCES inspecciones (id)
            ON DELETE CASCADE
        )
      ''');

      final columnas = await db.rawQuery(
        'PRAGMA table_info(inspecciones)',
      );

      final nombresColumnas = columnas
          .map(
            (columna) => columna['name'] as String,
          )
          .toSet();

      if (!nombresColumnas.contains('linea_transmision')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN linea_transmision TEXT NOT NULL DEFAULT ''
        ''');
      }

      if (!nombresColumnas.contains('zona_transmision')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN zona_transmision TEXT NOT NULL DEFAULT ''
        ''');
      }

      if (!nombresColumnas.contains('tipo_inspeccion')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN tipo_inspeccion TEXT NOT NULL DEFAULT ''
        ''');
      }

      if (!nombresColumnas.contains('elaboro')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN elaboro TEXT NOT NULL DEFAULT ''
        ''');
      }

      if (!nombresColumnas.contains('visto_bueno')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN visto_bueno TEXT
        ''');
      }

      if (!nombresColumnas.contains('sincronizado')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0
        ''');
      }
    }
  }

  // ============================================================
  // INSERTAR UNA INSPECCIÓN
  // ============================================================

  Future<int> insertarInspeccion(
    Map<String, dynamic> inspeccion,
  ) async {
    final db = await database;

    return await db.insert(
      'inspecciones',
      inspeccion,
    );
  }

  // ============================================================
  // INSERTAR UNA ANOMALÍA
  // ============================================================

  Future<int> insertarAnomalia(
    Map<String, dynamic> anomalia,
  ) async {
    final db = await database;

    return await db.insert(
      'anomalias',
      anomalia,
    );
  }

  // ============================================================
  // GUARDAR INSPECCIÓN COMPLETA
  // ============================================================

  Future<int> guardarInspeccionCompleta({
    required Map<String, dynamic> inspeccion,
    required List<Map<String, dynamic>> anomalias,
  }) async {
    final db = await database;

    return await db.transaction<int>(
      (txn) async {
        final inspeccionId = await txn.insert(
          'inspecciones',
          inspeccion,
        );

        for (final anomalia in anomalias) {
          final datosAnomalia =
              Map<String, dynamic>.from(anomalia);

          datosAnomalia['inspeccion_id'] =
              inspeccionId;

          await txn.insert(
            'anomalias',
            datosAnomalia,
          );
        }

        return inspeccionId;
      },
    );
  }

  // ============================================================
  // ACTUALIZAR INSPECCIÓN COMPLETA
  //
  // Se utiliza cuando el usuario edita una inspección guardada.
  // Actualiza los datos generales y reemplaza las anomalías.
  // ============================================================

  Future<void> actualizarInspeccionCompleta({
    required int inspeccionId,
    required Map<String, dynamic> inspeccion,
    required List<Map<String, dynamic>> anomalias,
  }) async {
    final db = await database;

    await db.transaction(
      (txn) async {
        // ======================================================
        // ACTUALIZAR INFORMACIÓN GENERAL
        // ======================================================

        await txn.update(
          'inspecciones',
          inspeccion,
          where: 'id = ?',
          whereArgs: [inspeccionId],
        );

        // ======================================================
        // ELIMINAR ANOMALÍAS ANTERIORES
        // ======================================================

        await txn.delete(
          'anomalias',
          where: 'inspeccion_id = ?',
          whereArgs: [inspeccionId],
        );

        // ======================================================
        // GUARDAR LAS NUEVAS ANOMALÍAS
        // ======================================================

        for (final anomalia in anomalias) {
          final datos =
              Map<String, dynamic>.from(anomalia);

          datos.remove('id');

          datos['inspeccion_id'] =
              inspeccionId;

          await txn.insert(
            'anomalias',
            datos,
          );
        }

        // ======================================================
        // AL EDITAR, LA INSPECCIÓN DEBE VOLVER A SINCRONIZARSE
        // ======================================================

        await txn.update(
          'inspecciones',
          {
            'sincronizado': 0,
          },
          where: 'id = ?',
          whereArgs: [inspeccionId],
        );
      },
    );
  }

  // ============================================================
  // OBTENER TODAS LAS INSPECCIONES
  // ============================================================

  Future<List<Map<String, dynamic>>>
      obtenerInspecciones() async {
    final db = await database;

    return await db.query(
      'inspecciones',
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // OBTENER ANOMALÍAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerAnomalias(
    int inspeccionId,
  ) async {
    final db = await database;

    return await db.query(
      'anomalias',
      where: 'inspeccion_id = ?',
      whereArgs: [inspeccionId],
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // OBTENER UNA INSPECCIÓN
  // ============================================================

  Future<Map<String, dynamic>?> obtenerInspeccion(
    int inspeccionId,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'inspecciones',
      where: 'id = ?',
      whereArgs: [inspeccionId],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return resultado.first;
  }

  // ============================================================
  // OBTENER INSPECCIÓN COMPLETA
  // ============================================================

  Future<Map<String, dynamic>?> obtenerInspeccionCompleta(
    int inspeccionId,
  ) async {
    final inspeccion =
        await obtenerInspeccion(inspeccionId);

    if (inspeccion == null) {
      return null;
    }

    final anomalias =
        await obtenerAnomalias(inspeccionId);

    return {
      'inspeccion': inspeccion,
      'anomalias': anomalias,
    };
  }

  // ============================================================
  // OBTENER DATOS PARA EXCEL
  // ============================================================

  Future<Map<String, dynamic>?> obtenerDatosParaExcel(
    int inspeccionId,
  ) async {
    final datos =
        await obtenerInspeccionCompleta(
      inspeccionId,
    );

    if (datos == null) {
      return null;
    }

    final inspeccion =
        Map<String, dynamic>.from(
      datos['inspeccion'],
    );

    final anomalias =
        List<Map<String, dynamic>>.from(
      datos['anomalias'],
    );

    return {
      'id': inspeccion['id'],
      'fecha_inspeccion':
          inspeccion['fecha_inspeccion'],
      'linea_transmision':
          inspeccion['linea_transmision'],
      'zona_transmision':
          inspeccion['zona_transmision'],
      'tipo_inspeccion':
          inspeccion['tipo_inspeccion'],
      'elaboro':
          inspeccion['elaboro'],
      'visto_bueno':
          inspeccion['visto_bueno'],
      'anomalias': anomalias,
    };
  }

  // ============================================================
  // ACTUALIZAR ANOMALÍA
  // ============================================================

  Future<int> actualizarAnomalia(
    int anomaliaId,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;

    final resultado = await db.update(
      'anomalias',
      datos,
      where: 'id = ?',
      whereArgs: [anomaliaId],
    );

    // ==========================================================
    // BUSCAR LA INSPECCIÓN DE LA ANOMALÍA
    // Y MARCARLA COMO PENDIENTE DE SINCRONIZACIÓN
    // ==========================================================

    final anomalia = await db.query(
      'anomalias',
      columns: ['inspeccion_id'],
      where: 'id = ?',
      whereArgs: [anomaliaId],
      limit: 1,
    );

    if (anomalia.isNotEmpty) {
      await db.update(
        'inspecciones',
        {
          'sincronizado': 0,
        },
        where: 'id = ?',
        whereArgs: [
          anomalia.first['inspeccion_id'],
        ],
      );
    }

    return resultado;
  }

  // ============================================================
  // ACTUALIZAR FECHA DE CORRECCIÓN
  // ============================================================

  Future<int> actualizarFechaCorreccion(
    int anomaliaId,
    String fechaCorreccion,
  ) async {
    final db = await database;

    final resultado = await db.update(
      'anomalias',
      {
        'fecha_correccion': fechaCorreccion,
      },
      where: 'id = ?',
      whereArgs: [anomaliaId],
    );

    // ==========================================================
    // LA INSPECCIÓN VUELVE A QUEDAR PENDIENTE
    // DE SINCRONIZACIÓN
    // ==========================================================

    final anomalia = await db.query(
      'anomalias',
      columns: ['inspeccion_id'],
      where: 'id = ?',
      whereArgs: [anomaliaId],
      limit: 1,
    );

    if (anomalia.isNotEmpty) {
      await db.update(
        'inspecciones',
        {
          'sincronizado': 0,
        },
        where: 'id = ?',
        whereArgs: [
          anomalia.first['inspeccion_id'],
        ],
      );
    }

    return resultado;
  }

  // ============================================================
  // OBTENER INSPECCIONES PENDIENTES DE SINCRONIZAR
  // ============================================================

  Future<List<Map<String, dynamic>>>
      obtenerInspeccionesPendientes() async {
    final db = await database;

    return await db.query(
      'inspecciones',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // MARCAR INSPECCIÓN COMO SINCRONIZADA
  // ============================================================

  Future<int> marcarInspeccionSincronizada(
    int inspeccionId,
  ) async {
    final db = await database;

    return await db.update(
      'inspecciones',
      {
        'sincronizado': 1,
      },
      where: 'id = ?',
      whereArgs: [inspeccionId],
    );
  }

  // ============================================================
  // ELIMINAR UNA INSPECCIÓN
  // ============================================================

  Future<int> eliminarInspeccion(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'inspecciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CERRAR BASE DE DATOS
  // ============================================================

  Future<void> cerrarBaseDeDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}