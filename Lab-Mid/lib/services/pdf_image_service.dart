import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Converts PDF pages into JPG/PNG image files.
class PdfImageService {
  PdfImageService._();
  static final PdfImageService instance = PdfImageService._();

  /// Renders [pageNumbers] (1-based) of [pdfPath] and writes them as image
  /// files. [scale] controls the output resolution. Returns the written files.
  Future<List<File>> convert({
    required String pdfPath,
    required List<int> pageNumbers,
    String format = 'png',
    double scale = 2.0,
    void Function(int done, int total)? onProgress,
  }) async {
    final document = await PdfDocument.openFile(pdfPath);
    final outputDir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'converted'),
    );
    await outputDir.create(recursive: true);

    final baseName = p.basenameWithoutExtension(pdfPath);
    final written = <File>[];

    try {
      for (var i = 0; i < pageNumbers.length; i++) {
        final page = document.pages[pageNumbers[i] - 1];
        final rendered = await page.render(
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
        );
        if (rendered == null) continue;

        // pdfrx hands back raw BGRA pixels; the image package encodes them.
        final bitmap = img.Image.fromBytes(
          width: rendered.width,
          height: rendered.height,
          bytes: rendered.pixels.buffer,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        );
        rendered.dispose();

        final bytes = format == 'jpg'
            ? img.encodeJpg(bitmap, quality: 90)
            : img.encodePng(bitmap);

        final file = File(p.join(
          outputDir.path,
          '${baseName}_page_${pageNumbers[i]}.$format',
        ));
        await file.writeAsBytes(Uint8List.fromList(bytes));
        written.add(file);
        onProgress?.call(i + 1, pageNumbers.length);
      }
    } finally {
      await document.dispose();
    }

    return written;
  }
}
