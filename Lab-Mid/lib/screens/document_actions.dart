import 'dart:io';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/pdf_document.dart';
import '../services/export_service.dart';
import '../services/library_service.dart';
import 'convert_screen.dart';
import 'reader_screen.dart';

/// Actions shared by the library, favourites and recent lists so each list
/// does not have to repeat them.
class DocumentActions {
  static final _db = DatabaseHelper.instance;

  static Future<void> open(
    BuildContext context,
    PdfDocumentItem document,
    VoidCallback onChanged, {
    int? page,
  }) async {
    if (!await File(document.filePath).exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The PDF file is missing from storage.')),
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(document: document, initialPage: page),
      ),
    );
    onChanged();
  }

  static Future<void> handle(
    BuildContext context,
    PdfDocumentItem document,
    String action,
    VoidCallback onChanged,
  ) async {
    switch (action) {
      case 'edit':
        await editDetails(context, document, onChanged);
      case 'bookmarks':
        await showBookmarks(context, document, onChanged);
      case 'images':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConvertScreen(document: document)),
        );
      case 'share':
        final shared = await ExportService.shareFiles(
          [File(document.filePath)],
          document.title,
        );
        if (!shared && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sharing is not available here.')),
          );
        }
      case 'delete':
        await confirmDelete(context, document, onChanged);
    }
  }

  /// Rename the document and edit its tags / description.
  static Future<void> editDetails(
    BuildContext context,
    PdfDocumentItem document,
    VoidCallback onChanged,
  ) async {
    final title = TextEditingController(text: document.title);
    final tags = TextEditingController(text: document.tags);
    final description = TextEditingController(text: document.description);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma separated, e.g. notes, semester 5',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    await _db.updateDocument(document.copyWith(
      title: title.text.trim().isEmpty ? document.title : title.text.trim(),
      tags: tags.text.trim(),
      description: description.text.trim(),
    ));
    onChanged();
  }

  static Future<void> showBookmarks(
    BuildContext context,
    PdfDocumentItem document,
    VoidCallback onChanged,
  ) async {
    final bookmarks = await _db.getBookmarks(documentId: document.id);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: bookmarks.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No bookmarks in this document yet.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final bookmark in bookmarks)
                    ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text('Page ${bookmark.pageNumber}'),
                      subtitle:
                          bookmark.label.isEmpty ? null : Text(bookmark.label),
                      onTap: () {
                        Navigator.pop(ctx);
                        open(context, document, onChanged,
                            page: bookmark.pageNumber);
                      },
                    ),
                ],
              ),
      ),
    );
  }

  static Future<void> confirmDelete(
    BuildContext context,
    PdfDocumentItem document,
    VoidCallback onChanged,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document'),
        content: Text(
          'Remove "${document.title}" from the library? '
          'Its bookmarks and reading history are removed too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true) return;
    await LibraryService.instance.delete(document);
    onChanged();
  }
}
