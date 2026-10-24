import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bookmark.dart';
import '../models/pdf_document.dart';

/// Single SQLite database holding documents, bookmarks, reading history and
/// user preferences.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'pdf_reader.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            file_path TEXT NOT NULL UNIQUE,
            tags TEXT NOT NULL DEFAULT '',
            description TEXT NOT NULL DEFAULT '',
            page_count INTEGER NOT NULL DEFAULT 0,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            source TEXT NOT NULL DEFAULT 'imported',
            added_on TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER NOT NULL,
            page_number INTEGER NOT NULL,
            label TEXT NOT NULL DEFAULT '',
            created_on TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            document_id INTEGER PRIMARY KEY,
            last_page INTEGER NOT NULL DEFAULT 1,
            progress REAL NOT NULL DEFAULT 0,
            opened_at TEXT NOT NULL,
            FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ------------------------------------------------------------- documents

  /// Documents with their reading progress attached.
  /// [search] matches the title, tags or description.
  Future<List<PdfDocumentItem>> getDocuments({
    String search = '',
    bool favoritesOnly = false,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (search.isNotEmpty) {
      where.add('(d.title LIKE ? OR d.tags LIKE ? OR d.description LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }
    if (favoritesOnly) where.add('d.is_favorite = 1');

    final rows = await db.rawQuery('''
      SELECT d.*, h.last_page, h.progress
      FROM documents d LEFT JOIN history h ON h.document_id = d.id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY d.id DESC
    ''', args);
    return rows.map(PdfDocumentItem.fromMap).toList();
  }

  /// Recently opened documents, most recent first.
  Future<List<PdfDocumentItem>> getRecent({int limit = 50}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT d.*, h.last_page, h.progress
      FROM history h JOIN documents d ON d.id = h.document_id
      ORDER BY h.opened_at DESC LIMIT ?
    ''', [limit]);
    return rows.map(PdfDocumentItem.fromMap).toList();
  }

  Future<int> insertDocument(PdfDocumentItem doc) async {
    final db = await database;
    return db.insert('documents', doc.toMap()..remove('id'));
  }

  Future<PdfDocumentItem?> getDocumentByPath(String path) async {
    final db = await database;
    final rows =
        await db.query('documents', where: 'file_path = ?', whereArgs: [path]);
    return rows.isEmpty ? null : PdfDocumentItem.fromMap(rows.first);
  }

  /// Renaming / editing metadata.
  Future<int> updateDocument(PdfDocumentItem doc) async {
    final db = await database;
    return db.update('documents', doc.toMap(),
        where: 'id = ?', whereArgs: [doc.id]);
  }

  Future<int> setFavorite(int id, bool value) async {
    final db = await database;
    return db.update('documents', {'is_favorite': value ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDocument(int id) async {
    final db = await database;
    return db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------------------------------------- bookmarks

  Future<int> addBookmark(Bookmark bookmark) async {
    final db = await database;
    return db.insert('bookmarks', bookmark.toMap()..remove('id'));
  }

  Future<List<Bookmark>> getBookmarks({int? documentId}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, d.title, d.file_path
      FROM bookmarks b JOIN documents d ON d.id = b.document_id
      ${documentId == null ? '' : 'WHERE b.document_id = ?'}
      ORDER BY b.document_id, b.page_number
    ''', documentId == null ? null : [documentId]);
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<Bookmark?> findBookmark(int documentId, int pageNumber) async {
    final db = await database;
    final rows = await db.query('bookmarks',
        where: 'document_id = ? AND page_number = ?',
        whereArgs: [documentId, pageNumber]);
    return rows.isEmpty ? null : Bookmark.fromMap(rows.first);
  }

  Future<int> deleteBookmark(int id) async {
    final db = await database;
    return db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------- history

  /// Stores the last read page so the document can be resumed later.
  Future<void> saveProgress(int documentId, int lastPage, int pageCount) async {
    final db = await database;
    await db.insert(
      'history',
      {
        'document_id': documentId,
        'last_page': lastPage,
        'progress': pageCount == 0 ? 0.0 : lastPage / pageCount,
        'opened_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // -------------------------------------------------------------- settings

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
