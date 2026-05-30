import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/paper_repository.dart';
import '../models/asset.dart';
import '../models/author.dart';
import '../models/enums.dart';
import '../models/paper.dart';
import '../models/reference.dart';
import '../models/review.dart';
import '../models/section.dart';
import '../services/workflow.dart';
import 'seed.dart';

/// Central application state. Holds the list of papers, the active role the
/// user is currently acting as, and exposes intent-style mutation methods that
/// keep persistence and the workflow rules in sync.
class AppState extends ChangeNotifier {
  AppState(this._repo);

  final PaperRepository _repo;
  final _uuid = const Uuid();
  final _workflow = const Workflow();

  List<Paper> _papers = [];
  bool _loading = true;
  UserRole _activeRole = UserRole.author;

  List<Paper> get papers => List.unmodifiable(_papers);
  bool get loading => _loading;
  UserRole get activeRole => _activeRole;
  Workflow get workflow => _workflow;

  Future<void> init() async {
    _papers = await _repo.loadAll();
    if (_papers.isEmpty) {
      _papers = [buildSamplePaper(DateTime.now())];
      await _persist();
    }
    _loading = false;
    notifyListeners();
  }

  void setActiveRole(UserRole role) {
    _activeRole = role;
    notifyListeners();
  }

  Paper? byId(String id) {
    for (final p in _papers) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _persist() => _repo.saveAll(_papers);

  Future<void> _replace(Paper updated) async {
    final idx = _papers.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _papers[idx] = updated;
    } else {
      _papers.add(updated);
    }
    await _persist();
    notifyListeners();
  }

  // --- Paper CRUD -----------------------------------------------------------

  Future<Paper> createPaper(String title) async {
    final now = DateTime.now();
    final paper = Paper(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled paper' : title.trim(),
      createdAt: now,
      updatedAt: now,
      sections: [
        Section(
          id: _uuid.v4(),
          title: 'Introduction',
          fileName: 'introduction.md',
          order: 0,
        ),
      ],
    );
    await _replace(paper);
    return paper;
  }

  Future<void> deletePaper(String id) async {
    _papers.removeWhere((p) => p.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateMetadata(
    Paper paper, {
    String? title,
    String? abstractText,
    List<String>? keywords,
  }) async {
    await _replace(paper.copyWith(
      title: title,
      abstractText: abstractText,
      keywords: keywords,
      updatedAt: DateTime.now(),
    ));
  }

  // --- Sections -------------------------------------------------------------

  Future<void> addSection(Paper paper, String title) async {
    final order = paper.sections.length;
    final section = Section(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'New section' : title.trim(),
      fileName: _slug('${title.isEmpty ? 'section' : title}.md'),
      order: order,
    );
    await _replace(paper.copyWith(
      sections: [...paper.sections, section],
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> updateSection(Paper paper, Section section) async {
    final sections = paper.sections
        .map((s) => s.id == section.id ? section : s)
        .toList();
    await _replace(
        paper.copyWith(sections: sections, updatedAt: DateTime.now()));
  }

  Future<void> deleteSection(Paper paper, String sectionId) async {
    final sections =
        paper.sections.where((s) => s.id != sectionId).toList();
    await _replace(
        paper.copyWith(sections: sections, updatedAt: DateTime.now()));
  }

  // --- References -----------------------------------------------------------

  Future<void> upsertReference(Paper paper, Reference reference) async {
    final exists = paper.references.any((r) => r.id == reference.id);
    final refs = exists
        ? paper.references
            .map((r) => r.id == reference.id ? reference : r)
            .toList()
        : [...paper.references, reference];
    await _replace(
        paper.copyWith(references: refs, updatedAt: DateTime.now()));
  }

  Future<void> deleteReference(Paper paper, String refId) async {
    await _replace(paper.copyWith(
      references: paper.references.where((r) => r.id != refId).toList(),
      updatedAt: DateTime.now(),
    ));
  }

  String newId() => _uuid.v4();

  // --- Assets ---------------------------------------------------------------

  Future<void> addAsset(Paper paper, Asset asset) async {
    await _replace(paper.copyWith(
      assets: [...paper.assets, asset],
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deleteAsset(Paper paper, String assetId) async {
    await _replace(paper.copyWith(
      assets: paper.assets.where((a) => a.id != assetId).toList(),
      updatedAt: DateTime.now(),
    ));
  }

  // --- Authors --------------------------------------------------------------

  Future<void> upsertAuthor(Paper paper, Author author) async {
    final exists = paper.authors.any((a) => a.id == author.id);
    final authors = exists
        ? paper.authors.map((a) => a.id == author.id ? author : a).toList()
        : [...paper.authors, author];
    await _replace(
        paper.copyWith(authors: authors, updatedAt: DateTime.now()));
  }

  // --- Workflow -------------------------------------------------------------

  bool canSubmit(Paper paper) => _workflow.canSubmit(paper);
  bool canStartReview(Paper paper) => _workflow.canStartReview(paper);
  bool canDecide(Paper paper) => _workflow.canDecide(paper);

  Future<void> submit(Paper paper) async {
    if (!_workflow.canSubmit(paper)) return;
    await _replace(_workflow.submit(paper,
        roundId: _uuid.v4(), now: DateTime.now()));
  }

  Future<void> startReview(Paper paper) async {
    if (!_workflow.canStartReview(paper)) return;
    await _replace(_workflow.startReview(paper, now: DateTime.now()));
  }

  Future<void> decide(
    Paper paper,
    EditorDecision decision,
    String note,
  ) async {
    if (!_workflow.canDecide(paper)) return;
    await _replace(_workflow.decide(paper,
        decision: decision, note: note, now: DateTime.now()));
  }

  // --- Reviews --------------------------------------------------------------

  Future<void> upsertReview(Paper paper, Review review) async {
    final round = paper.currentRound;
    if (round == null) return;
    final exists = round.reviews.any((r) => r.id == review.id);
    final reviews = exists
        ? round.reviews.map((r) => r.id == review.id ? review : r).toList()
        : [...round.reviews, review];
    final updatedRound = round.copyWith(reviews: reviews);
    final rounds = [...paper.reviewRounds];
    rounds[rounds.length - 1] = updatedRound;
    await _replace(
        paper.copyWith(reviewRounds: rounds, updatedAt: DateTime.now()));
  }

  Future<void> setAuthorResponse(Paper paper, String response) async {
    final round = paper.currentRound;
    if (round == null) return;
    final rounds = [...paper.reviewRounds];
    rounds[rounds.length - 1] = round.copyWith(authorResponse: response);
    await _replace(
        paper.copyWith(reviewRounds: rounds, updatedAt: DateTime.now()));
  }

  String _slug(String input) {
    final s = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return s.isEmpty ? 'section.md' : s;
  }
}
