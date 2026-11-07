
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
      version: 4,
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inspecciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_inspeccion TEXT NOT NULL,
        linea_transmision TEXT NOT NULL,
        zona_transmision TEXT NOT NULL,
        tipo_inspeccion TEXT NOT NULL,
        tipo_torre TEXT,
        tipo_cimentacion TEXT,
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

    await _crearTablaUsuarios(db);
  }

  // ============================================================
  // CREAR TABLA DE USUARIOS
  // ============================================================

  Future<void> _crearTablaUsuarios(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL COLLATE NOCASE UNIQUE,
        nombre TEXT NOT NULL,
        rpe TEXT,
        contrasena_hash TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'usuario'
          CHECK (rol IN ('administrador', 'usuario')),
        activo INTEGER NOT NULL DEFAULT 1,
        debe_cambiar_contrasena INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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
          .map((columna) => columna['name'] as String)
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

    if (oldVersion < 3) {
      await _crearTablaUsuarios(db);
    }

    if (oldVersion < 4) {
      final columnas = await db.rawQuery(
        'PRAGMA table_info(inspecciones)',
      );

      final nombresColumnas = columnas
          .map((columna) => columna['name'] as String)
          .toSet();

      if (!nombresColumnas.contains('tipo_torre')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN tipo_torre TEXT
        ''');
      }

      if (!nombresColumnas.contains('tipo_cimentacion')) {
        await db.execute('''
          ALTER TABLE inspecciones
          ADD COLUMN tipo_cimentacion TEXT
        ''');
      }
    }
  }

  // ============================================================
  // USUARIOS: CREAR
  // ============================================================

  Future<int> crearUsuario(Map<String, dynamic> datos) async {
    final db = await database;

    final usuario = Map<String, dynamic>.from(datos);

    usuario['usuario'] =
        (usuario['usuario'] as String).trim();

    usuario['nombre'] =
        (usuario['nombre'] as String).trim();

    return await db.insert(
      'usuarios',
      usuario,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // USUARIOS: BUSCAR POR NOMBRE
  // ============================================================

  Future<Map<String, dynamic>?> obtenerUsuarioPorNombre(
    String usuario,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario.trim()],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return resultado.first;
  }

  // ============================================================
  // USUARIOS: CONSULTAR SIN EXPONER HASHES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final db = await database;

    return await db.query(
      'usuarios',
      columns: [
        'id',
        'usuario',
        'nombre',
        'rpe',
        'rol',
        'activo',
        'debe_cambiar_contrasena',
        'fecha_creacion',
      ],
      orderBy: 'nombre COLLATE NOCASE ASC',
    );
  }

  // ============================================================
  // USUARIOS: ACTUALIZAR DATOS
  // ============================================================

  Future<int> actualizarUsuario(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final db = await database;

    final cambios = Map<String, dynamic>.from(datos);

    cambios.remove('id');
    cambios.remove('contrasena_hash');
    cambios.remove('fecha_creacion');

    if (cambios.containsKey('usuario')) {
      cambios['usuario'] =
          (cambios['usuario'] as String).trim();
    }

    if (cambios.containsKey('nombre')) {
      cambios['nombre'] =
          (cambios['nombre'] as String).trim();
    }

    return await db.update(
      'usuarios',
      cambios,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // USUARIOS: CAMBIAR CONTRASEÑA
  // ============================================================

  Future<int> cambiarContrasenaUsuario(
    int id,
    String contrasenaHash, {
    bool exigirCambio = false,
  }) async {
    final db = await database;

    return await db.update(
      'usuarios',
      {
        'contrasena_hash': contrasenaHash,
        'debe_cambiar_contrasena':
            exigirCambio ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // USUARIOS: ACTIVAR O DESACTIVAR
  // ============================================================

  Future<int> cambiarEstadoUsuario(
    int id,
    bool activo,
  ) async {
    final db = await database;

    return await db.update(
      'usuarios',
      {'activo': activo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // USUARIOS: ELIMINAR
  // ============================================================

  Future<int> eliminarUsuario(int id) async {
    final db = await database;

    return await db.delete(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // COMPROBAR ADMINISTRADOR ACTIVO
  // ============================================================

  Future<bool> existeAdministrador() async {
    final db = await database;

    final resultado = await db.query(
      'usuarios',
      columns: ['id'],
      where: 'rol = ? AND activo = ?',
      whereArgs: ['administrador', 1],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }

  // ============================================================
  // COMPROBAR SI EXISTEN USUARIOS
  // ============================================================

  Future<bool> existenUsuarios() async {
    final db = await database;

    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM usuarios',
    );

    final total = resultado.first['total'] as int;

    return total > 0;
  }

  // ============================================================
  // INSPECCIONES: INSERTAR
  // ============================================================

  Future<int> insertarInspeccion(
    Map<String, dynamic> inspeccion,
  ) async {
    final db = await database;

    return await db.insert('inspecciones', inspeccion);
  }

  // ============================================================
  // ANOMALÍAS: INSERTAR UNA
  // ============================================================

  Future<int> insertarAnomalia(
    Map<String, dynamic> anomalia,
  ) async {
    final db = await database;

    final id = await db.insert('anomalias', anomalia);

    final inspeccionId = anomalia['inspeccion_id'];

    if (inspeccionId != null) {
      await db.update(
        'inspecciones',
        {'sincronizado': 0},
        where: 'id = ?',
        whereArgs: [inspeccionId],
      );
    }

    return id;
  }

  // ============================================================
  // GUARDAR INSPECCIÓN COMPLETA CON VARIAS ANOMALÍAS
  // ============================================================

  Future<int> guardarInspeccionCompleta({
    required Map<String, dynamic> inspeccion,
    required List<Map<String, dynamic>> anomalias,
  }) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final inspeccionId = await txn.insert(
        'inspecciones',
        inspeccion,
      );

      for (final anomalia in anomalias) {
        final datosAnomalia =
            Map<String, dynamic>.from(anomalia);

        datosAnomalia.remove('id');
        datosAnomalia['inspeccion_id'] = inspeccionId;

        await txn.insert('anomalias', datosAnomalia);
      }

      return inspeccionId;
    });
  }

  // ============================================================
  // ACTUALIZAR INSPECCIÓN COMPLETA
  // ============================================================

  Future<void> actualizarInspeccionCompleta({
    required int inspeccionId,
    required Map<String, dynamic> inspeccion,
    required List<Map<String, dynamic>> anomalias,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final datosInspeccion =
          Map<String, dynamic>.from(inspeccion);

      datosInspeccion.remove('id');
      datosInspeccion['sincronizado'] = 0;

      await txn.update(
        'inspecciones',
        datosInspeccion,
        where: 'id = ?',
        whereArgs: [inspeccionId],
      );

      await txn.delete(
        'anomalias',
        where: 'inspeccion_id = ?',
        whereArgs: [inspeccionId],
      );

      for (final anomalia in anomalias) {
        final datos = Map<String, dynamic>.from(anomalia);

        datos.remove('id');
        datos['inspeccion_id'] = inspeccionId;

        await txn.insert('anomalias', datos);
      }
    });
  }

  // ============================================================
  // OBTENER TODAS LAS INSPECCIONES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerInspecciones() async {
    final db = await database;

    return await db.query(
      'inspecciones',
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // OBTENER ANOMALÍAS DE UNA INSPECCIÓN
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
    final inspeccion = await obtenerInspeccion(inspeccionId);

    if (inspeccion == null) {
      return null;
    }

    final anomalias = await obtenerAnomalias(inspeccionId);

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
    final datos = await obtenerInspeccionCompleta(inspeccionId);

    if (datos == null) {
      return null;
    }

    final inspeccion =
        Map<String, dynamic>.from(datos['inspeccion']);

    final anomalias =
        List<Map<String, dynamic>>.from(datos['anomalias']);

    return {
      'id': inspeccion['id'],
      'fecha_inspeccion': inspeccion['fecha_inspeccion'],
      'linea_transmision': inspeccion['linea_transmision'],
      'zona_transmision': inspeccion['zona_transmision'],
      'tipo_inspeccion': inspeccion['tipo_inspeccion'],
      'tipo_torre': inspeccion['tipo_torre'],
      'tipo_cimentacion': inspeccion['tipo_cimentacion'],
      'elaboro': inspeccion['elaboro'],
      'visto_bueno': inspeccion['visto_bueno'],
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

    final cambios = Map<String, dynamic>.from(datos);
    cambios.remove('id');
    cambios.remove('inspeccion_id');

    return await db.transaction<int>((txn) async {
      final resultado = await txn.update(
        'anomalias',
        cambios,
        where: 'id = ?',
        whereArgs: [anomaliaId],
      );

      final anomalia = await txn.query(
        'anomalias',
        columns: ['inspeccion_id'],
        where: 'id = ?',
        whereArgs: [anomaliaId],
        limit: 1,
      );

      if (anomalia.isNotEmpty) {
        await txn.update(
          'inspecciones',
          {'sincronizado': 0},
          where: 'id = ?',
          whereArgs: [anomalia.first['inspeccion_id']],
        );
      }

      return resultado;
    });
  }

  // ============================================================
  // ACTUALIZAR FECHA / ESTATUS DE CORRECCIÓN
  // ============================================================

  Future<int> actualizarFechaCorreccion(
    int anomaliaId,
    String fechaCorreccion,
  ) async {
    return await actualizarAnomalia(
      anomaliaId,
      {'fecha_correccion': fechaCorreccion},
    );
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
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [inspeccionId],
    );
  }

  // ============================================================
  // ELIMINAR UNA INSPECCIÓN
  // ============================================================

  Future<int> eliminarInspeccion(int id) async {
    final db = await database;

    return await db.delete(
      'inspecciones',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // ASIGNAR ROL DE ADMINISTRADOR A LA CUENTA EXISTENTE
  // ============================================================

  Future<int> asignarRolAdministradorCfe() async {
    final db = await database;

    return await db.update(
      'usuarios',
      {
        'rol': 'administrador',
        'activo': 1,
      },
      where: 'usuario = ?',
      whereArgs: ['ADMIN_CFE'],
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
