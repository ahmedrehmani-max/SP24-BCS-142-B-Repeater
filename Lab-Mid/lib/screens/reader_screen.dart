import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../app_settings.dart';
import '../db/database_helper.dart';
import '../models/bookmark.dart';
import '../models/pdf_document.dart';

/// Reads a PDF: page navigation, zoom, jump to page, bookmarking and
/// automatic reading-progress tracking.
class ReaderScreen extends StatefulWidget {
  final PdfDocumentItem document;
  final int? initialPage;

  const ReaderScreen({super.key, required this.document, this.initialPage});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _db = DatabaseHelper.instance;
  final controller = PdfViewerController();

  int currentPage = 1;
  int pageCount = 0;
  Set<int> bookmarkedPages = {};

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage ?? widget.document.lastPage;
    pageCount = widget.document.pageCount;
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    final marks = await _db.getBookmarks(documentId: widget.document.id);
    if (!mounted) return;
    setState(() => bookmarkedPages = marks.map((b) => b.pageNumber).toSet());
  }

  Future<void> onPageChanged(int? page) async {
    if (page == null) return;
    setState(() => currentPage = page);
    await _db.saveProgress(widget.document.id!, page, pageCount);
  }

  Future<void> toggleBookmark() async {
    final existing = await _db.findBookmark(widget.document.id!, currentPage);
    if (existing != null) {
      await _db.deleteBookmark(existing.id!);
    } else {
      await _db.addBookmark(Bookmark(
        documentId: widget.document.id!,
        pageNumber: currentPage,
        label: 'Page $currentPage of ${widget.document.title}',
        createdOn: DateTime.now().toIso8601String(),
      ));
    }
    await loadBookmarks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing != null
            ? 'Bookmark removed from page $currentPage'
            : 'Page $currentPage bookmarked'),
      ),
    );
  }

  Future<void> jumpToPage() async {
    final controllerText = TextEditingController(text: '$currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to page'),
        content: TextField(
          controller: controllerText,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page number (1 - $pageCount)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controllerText.text.trim())),
            child: const Text('Go'),
          ),
        ],
      ),
    );

    if (page == null || page < 1 || page > pageCount) return;
    await controller.goToPage(pageNumber: page);
  }

  void goRelative(int delta) {
    final target = currentPage + delta;
    if (target < 1 || target > pageCount) return;
    controller.goToPage(pageNumber: target);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final progress = pageCount == 0 ? 0.0 : currentPage / pageCount;
    final isBookmarked = bookmarkedPages.contains(currentPage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark this page',
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: toggleBookmark,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in),
            onPressed: () => controller.zoomUp(),
          ),
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out),
            onPressed: () => controller.zoomDown(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress, minHeight: 4),
        ),
      ),
      body: PdfViewer.file(
        widget.document.filePath,
        controller: controller,
        initialPageNumber: currentPage,
        params: PdfViewerParams(
          backgroundColor: settings.readingBackground,
          onPageChanged: onPageChanged,
          onViewerReady: (document, _) {
            if (!mounted) return;
            setState(() => pageCount = document.pages.length);
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 1 ? () => goRelative(-1) : null,
            ),
            TextButton(
              onPressed: jumpToPage,
              child: Text('Page $currentPage / $pageCount'),
            ),
            Text('${(progress * 100).round()}% read'),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < pageCount ? () => goRelative(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
