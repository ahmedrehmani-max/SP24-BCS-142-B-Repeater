import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Document scanner: capture pages with the camera, crop/enhance them and
/// save the result as a PDF.
class ScannerService {
  ScannerService._();
  static final ScannerService instance = ScannerService._();

  bool get cameraAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Captures one page. Uses the camera on mobile; on desktop, where no
  /// camera plugin is available, an image file can be chosen instead.
  Future<File?> capturePage() async {
    if (cameraAvailable) {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      return shot == null ? null : File(shot.path);
    }

    final picked = await FilePicker.pickFile(
      dialogTitle: 'Select a page image',
      type: FileType.image,
    );
    return picked?.path == null ? null : File(picked!.path!);
  }

  /// Crops [source] to [cropFraction] of its centre and boosts contrast so the
  /// page looks like a scan rather than a photo.
  Future<Uint8List> enhance(
    File source, {
    double cropFraction = 1.0,
    bool grayscale = true,
  }) async {
    final decoded = img.decodeImage(await source.readAsBytes());
    if (decoded == null) return source.readAsBytes();

    var page = decoded;
    if (cropFraction < 1.0) {
      final width = (page.width * cropFraction).round();
      final height = (page.height * cropFraction).round();
      page = img.copyCrop(
        page,
        x: (page.width - width) ~/ 2,
        y: (page.height - height) ~/ 2,
        width: width,
        height: height,
      );
    }

    if (grayscale) page = img.grayscale(page);
    page = img.adjustColor(page, contrast: 1.35, brightness: 1.05);

    return Uint8List.fromList(img.encodeJpg(page, quality: 88));
  }

  /// Builds a PDF where every entry of [pages] becomes one full page.
  Future<File> buildPdf(List<Uint8List> pages, String title) async {
    final document = pw.Document(title: title);

    for (final bytes in pages) {
      final image = pw.MemoryImage(bytes);
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final safeTitle = title.replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '_');
    final file = File(p.join(dir.path, '$safeTitle.pdf'));
    await file.writeAsBytes(await document.save());
    return file;
  }
}
