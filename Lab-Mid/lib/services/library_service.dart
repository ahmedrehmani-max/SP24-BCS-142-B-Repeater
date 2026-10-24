import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../db/database_helper.dart';
import '../models/pdf_document.dart';

/// Imports PDFs into the library and keeps the files inside the app folder so
/// they stay available after the original is moved or deleted.
class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  final _db = DatabaseHelper.instance;

  Future<Directory> documentsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'pdfs'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Lets the user choose PDFs and copies them into the library.
  /// Returns the titles that were added.
  Future<List<String>> importPdfs() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Select PDF files',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    final added = <String>[];
    for (final file in picked) {
      final path = file.path;
      if (path == null) continue;
      final doc = await addFile(File(path), source: 'imported');
      if (doc != null) added.add(doc.title);
    }
    return added;
  }

  /// Copies [file] into the library folder and records it in the database.
  Future<PdfDocumentItem?> addFile(File file, {String source = 'imported'}) async {
    if (!await file.exists()) return null;

    final dir = await documentsDirectory();
    final name = p.basename(file.path);
    final stored = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_$name');
    await file.copy(stored);

    final doc = PdfDocumentItem(
      title: p.basenameWithoutExtension(name),
      filePath: stored,
      pageCount: await _pageCount(stored),
      source: source,
      addedOn: DateTime.now().toIso8601String(),
    );
    await _db.insertDocument(doc);
    return _db.getDocumentByPath(stored);
  }

  Future<int> _pageCount(String path) async {
    try {
      final document = await PdfDocument.openFile(path);
      final count = document.pages.length;
      await document.dispose();
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Removes the database row and the stored file.
  Future<void> delete(PdfDocumentItem doc) async {
    await _db.deleteDocument(doc.id!);
    final file = File(doc.filePath);
    if (await file.exists()) await file.delete();
  }
}
