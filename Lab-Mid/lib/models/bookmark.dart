/// A bookmarked page inside a document.
class Bookmark {
  final int? id;
  final int documentId;
  final int pageNumber;
  final String label;
  final String createdOn;

  // Joined from the documents table for the favourites screen.
  final String documentTitle;
  final String documentPath;

  const Bookmark({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.label,
    required this.createdOn,
    this.documentTitle = '',
    this.documentPath = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'document_id': documentId,
        'page_number': pageNumber,
        'label': label,
        'created_on': createdOn,
      };

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int?,
        documentId: map['document_id'] as int,
        pageNumber: map['page_number'] as int,
        label: (map['label'] as String?) ?? '',
        createdOn: map['created_on'] as String,
        documentTitle: (map['title'] as String?) ?? '',
        documentPath: (map['file_path'] as String?) ?? '',
      );
}
