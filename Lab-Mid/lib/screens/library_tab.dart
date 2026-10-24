import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../db/database_helper.dart';
import '../models/pdf_document.dart';
import '../services/library_service.dart';
import '../services/notification_service.dart';
import '../widgets/document_tile.dart';
import 'document_actions.dart';

/// All PDFs imported or scanned by the user, with search.
class LibraryTab extends StatefulWidget {
  final VoidCallback onChanged;

  const LibraryTab({super.key, required this.onChanged});

  @override
  State<LibraryTab> createState() => LibraryTabState();
}

class LibraryTabState extends State<LibraryTab> {
  final _db = DatabaseHelper.instance;
  final searchController = TextEditingController();

  List<PdfDocumentItem> documents = [];
  bool loading = true;
  bool importing = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final result = await _db.getDocuments(search: searchController.text.trim());
    if (!mounted) return;
    setState(() {
      documents = result;
      loading = false;
    });
  }

  Future<void> importFiles() async {
    setState(() => importing = true);
    final added = await LibraryService.instance.importPdfs();
    if (!mounted) return;
    setState(() => importing = false);

    if (added.isEmpty) return;
    await NotificationService.instance.showDocumentAdded(
      added.first,
      AppSettings.instance.notificationSound,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${added.length} document(s) added')),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => load(),
              decoration: InputDecoration(
                hintText: 'Search by name, tag or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          load();
                        },
                      ),
              ),
            ),
          ),
          if (importing) const LinearProgressIndicator(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : documents.isEmpty
                    ? const _Empty(
                        icon: Icons.library_books_outlined,
                        title: 'Your library is empty',
                        message: 'Import a PDF or scan a document to start.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: documents.length,
                        itemBuilder: (context, i) {
                          final doc = documents[i];
                          return DocumentTile(
                            document: doc,
                            onOpen: () => DocumentActions.open(
                                context, doc, widget.onChanged),
                            onToggleFavorite: () async {
                              await _db.setFavorite(doc.id!, !doc.isFavorite);
                              widget.onChanged();
                            },
                            onAction: (action) => DocumentActions.handle(
                                context, doc, action, widget.onChanged),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importing ? null : importFiles,
        icon: const Icon(Icons.file_open_outlined),
        label: const Text('Import PDF'),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Reused by the other tabs.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) =>
      _Empty(icon: icon, title: title, message: message);
}
