/// A PDF stored in the library.
class PdfDocumentItem {
  final int? id;
  final String title;
  final String filePath;
  final String tags;
  final String description;
  final int pageCount;
  final bool isFavorite;
  final String source; // 'imported' or 'scanned'
  final String addedOn;

  // Filled in from the history table when the library is loaded.
  final int lastPage;
  final double progress; // 0.0 .. 1.0

  const PdfDocumentItem({
    this.id,
    required this.title,
    required this.filePath,
    this.tags = '',
    this.description = '',
    this.pageCount = 0,
    this.isFavorite = false,
    this.source = 'imported',
    required this.addedOn,
    this.lastPage = 1,
    this.progress = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'file_path': filePath,
        'tags': tags,
        'description': description,
        'page_count': pageCount,
        'is_favorite': isFavorite ? 1 : 0,
        'source': source,
        'added_on': addedOn,
      };

  factory PdfDocumentItem.fromMap(Map<String, dynamic> map) => PdfDocumentItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        filePath: map['file_path'] as String,
        tags: (map['tags'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        pageCount: (map['page_count'] as int?) ?? 0,
        isFavorite: ((map['is_favorite'] as int?) ?? 0) == 1,
        source: (map['source'] as String?) ?? 'imported',
        addedOn: map['added_on'] as String,
        lastPage: (map['last_page'] as int?) ?? 1,
        progress: (map['progress'] as num?)?.toDouble() ?? 0,
      );

  PdfDocumentItem copyWith({
    String? title,
    String? tags,
    String? description,
    int? pageCount,
    bool? isFavorite,
    int? lastPage,
    double? progress,
  }) =>
      PdfDocumentItem(
        id: id,
        title: title ?? this.title,
        filePath: filePath,
        tags: tags ?? this.tags,
        description: description ?? this.description,
        pageCount: pageCount ?? this.pageCount,
        isFavorite: isFavorite ?? this.isFavorite,
        source: source,
        addedOn: addedOn,
        lastPage: lastPage ?? this.lastPage,
        progress: progress ?? this.progress,
      );

  List<String> get tagList =>
      tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  int get progressPercent => (progress * 100).round();
}
