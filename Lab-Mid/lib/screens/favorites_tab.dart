import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/bookmark.dart';
import '../models/pdf_document.dart';
import '../widgets/document_tile.dart';
import 'document_actions.dart';
import 'library_tab.dart';

/// Favourite documents plus every bookmarked page.
class FavoritesTab extends StatefulWidget {
  final VoidCallback onChanged;

  const FavoritesTab({super.key, required this.onChanged});

  @override
  State<FavoritesTab> createState() => FavoritesTabState();
}

class FavoritesTabState extends State<FavoritesTab> {
  final _db = DatabaseHelper.instance;

  List<PdfDocumentItem> favorites = [];
  List<Bookmark> bookmarks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final docs = await _db.getDocuments(favoritesOnly: true);
    final marks = await _db.getBookmarks();
    if (!mounted) return;
    setState(() {
      favorites = docs;
      bookmarks = marks;
      loading = false;
    });
  }

  Future<void> openBookmark(Bookmark bookmark) async {
    final documents = await _db.getDocuments();
    final document = documents.where((d) => d.id == bookmark.documentId);
    if (document.isEmpty || !mounted) return;
    await DocumentActions.open(
      context,
      document.first,
      widget.onChanged,
      page: bookmark.pageNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (favorites.isEmpty && bookmarks.isEmpty) {
      return const EmptyState(
        icon: Icons.star_border,
        title: 'Nothing marked yet',
        message: 'Star a document or bookmark a page while reading.',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (favorites.isNotEmpty) ...[
          const _SectionHeader('Favourite documents'),
          for (final doc in favorites)
            DocumentTile(
              document: doc,
              onOpen: () => DocumentActions.open(context, doc, widget.onChanged),
              onToggleFavorite: () async {
                await _db.setFavorite(doc.id!, false);
                widget.onChanged();
              },
              onAction: (action) => DocumentActions.handle(
                  context, doc, action, widget.onChanged),
            ),
        ],
        if (bookmarks.isNotEmpty) ...[
          const _SectionHeader('Bookmarked pages'),
          for (final bookmark in bookmarks)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark, color: Color(0xFFD32F2F)),
                title: Text('${bookmark.documentTitle} — page ${bookmark.pageNumber}'),
                subtitle: bookmark.label.isEmpty ? null : Text(bookmark.label),
                trailing: IconButton(
                  tooltip: 'Remove bookmark',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await _db.deleteBookmark(bookmark.id!);
                    widget.onChanged();
                  },
                ),
                onTap: () => openBookmark(bookmark),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
}
