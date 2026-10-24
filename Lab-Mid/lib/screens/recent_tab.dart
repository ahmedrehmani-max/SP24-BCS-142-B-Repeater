import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/pdf_document.dart';
import 'document_actions.dart';
import 'library_tab.dart';

/// Reading history: recently opened documents and the page to resume from.
class RecentTab extends StatefulWidget {
  final VoidCallback onChanged;

  const RecentTab({super.key, required this.onChanged});

  @override
  State<RecentTab> createState() => RecentTabState();
}

class RecentTabState extends State<RecentTab> {
  final _db = DatabaseHelper.instance;

  List<PdfDocumentItem> recent = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await _db.getRecent();
    if (!mounted) return;
    setState(() {
      recent = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (recent.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No reading history',
        message: 'Documents you open appear here with your last page.',
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: () async {
                await _db.clearHistory();
                widget.onChanged();
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear history'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: recent.length,
            itemBuilder: (context, i) {
              final doc = recent[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      color: Color(0xFFD32F2F), size: 36),
                  title: Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last read page ${doc.lastPage} of ${doc.pageCount}'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: doc.progress.clamp(0, 1),
                        minHeight: 5,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: FilledButton.tonal(
                    onPressed: () => DocumentActions.open(
                      context,
                      doc,
                      widget.onChanged,
                      page: doc.lastPage,
                    ),
                    child: const Text('Resume'),
                  ),
                  onTap: () => DocumentActions.open(
                    context,
                    doc,
                    widget.onChanged,
                    page: doc.lastPage,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
