/// A single contact record stored in the SQLite `persons` table.
class Person {
  final int? id;
  final String name;
  final String email;
  final int age;
  final String? imagePath;

  const Person({
    this.id,
    required this.name,
    required this.email,
    required this.age,
    this.imagePath,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'age': age,
        'image_path': imagePath,
      };

  factory Person.fromMap(Map<String, Object?> map) => Person(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        age: map['age'] as int,
        imagePath: map['image_path'] as String?,
      );

  Person copyWith({int? id, String? name, String? email, int? age, String? imagePath}) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        age: age ?? this.age,
        imagePath: imagePath ?? this.imagePath,
      );

  /// Initials shown when the record has no picture.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
