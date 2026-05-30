import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/paper.dart';
import '../state/app_state.dart';
import 'tabs/content_tab.dart';
import 'tabs/figures_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/references_tab.dart';
import 'tabs/review_tab.dart';
import 'widgets.dart';

/// Detail view for a single paper. Tabs adapt to the role the user is acting
/// as: authors edit content; editors/reviewers focus on the review tab.
class PaperDetailScreen extends StatelessWidget {
  const PaperDetailScreen({required this.paperId, super.key});

  final String paperId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final paper = app.byId(paperId);
    if (paper == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          message: 'This paper no longer exists.',
        ),
      );
    }

    final isAuthor = app.activeRole == UserRole.author;

    final tabs = <Tab>[
      const Tab(text: 'Overview'),
      if (isAuthor) const Tab(text: 'Content'),
      if (isAuthor) const Tab(text: 'Figures'),
      if (isAuthor) const Tab(text: 'References'),
      const Tab(text: 'Review'),
    ];
    final views = <Widget>[
      OverviewTab(paper: paper),
      if (isAuthor) ContentTab(paper: paper),
      if (isAuthor) FiguresTab(paper: paper),
      if (isAuthor) ReferencesTab(paper: paper),
      ReviewTab(paper: paper),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            paper.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: StatusChip(paper.status)),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        body: TabBarView(children: views),
        floatingActionButton: _buildFab(context, app, paper),
      ),
    );
  }

  Widget? _buildFab(BuildContext context, AppState app, Paper paper) {
    if (app.activeRole == UserRole.author && app.canSubmit(paper)) {
      return FloatingActionButton.extended(
        onPressed: () => _confirmSubmit(context, app, paper),
        icon: const Icon(Icons.send),
        label: Text(paper.status == PaperStatus.revisionRequested
            ? 'Resubmit'
            : 'Submit'),
      );
    }
    if (app.activeRole == UserRole.editor && app.canStartReview(paper)) {
      return FloatingActionButton.extended(
        onPressed: () => app.startReview(paper),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start review'),
      );
    }
    return null;
  }

  Future<void> _confirmSubmit(
      BuildContext context, AppState app, Paper paper) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit for review?'),
        content: const Text(
          'The manuscript will be locked into a review round and made '
          'visible to editors and reviewers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok == true) await app.submit(paper);
  }
}
