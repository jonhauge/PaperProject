import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/paper.dart';
import '../state/app_state.dart';
import 'paper_detail_screen.dart';
import 'widgets.dart';

/// Landing screen: pick the role you are acting as, then browse the papers
/// relevant to that role and create new ones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PaperFlow'),
        actions: [
          _RoleMenu(active: app.activeRole, onSelected: app.setActiveRole),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: app.activeRole == UserRole.author
          ? FloatingActionButton.extended(
              onPressed: () => _createPaper(context),
              icon: const Icon(Icons.add),
              label: const Text('New paper'),
            )
          : null,
      body: app.loading
          ? const Center(child: CircularProgressIndicator())
          : _PaperList(papers: _visiblePapers(app)),
    );
  }

  List<Paper> _visiblePapers(AppState app) {
    // Editors and reviewers only care about papers that have entered the
    // review pipeline; authors see everything.
    switch (app.activeRole) {
      case UserRole.author:
        return app.papers;
      case UserRole.editor:
      case UserRole.reviewer:
        return app.papers
            .where((p) => p.status != PaperStatus.draft)
            .toList();
    }
  }

  Future<void> _createPaper(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New paper'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Working title'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title == null) return;
    if (!context.mounted) return;
    final app = context.read<AppState>();
    final paper = await app.createPaper(title);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaperDetailScreen(paperId: paper.id),
      ),
    );
  }
}

class _RoleMenu extends StatelessWidget {
  const _RoleMenu({required this.active, required this.onSelected});

  final UserRole active;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<UserRole>(
      onSelected: onSelected,
      itemBuilder: (_) => UserRole.values
          .map((r) => PopupMenuItem(
                value: r,
                child: Row(
                  children: [
                    Icon(
                      r == active
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(r.label),
                  ],
                ),
              ))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.switch_account, size: 18),
        label: Text(active.label),
      ),
    );
  }
}

class _PaperList extends StatelessWidget {
  const _PaperList({required this.papers});

  final List<Paper> papers;

  @override
  Widget build(BuildContext context) {
    if (papers.isEmpty) {
      return const EmptyState(
        icon: Icons.article_outlined,
        message: 'No papers here yet.',
      );
    }
    final df = DateFormat.yMMMd();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = papers[i];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              p.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${p.authors.length} author(s) · v${p.version} · '
                'updated ${df.format(p.updatedAt)}',
              ),
            ),
            trailing: StatusChip(p.status),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaperDetailScreen(paperId: p.id),
              ),
            ),
          ),
        );
      },
    );
  }
}
