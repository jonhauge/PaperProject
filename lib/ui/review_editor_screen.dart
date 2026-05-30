import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/paper.dart';
import '../models/review.dart';
import '../state/app_state.dart';

/// Form a reviewer uses to compose or update their review for the current
/// round, including separate comments to authors and to the editor.
class ReviewEditorScreen extends StatefulWidget {
  const ReviewEditorScreen({
    required this.paperId,
    required this.reviewerId,
    this.reviewId,
    super.key,
  });

  final String paperId;
  final String reviewerId;
  final String? reviewId;

  @override
  State<ReviewEditorScreen> createState() => _ReviewEditorScreenState();
}

class _ReviewEditorScreenState extends State<ReviewEditorScreen> {
  final _name = TextEditingController();
  final _summary = TextEditingController();
  final _toAuthors = TextEditingController();
  final _toEditor = TextEditingController();
  ReviewRecommendation _recommendation = ReviewRecommendation.majorRevision;
  double _score = 3;

  Review? _existing;

  @override
  void initState() {
    super.initState();
    final r = _find();
    if (r != null) {
      _existing = r;
      _name.text = r.reviewerName;
      _summary.text = r.summary;
      _toAuthors.text = r.commentsToAuthors;
      _toEditor.text = r.commentsToEditor;
      _recommendation = r.recommendation;
      _score = r.score.toDouble();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    _toAuthors.dispose();
    _toEditor.dispose();
    super.dispose();
  }

  Review? _find() {
    if (widget.reviewId == null) return null;
    final paper = context.read<AppState>().byId(widget.paperId);
    final round = paper?.currentRound;
    if (round == null) return null;
    for (final r in round.reviews) {
      if (r.id == widget.reviewId) return r;
    }
    return null;
  }

  Future<void> _save({required bool submit}) async {
    final app = context.read<AppState>();
    final paper = app.byId(widget.paperId);
    if (paper == null) return;
    final review = Review(
      id: _existing?.id ?? app.newId(),
      reviewerId: widget.reviewerId,
      reviewerName: _name.text.trim(),
      summary: _summary.text.trim(),
      commentsToAuthors: _toAuthors.text.trim(),
      commentsToEditor: _toEditor.text.trim(),
      recommendation: _recommendation,
      score: _score.round(),
      submitted: submit || (_existing?.submitted ?? false),
      updatedAt: DateTime.now(),
    );
    await app.upsertReview(paper, review);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summary,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Summary of the paper'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toAuthors,
            maxLines: 6,
            decoration:
                const InputDecoration(labelText: 'Comments to authors'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toEditor,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Confidential comments to editor'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReviewRecommendation>(
            initialValue: _recommendation,
            decoration:
                const InputDecoration(labelText: 'Recommendation'),
            items: ReviewRecommendation.values
                .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) =>
                setState(() => _recommendation = v ?? _recommendation),
          ),
          const SizedBox(height: 16),
          Text('Overall score: ${_score.round()} / 5'),
          Slider(
            value: _score,
            min: 1,
            max: 5,
            divisions: 4,
            label: '${_score.round()}',
            onChanged: (v) => setState(() => _score = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(submit: false),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(submit: true),
                  child: const Text('Submit review'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
