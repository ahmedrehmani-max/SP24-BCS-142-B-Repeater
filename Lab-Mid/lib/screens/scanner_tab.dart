import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../services/library_service.dart';
import '../services/notification_service.dart';
import '../services/scanner_service.dart';

/// Scans pages with the camera, enhances them and saves them as one PDF.
class ScannerTab extends StatefulWidget {
  final VoidCallback onSaved;

  const ScannerTab({super.key, required this.onSaved});

  @override
  State<ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<ScannerTab> {
  final scanner = ScannerService.instance;

  final pages = <Uint8List>[];
  final titleController = TextEditingController(text: 'Scanned document');

  double cropFraction = 1.0;
  bool grayscale = true;
  bool busy = false;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> addPage() async {
    final source = await scanner.capturePage();
    if (source == null) return;

    setState(() => busy = true);
    final enhanced = await scanner.enhance(
      source,
      cropFraction: cropFraction,
      grayscale: grayscale,
    );
    if (!mounted) return;
    setState(() {
      pages.add(enhanced);
      busy = false;
    });
  }

  Future<void> saveAsPdf() async {
    if (pages.isEmpty) return;
    setState(() => busy = true);

    final title = titleController.text.trim().isEmpty
        ? 'Scanned document'
        : titleController.text.trim();
    final pdf = await scanner.buildPdf(pages, title);
    final added = await LibraryService.instance.addFile(pdf, source: 'scanned');

    if (added != null) {
      await NotificationService.instance.showDocumentAdded(
        added.title,
        AppSettings.instance.notificationSound,
      );
    }

    if (!mounted) return;
    setState(() {
      pages.clear();
      busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" saved to your library')),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            scanner.cameraAvailable
                ? 'Capture pages with the camera, then save them as a PDF.'
                : 'No camera on this platform — choose page images instead, '
                    'then save them as a PDF.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Document name'),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Crop',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: cropFraction,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    label: '${(cropFraction * 100).round()}%',
                    onChanged: (value) => setState(() => cropFraction = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enhance as black & white scan'),
                    value: grayscale,
                    onChanged: (value) => setState(() => grayscale = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : addPage,
                  icon: Icon(scanner.cameraAvailable
                      ? Icons.photo_camera_outlined
                      : Icons.image_outlined),
                  label: Text(scanner.cameraAvailable ? 'Scan page' : 'Add image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy || pages.isEmpty ? null : saveAsPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Save as PDF'),
                ),
              ),
            ],
          ),
          if (busy) const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: 20),
          Text('Captured pages (${pages.length})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (pages.isEmpty)
            const Text('Nothing captured yet.')
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (var i = 0; i < pages.length; i++)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(pages[i], fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: 'Remove page',
                          icon: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                          onPressed: () => setState(() => pages.removeAt(i)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
