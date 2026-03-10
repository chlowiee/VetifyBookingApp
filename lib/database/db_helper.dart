import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {

  static Database? _database;

  static Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {

    String path = join(await getDatabasesPath(), 'veterinaria.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
        CREATE TABLE usuarios(
          id TEXT PRIMARY KEY,
          nombre TEXT,
          email TEXT,
          rol TEXT,
          foto TEXT
        )
        ''');

        await db.execute('''
        CREATE TABLE mascotas(
          id TEXT PRIMARY KEY,
          nombre TEXT,
          especie TEXT,
          raza TEXT,
          edad TEXT,
          peso TEXT,
          sexo TEXT,
          color TEXT,
          usuarioId TEXT
        )
        ''');

        await db.execute('''
        CREATE TABLE citas(
          id TEXT PRIMARY KEY,
          clienteId TEXT,
          mascotaId TEXT,
          fecha TEXT,
          veterinario TEXT,
          servicio TEXT,
          estado TEXT
        )
        ''');

      },
    );
  }
}