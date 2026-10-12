class PatientFile {
  final int? id;
  final int patientId;
  final String fileName;
  final String filePath;
  final String fileType; // 'image' or 'document'
  final String addedOn;

  PatientFile({
    this.id,
    required this.patientId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.addedOn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'added_on': addedOn,
    };
  }

  factory PatientFile.fromMap(Map<String, dynamic> map) {
    return PatientFile(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      addedOn: map['added_on'] as String,
    );
  }

  bool get isImage => fileType == 'image';
}
