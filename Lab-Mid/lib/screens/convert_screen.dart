import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/pdf_document.dart';
import '../services/export_service.dart';
import '../services/pdf_image_service.dart';

/// Converts selected pages (or the whole document) into JPG/PNG files.
class ConvertScreen extends StatefulWidget {
  final PdfDocumentItem document;

  const ConvertScreen({super.key, required this.document});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  late final Set<int> selected = {
    for (var page = 1; page <= widget.document.pageCount; page++) page
  };

  String format = 'png';
  double scale = 2.0;
  bool busy = false;
  int done = 0;
  List<File> results = [];

  Future<void> convert() async {
    if (selected.isEmpty) return;
    setState(() {
      busy = true;
      done = 0;
      results = [];
    });

    final pages = selected.toList()..sort();
    final files = await PdfImageService.instance.convert(
      pdfPath: widget.document.filePath,
      pageNumbers: pages,
      format: format,
      scale: scale,
      onProgress: (completed, _) {
        if (mounted) setState(() => done = completed);
      },
    );

    if (!mounted) return;
    setState(() {
      busy = false;
      results = files;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${files.length} image(s) saved')),
    );
  }

  Future<void> shareAll() async {
    if (results.isEmpty) return;
    final shared = await ExportService.shareFiles(
      results,
      '${widget.document.title} as images',
    );
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is not available here.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.document.pageCount;

    return Scaffold(
      appBar: AppBar(title: const Text('PDF to image')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.document.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text('$total page(s)'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Format'),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'png', label: Text('PNG')),
                  ButtonSegment(value: 'jpg', label: Text('JPG')),
                ],
                selected: {format},
                onSelectionChanged: (value) =>
                    setState(() => format = value.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Resolution  ×${scale.toStringAsFixed(1)}'),
          Slider(
            value: scale,
            min: 1,
            max: 4,
            divisions: 6,
            label: '×${scale.toStringAsFixed(1)}',
            onChanged: (value) => setState(() => scale = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Pages',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  selected
                    ..clear()
                    ..addAll([for (var i = 1; i <= total; i++) i]);
                }),
                child: const Text('All'),
              ),
              TextButton(
                onPressed: () => setState(selected.clear),
                child: const Text('None'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (var page = 1; page <= total; page++)
                FilterChip(
                  label: Text('$page'),
                  selected: selected.contains(page),
                  onSelected: (value) => setState(() {
                    value ? selected.add(page) : selected.remove(page);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : convert,
            icon: const Icon(Icons.image_outlined),
            label: Text('Convert ${selected.length} page(s)'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          if (busy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: selected.isEmpty ? null : done / selected.length,
            ),
            const SizedBox(height: 8),
            Text('Rendering page $done of ${selected.length}...'),
          ],
          if (results.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Result',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: shareAll,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
            Text('Saved in ${p.dirname(results.first.path)}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (final file in results)
                  Image.file(file, fit: BoxFit.cover),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
