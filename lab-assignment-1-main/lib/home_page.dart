import 'dart:io';

import 'package:flutter/material.dart';

import 'db_helper.dart';
import 'person.dart';
import 'person_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Person> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final people = await DbHelper.instance.getAll();
    if (!mounted) return;
    setState(() {
      _people = people;
      _loading = false;
    });
  }

  void _toast(String message, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(message),
        ]),
      ));
  }

  /// Opens the form sheet for a new record (CREATE) or an existing one (UPDATE).
  Future<void> _openForm([Person? existing]) async {
    final result = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PersonForm(person: existing),
    );
    if (result == null) return;

    if (existing == null) {
      await DbHelper.instance.insert(result);
      _toast('${result.name} added', Icons.check_circle_outline);
    } else {
      await DbHelper.instance.update(result.copyWith(id: existing.id));
      _toast('${result.name} updated', Icons.sync_alt);
    }
    await _refresh();
  }

  Future<void> _confirmDelete(Person person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, size: 32),
        title: const Text('Delete record?'),
        content: Text('“${person.name}” will be removed from the database permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DbHelper.instance.delete(person);
    _toast('${person.name} deleted', Icons.delete_outline);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 18),
              title: Text(
                'Contacts',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: const _HeaderBackdrop(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: Icon(Icons.storage_rounded, size: 18, color: scheme.onPrimaryContainer),
                  label: Text('${_people.length}'),
                  backgroundColor: scheme.surface.withValues(alpha: 0.7),
                  side: BorderSide.none,
                ),
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_people.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverList.separated(
                itemCount: _people.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PersonCard(
                  person: _people[i],
                  onEdit: () => _openForm(_people[i]),
                  onDelete: () => _confirmDelete(_people[i]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
    );
  }
}

class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.onEdit, required this.onDelete});

  final Person person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Avatar(person: person, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    person.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${person.age} yrs',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              color: scheme.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round picture for a record, falling back to the person's initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.person, required this.radius});

  final Person person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = person.imagePath;
    final hasImage = path != null && File(path).existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage
          ? null
          : Text(
              person.initials,
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 88, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No records yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Tap “Add” to store your first contact.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
