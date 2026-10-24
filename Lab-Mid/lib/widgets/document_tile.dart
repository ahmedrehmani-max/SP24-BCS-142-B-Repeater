import 'package:flutter/material.dart';

import '../models/pdf_document.dart';

/// One row in the library / favourites / recent lists.
class DocumentTile extends StatelessWidget {
  final PdfDocumentItem document;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final void Function(String action) onAction;

  const DocumentTile({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '${document.pageCount} pages',
      if (document.source == 'scanned') 'scanned',
      if (document.tagList.isNotEmpty) document.tagList.join(', '),
    ].join('  •  ');

    return Card(
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F), size: 36),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // Reading progress for this document.
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: document.progress.clamp(0, 1),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${document.progressPercent}%',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Favourite',
              icon: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
                color: document.isFavorite ? Colors.amber[700] : null,
              ),
              onPressed: onToggleFavorite,
            ),
            PopupMenuButton<String>(
              onSelected: onAction,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Rename / edit details')),
                PopupMenuItem(value: 'bookmarks', child: Text('Bookmarked pages')),
                PopupMenuItem(value: 'images', child: Text('Convert to images')),
                PopupMenuItem(value: 'share', child: Text('Share PDF')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}
