import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/patient.dart';

/// Used for both "Add patient" and "Edit patient".
class PatientFormScreen extends StatefulWidget {
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final formKey = GlobalKey<FormState>();
  final db = DatabaseHelper.instance;

  late final TextEditingController nameController;
  late final TextEditingController ageController;
  late final TextEditingController phoneController;
  late final TextEditingController diagnosisController;
  late final TextEditingController notesController;

  late String gender;
  late DateTime lastVisit;

  bool get isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    nameController = TextEditingController(text: p?.name ?? '');
    ageController = TextEditingController(text: p?.age.toString() ?? '');
    phoneController = TextEditingController(text: p?.phone ?? '');
    diagnosisController = TextEditingController(text: p?.diagnosis ?? '');
    notesController = TextEditingController(text: p?.notes ?? '');
    gender = p?.gender ?? 'Male';
    lastVisit = DateTime.tryParse(p?.lastVisit ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    diagnosisController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: lastVisit,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => lastVisit = picked);
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final patient = Patient(
      id: widget.patient?.id,
      name: nameController.text.trim(),
      age: int.parse(ageController.text.trim()),
      gender: gender,
      phone: phoneController.text.trim(),
      diagnosis: diagnosisController.text.trim(),
      notes: notesController.text.trim(),
      lastVisit: lastVisit.toIso8601String().split('T').first,
    );

    if (isEditing) {
      await db.updatePatient(patient);
    } else {
      await db.insertPatient(patient);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Patient' : 'Add Patient')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: (value) {
                final age = int.tryParse(value?.trim() ?? '');
                if (age == null || age <= 0 || age > 120) return 'Enter a valid age';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => gender = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Phone is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis',
                prefixIcon: Icon(Icons.healing_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Diagnosis is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prescription / notes',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Last visit'),
                subtitle: Text(lastVisit.toIso8601String().split('T').first),
                trailing: TextButton(
                  onPressed: pickDate,
                  child: const Text('Change'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Update Patient' : 'Save Patient'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
