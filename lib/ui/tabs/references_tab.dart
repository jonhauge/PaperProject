import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/paper.dart';
import '../../models/reference.dart';
import '../../state/app_state.dart';
import '../widgets.dart';

/// Bibliography manager. References are cited from markdown using their
/// [Reference.citationKey], e.g. `[@smith2021]`.
class ReferencesTab extends StatelessWidget {
  const ReferencesTab({required this.paper, super.key});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Stack(
      children: [
        if (paper.references.isEmpty)
          const EmptyState(
            icon: Icons.menu_book_outlined,
            message: 'No references yet.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: paper.references.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = paper.references[i];
              return Card(
                child: ListTile(
                  title: Text(r.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '[@${r.citationKey}] · ${r.shortLabel}'
                      '${r.venue.isEmpty ? '' : ' · ${r.venue}'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => app.deleteReference(paper, r.id),
                  ),
                  onTap: () => _edit(context, app, r),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add-ref',
            onPressed: () => _edit(context, app, null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
      BuildContext context, AppState app, Reference? existing) async {
    final key = TextEditingController(text: existing?.citationKey ?? '');
    final title = TextEditingController(text: existing?.title ?? '');
    final authors = TextEditingController(text: existing?.authors ?? '');
    final venue = TextEditingController(text: existing?.venue ?? '');
    final year =
        TextEditingController(text: existing?.year?.toString() ?? '');
    final doi = TextEditingController(text: existing?.doi ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add reference' : 'Edit reference'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(key, 'Citation key (e.g. smith2021)'),
              _field(title, 'Title'),
              _field(authors, 'Authors'),
              _field(venue, 'Venue / journal'),
              _field(year, 'Year', keyboard: TextInputType.number),
              _field(doi, 'DOI'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await app.upsertReference(
        paper,
        Reference(
          id: existing?.id ?? app.newId(),
          citationKey: key.text.trim(),
          title: title.text.trim(),
          authors: authors.text.trim(),
          venue: venue.text.trim(),
          year: int.tryParse(year.text.trim()),
          doi: doi.text.trim(),
        ),
      );
    }
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
