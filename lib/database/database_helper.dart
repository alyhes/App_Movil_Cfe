import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('inspecciones_cfe.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

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
  }

  Future<int> insertarInspeccion(
    Map<String, dynamic> inspeccion,
  ) async {
    final db = await database;

    return await db.insert(
      'inspecciones',
      inspeccion,
    );
  }

  Future<int> insertarAnomalia(
    Map<String, dynamic> anomalia,
  ) async {
    final db = await database;

    return await db.insert(
      'anomalias',
      anomalia,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerInspecciones() async {
    final db = await database;

    return await db.query(
      'inspecciones',
      orderBy: 'id DESC',
    );
  }

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

  Future<void> cerrarBaseDeDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
