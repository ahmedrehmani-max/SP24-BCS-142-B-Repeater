// Tests for the SQLite layer that backs the library, bookmarks and history.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pdf_reader_utility/db/database_helper.dart';
import 'package:pdf_reader_utility/models/bookmark.dart';
import 'package:pdf_reader_utility/models/pdf_document.dart';

void main() {
  final db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // The test database file survives between runs, so start from empty.
    final database = await db.database;
    await database.delete('documents');
    await database.delete('settings');
  });

  Future<PdfDocumentItem> addDocument(String title, {int pages = 10}) async {
    await db.insertDocument(PdfDocumentItem(
      title: title,
      filePath: '/tmp/$title-${DateTime.now().microsecondsSinceEpoch}.pdf',
      tags: 'semester 5, notes',
      pageCount: pages,
      addedOn: DateTime.now().toIso8601String(),
    ));
    final all = await db.getDocuments(search: title);
    return all.first;
  }

  test('documents can be added, renamed, searched and deleted', () async {
    final doc = await addDocument('Operating Systems');

    expect(doc.title, 'Operating Systems');
    expect((await db.getDocuments(search: 'Operating')).length, 1);
    expect((await db.getDocuments(search: 'semester 5')).isNotEmpty, true);

    await db.updateDocument(doc.copyWith(title: 'OS Handbook'));
    final renamed = await db.getDocumentByPath(doc.filePath);
    expect(renamed!.title, 'OS Handbook');

    await db.deleteDocument(doc.id!);
    expect(await db.getDocumentByPath(doc.filePath), isNull);
  });

  test('reading progress is stored and reported as a percentage', () async {
    final doc = await addDocument('Computer Networks', pages: 200);

    await db.saveProgress(doc.id!, 50, doc.pageCount);
    final recent = await db.getRecent();
    final tracked = recent.firstWhere((d) => d.id == doc.id);

    expect(tracked.lastPage, 50);
    expect(tracked.progressPercent, 25);

    await db.deleteDocument(doc.id!);
  });

  test('bookmarks are removed together with their document', () async {
    final doc = await addDocument('Database Systems');

    await db.addBookmark(Bookmark(
      documentId: doc.id!,
      pageNumber: 7,
      label: 'Normalisation',
      createdOn: DateTime.now().toIso8601String(),
    ));
    expect((await db.getBookmarks(documentId: doc.id)).single.pageNumber, 7);
    expect(await db.findBookmark(doc.id!, 7), isNotNull);

    await db.deleteDocument(doc.id!);
    expect((await db.getBookmarks(documentId: doc.id)), isEmpty);
  });

  test('favourites and settings round-trip through the database', () async {
    final doc = await addDocument('Software Engineering');

    await db.setFavorite(doc.id!, true);
    expect((await db.getDocuments(favoritesOnly: true)).map((d) => d.id),
        contains(doc.id));

    await db.setSetting('theme_mode', 'dark');
    expect((await db.getSettings())['theme_mode'], 'dark');

    await db.deleteDocument(doc.id!);
  });
}
