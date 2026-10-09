import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'person.dart';

/// Thin wrapper around the local SQLite database.
///
/// The database file lives in the application documents directory, so records
/// survive app restarts.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _table = 'persons';
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return openDatabase(
      p.join(dir.path, 'persons.db'),
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          age INTEGER NOT NULL,
          image_path TEXT
        )
      '''),
    );
  }

  Future<List<Person>> getAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map(Person.fromMap).toList();
  }

  Future<int> insert(Person person) async {
    final db = await database;
    return db.insert(_table, person.toMap());
  }

  Future<int> update(Person person) async {
    final db = await database;
    return db.update(_table, person.toMap(), where: 'id = ?', whereArgs: [person.id]);
  }

  Future<int> delete(Person person) async {
    final db = await database;
    // Drop the stored copy of the picture too, otherwise it leaks on disk.
    final path = person.imagePath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    return db.delete(_table, where: 'id = ?', whereArgs: [person.id]);
  }
}
