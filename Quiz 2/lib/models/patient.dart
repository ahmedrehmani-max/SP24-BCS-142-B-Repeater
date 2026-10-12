class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String diagnosis;
  final String notes;
  final String lastVisit;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.diagnosis,
    required this.notes,
    required this.lastVisit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'diagnosis': diagnosis,
      'notes': notes,
      'last_visit': lastVisit,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      phone: map['phone'] as String,
      diagnosis: map['diagnosis'] as String,
      notes: map['notes'] as String,
      lastVisit: map['last_visit'] as String,
    );
  }

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? diagnosis,
    String? notes,
    String? lastVisit,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}
