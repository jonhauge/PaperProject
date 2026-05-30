import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/paper.dart';
import '../../models/review.dart';
import '../../state/app_state.dart';
import '../review_editor_screen.dart';
import '../widgets.dart';

/// The review workspace. Content adapts to the active role:
/// - Reviewer: write/update their own review for the open round.
/// - Editor: read all reviews and record a decision.
/// - Author: read decisions and reviewer comments, write a revision response.
class ReviewTab extends StatelessWidget {
  const ReviewTab({required this.paper, super.key});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (paper.reviewRounds.isEmpty) {
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        message: 'This paper has not been submitted for review yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final round in paper.reviewRounds.reversed)
          _RoundCard(paper: paper, round: round, app: app),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.paper,
    required this.round,
    required this.app,
  });

  final Paper paper;
  final ReviewRound round;
  final AppState app;

  bool get isCurrent => paper.currentRound?.id == round.id;

  @override
  Widget build(BuildContext context) {
    final role = app.activeRole;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Round ${round.number}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (round.isClosed)
                  Chip(
                    label: Text(round.decision!.label),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                Text('${round.reviews.where((r) => r.submitted).length}'
                    '/${round.reviews.length} submitted'),
              ],
            ),
            const Divider(),

            // Reviews list — visible to editor always; to author once closed;
            // reviewer sees only their own.
            ..._visibleReviews(role).map((r) => _ReviewTile(
                  review: r,
                  showAuthorOnly: role == UserRole.author,
                  onEdit: role == UserRole.reviewer && isCurrent
                      ? () => _openReviewEditor(context, r)
                      : null,
                )),

            if (_visibleReviews(role).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No reviews to show.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),

            if (round.isClosed && round.decisionNote.isNotEmpty) ...[
              const SectionHeader('Editor note'),
              Text(round.decisionNote),
            ],

            if (round.authorResponse.isNotEmpty) ...[
              const SectionHeader('Author response'),
              Text(round.authorResponse),
            ],

            const SizedBox(height: 8),
            _actions(context, role),
          ],
        ),
      ),
    );
  }

  List<Review> _visibleReviews(UserRole role) {
    switch (role) {
      case UserRole.editor:
        return round.reviews;
      case UserRole.author:
        return round.isClosed
            ? round.reviews.where((r) => r.submitted).toList()
            : const [];
      case UserRole.reviewer:
        return round.reviews
            .where((r) => r.reviewerId == _currentReviewerId)
            .toList();
    }
  }

  // For this single-device prototype the "current reviewer" is a fixed demo
  // identity; the git-backed multi-user layer will replace this with the
  // authenticated account.
  static const _currentReviewerId = 'reviewer-self';

  Widget _actions(BuildContext context, UserRole role) {
    if (!isCurrent) return const SizedBox.shrink();

    if (role == UserRole.reviewer && !round.isClosed) {
      final mine = round.reviews
          .where((r) => r.reviewerId == _currentReviewerId)
          .toList();
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _openReviewEditor(
              context, mine.isEmpty ? null : mine.first),
          icon: const Icon(Icons.edit_note),
          label: Text(mine.isEmpty ? 'Write review' : 'Edit my review'),
        ),
      );
    }

    if (role == UserRole.editor && app.canDecide(paper)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () => _decide(context),
          icon: const Icon(Icons.gavel),
          label: const Text('Record decision'),
        ),
      );
    }

    if (role == UserRole.author &&
        paper.status == PaperStatus.revisionRequested) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _writeResponse(context),
          icon: const Icon(Icons.reply),
          label: const Text('Write revision response'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openReviewEditor(BuildContext context, Review? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewEditorScreen(
          paperId: paper.id,
          reviewId: existing?.id,
          reviewerId: _currentReviewerId,
        ),
      ),
    );
  }

  Future<void> _decide(BuildContext context) async {
    EditorDecision decision = EditorDecision.revise;
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Editor decision'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<EditorDecision>(
                initialValue: decision,
                items: EditorDecision.values
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text(d.label)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => decision = v ?? decision),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Note to authors'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit decision'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await app.decide(paper, decision, note.text.trim());
    }
  }

  Future<void> _writeResponse(BuildContext context) async {
    final ctrl = TextEditingController(text: round.authorResponse);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revision response'),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Point-by-point response to the reviewers…',
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
      await app.setAuthorResponse(paper, ctrl.text.trim());
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.showAuthorOnly,
    this.onEdit,
  });

  final Review review;
  final bool showAuthorOnly;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName.isEmpty
                      ? 'Reviewer'
                      : review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                label: Text(review.recommendation.label),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Text('★ ${review.score}'),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (!review.submitted)
            Text('Draft — not submitted',
                style: Theme.of(context).textTheme.bodySmall),
          if (review.commentsToAuthors.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.commentsToAuthors),
          ],
          if (!showAuthorOnly && review.commentsToEditor.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('To editor: ${review.commentsToEditor}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
