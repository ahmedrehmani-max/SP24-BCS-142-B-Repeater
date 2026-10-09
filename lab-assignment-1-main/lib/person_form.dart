import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'home_page.dart' show Avatar;
import 'person.dart';

/// Bottom-sheet form used for both adding a new record and editing an existing
/// one. Returns the filled-in [Person] via `Navigator.pop`, or null on cancel.
class PersonForm extends StatefulWidget {
  const PersonForm({super.key, this.person});

  final Person? person;

  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.person?.name ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.person?.email ?? '');
  late final TextEditingController _age =
      TextEditingController(text: widget.person?.age.toString() ?? '');

  String? _imagePath;

  bool get _isEdit => widget.person != null;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.person?.imagePath;
    _name.addListener(() => setState(() {})); // keeps the avatar initials in sync
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (picked == null) return;
    // Copy into app storage: the picker's cache path is not durable.
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'img_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}');
    await File(picked.path).copy(dest);
    if (!mounted) return;
    setState(() => _imagePath = dest);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Person(
        id: widget.person?.id,
        name: _name.text.trim(),
        email: _email.text.trim(),
        age: int.parse(_age.text.trim()),
        imagePath: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = Person(
      name: _name.text.isEmpty ? '?' : _name.text,
      email: '',
      age: 0,
      imagePath: _imagePath,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Edit record' : 'Add new record',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Avatar(person: preview, radius: 44),
                  Material(
                    color: scheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickImage,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(Icons.photo_camera_outlined,
                            size: 18, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton(onPressed: _pickImage, child: const Text('Choose image')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                validator: (v) {
                  final age = int.tryParse(v?.trim() ?? '');
                  if (age == null) return 'Age is required';
                  if (age < 1 || age > 120) return 'Age must be between 1 and 120';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(_isEdit ? Icons.save_outlined : Icons.add),
                      label: Text(_isEdit ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
