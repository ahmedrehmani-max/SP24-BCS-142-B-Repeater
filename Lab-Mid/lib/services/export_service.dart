import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/database_helper.dart';

/// Exports the library, reading history and bookmarks to CSV / PDF, and
/// hands the file to the share sheet or the mail client.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final _db = DatabaseHelper.instance;

  static String _csvCell(Object? value) {
    final text = '${value ?? ''}'.replaceAll('"', '""');
    return '"$text"';
  }

  Future<List<List<Object?>>> _rows() async {
    final documents = await _db.getDocuments();
    final bookmarks = await _db.getBookmarks();

    final rows = <List<Object?>>[
      ['Title', 'Tags', 'Description', 'Pages', 'Favorite', 'Source',
       'Added on', 'Last page', 'Progress %', 'Bookmarked pages'],
    ];

    for (final doc in documents) {
      final pages = bookmarks
          .where((b) => b.documentId == doc.id)
          .map((b) => b.pageNumber)
          .join(' ');
      rows.add([
        doc.title,
        doc.tags,
        doc.description,
        doc.pageCount,
        doc.isFavorite ? 'Yes' : 'No',
        doc.source,
        doc.addedOn.split('T').first,
        doc.lastPage,
        doc.progressPercent,
        pages,
      ]);
    }
    return rows;
  }

  Future<File> _writeToExports(String fileName, List<int> bytes) async {
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'exports'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> exportCsv() async {
    final rows = await _rows();
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return _writeToExports('library_$stamp.csv', csv.codeUnits);
  }

  Future<File> exportPdf() async {
    final rows = await _rows();
    final document = pw.Document(title: 'PDF Library Report');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: 'PDF Library Report'),
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: rows.first.map((c) => '$c').toList(),
            data: rows.skip(1).map((r) => r.map((c) => '$c').toList()).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return _writeToExports('library_$stamp.pdf', await document.save());
  }

  /// Opens the share sheet so files can be sent anywhere, email included.
  ///
  /// Not every platform has a share sheet (desktop Linux, for example), so a
  /// failure here must not take down the action that produced the files.
  /// Returns false when nothing could be shared.
  static Future<bool> shareFiles(List<File> files, String subject) async {
    if (files.isEmpty) return false;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: files.map((f) => XFile(f.path)).toList(),
          subject: subject,
        ),
      );
      return true;
    } catch (error) {
      debugPrint('Sharing unavailable: $error');
      return false;
    }
  }

  Future<bool> share(File file, String subject) => shareFiles([file], subject);

  /// Opens the mail client with a ready-made summary of the library.
  Future<bool> emailSummary() async {
    final documents = await _db.getDocuments();
    final body = StringBuffer('My PDF library (${documents.length} documents)\n\n');
    for (final doc in documents) {
      body.writeln(
        '- ${doc.title} | ${doc.pageCount} pages | '
        '${doc.progressPercent}% read${doc.isFavorite ? ' | favourite' : ''}',
      );
    }

    final uri = Uri(
      scheme: 'mailto',
      query: Uri.encodeFull(
        'subject=PDF Library Export&body=${body.toString()}',
      ).replaceAll('#', '%23'),
    );
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri);
    } catch (error) {
      debugPrint('Mail client unavailable: $error');
      return false;
    }
  }
}
