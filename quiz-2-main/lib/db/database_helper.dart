import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/patient.dart';
import '../models/patient_file.dart';

/// Single SQLite database used by the whole app.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'doctor_app.db');
    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            phone TEXT NOT NULL,
            diagnosis TEXT NOT NULL,
            notes TEXT NOT NULL,
            last_visit TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE patient_files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_id INTEGER NOT NULL,
            file_name TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_type TEXT NOT NULL,
            added_on TEXT NOT NULL,
            FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // ---------------- Patients (CRUD) ----------------

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return db.insert('patients', patient.toMap()..remove('id'));
  }

  Future<List<Patient>> getPatients({String search = ''}) async {
    final db = await database;
    final rows = await db.query(
      'patients',
      where: search.isEmpty ? null : 'name LIKE ? OR diagnosis LIKE ?',
      whereArgs: search.isEmpty ? null : ['%$search%', '%$search%'],
      orderBy: 'id DESC',
    );
    return rows.map(Patient.fromMap).toList();
  }

  Future<Patient?> getPatient(int id) async {
    final db = await database;
    final rows = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Patient.fromMap(rows.first);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Patient files ----------------

  Future<int> insertFile(PatientFile file) async {
    final db = await database;
    return db.insert('patient_files', file.toMap()..remove('id'));
  }

  Future<List<PatientFile>> getFiles(int patientId) async {
    final db = await database;
    final rows = await db.query(
      'patient_files',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'id DESC',
    );
    return rows.map(PatientFile.fromMap).toList();
  }

  Future<int> deleteFile(int id) async {
    final db = await database;
    return db.delete('patient_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countFiles(int patientId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patient_files WHERE patient_id = ?',
      [patientId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
