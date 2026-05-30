import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/paper.dart';
import '../../state/app_state.dart';
import '../widgets.dart';

/// Editable metadata and at-a-glance stats for a paper.
class OverviewTab extends StatefulWidget {
  const OverviewTab({required this.paper, super.key});

  final Paper paper;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late final TextEditingController _title;
  late final TextEditingController _abstract;
  late final TextEditingController _keywords;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.paper.title);
    _abstract = TextEditingController(text: widget.paper.abstractText);
    _keywords = TextEditingController(text: widget.paper.keywords.join(', '));
  }

  @override
  void dispose() {
    _title.dispose();
    _abstract.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    await app.updateMetadata(
      widget.paper,
      title: _title.text,
      abstractText: _abstract.text,
      keywords: _keywords.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paper;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatCard(label: 'Version', value: 'v${p.version}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Sections', value: '${p.sections.length}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Words', value: '${p.totalWordCount}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Rounds', value: '${p.reviewRounds.length}'),
          ],
        ),
        const SectionHeader('Title'),
        TextField(controller: _title),
        const SectionHeader('Abstract'),
        TextField(controller: _abstract, maxLines: 6),
        const SectionHeader('Keywords (comma-separated)'),
        TextField(controller: _keywords),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Save changes'),
        ),
        const SizedBox(height: 24),
        const SectionHeader('Authors'),
        ...p.authors.map(
          (a) => ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(a.name),
            subtitle: Text([a.affiliation, a.email]
                .where((s) => s.isNotEmpty)
                .join(' · ')),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
