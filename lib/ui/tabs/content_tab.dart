import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/paper.dart';
import '../../state/app_state.dart';
import '../section_editor_screen.dart';
import '../widgets.dart';

/// Lists the paper's sections (markdown files) and lets the author add, open
/// or remove them.
class ContentTab extends StatelessWidget {
  const ContentTab({required this.paper, super.key});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final sections = [...paper.sections]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Stack(
      children: [
        if (sections.isEmpty)
          const EmptyState(
            icon: Icons.description_outlined,
            message: 'No sections yet. Add your first one.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = sections[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(s.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.fileName} · ${s.wordCount} words'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        app.deleteSection(paper, s.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SectionEditorScreen(
                        paperId: paper.id,
                        sectionId: s.id,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add-section',
            onPressed: () => _addSection(context, app),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _addSection(BuildContext context, AppState app) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Section title'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title != null) await app.addSection(paper, title);
  }
}
