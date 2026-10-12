import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';
import '../models/patient.dart';
import '../models/patient_file.dart';
import 'patient_form_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final db = DatabaseHelper.instance;

  late Patient patient;
  List<PatientFile> files = [];

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
    loadFiles();
  }

  Future<void> loadFiles() async {
    final result = await db.getFiles(patient.id!);
    if (!mounted) return;
    setState(() => files = result);
  }

  Future<void> editPatient() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PatientFormScreen(patient: patient)),
    );
    if (saved != true) return;
    final updated = await db.getPatient(patient.id!);
    if (!mounted || updated == null) return;
    setState(() => patient = updated);
  }

  /// Picks a document/image and copies it into the app directory so the
  /// record keeps working even if the original file is moved.
  Future<void> addFile() async {
    final result = await FilePicker.pickFile(
      dialogTitle: 'Select a report or image',
      type: FileType.any,
    );
    final picked = result?.path;
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final patientDir = Directory(p.join(appDir.path, 'patient_${patient.id}'));
    await patientDir.create(recursive: true);

    final fileName = p.basename(picked);
    final storedPath = p.join(
      patientDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    await File(picked).copy(storedPath);

    const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];
    final isImage = imageExtensions.contains(p.extension(picked).toLowerCase());

    await db.insertFile(
      PatientFile(
        patientId: patient.id!,
        fileName: fileName,
        filePath: storedPath,
        fileType: isImage ? 'image' : 'document',
        addedOn: DateTime.now().toIso8601String().split('T').first,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$fileName attached')));
    loadFiles();
  }

  Future<void> deleteFile(PatientFile file) async {
    await db.deleteFile(file.id!);
    final stored = File(file.filePath);
    if (await stored.exists()) await stored.delete();
    loadFiles();
  }

  void previewFile(PatientFile file) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(file.fileName),
        content: file.isImage && File(file.filePath).existsSync()
            ? Image.file(File(file.filePath))
            : Text('Stored at:\n${file.filePath}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: editPatient,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF00897B),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    patient.name.isEmpty ? '?' : patient.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${patient.age} years  •  ${patient.gender}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: patient.phone,
          ),
          _InfoTile(
            icon: Icons.healing_outlined,
            label: 'Diagnosis',
            value: patient.diagnosis,
          ),
          _InfoTile(
            icon: Icons.event_outlined,
            label: 'Last visit',
            value: patient.lastVisit,
          ),
          _InfoTile(
            icon: Icons.notes_outlined,
            label: 'Prescription / notes',
            value: patient.notes.isEmpty ? '-' : patient.notes,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents & Images (${files.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: addFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ),
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No reports or images attached yet.'),
            )
          else
            ...files.map(
              (file) => Card(
                child: ListTile(
                  leading: file.isImage && File(file.filePath).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(file.filePath),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.description_outlined, size: 36),
                  title: Text(file.fileName),
                  subtitle: Text('${file.fileType}  •  added ${file.addedOn}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => deleteFile(file),
                  ),
                  onTap: () => previewFile(file),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00897B)),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}
