import '../models/enums.dart';
import '../models/paper.dart';
import '../models/review.dart';

/// Encapsulates the legal transitions of the paper lifecycle so the rules live
/// in one place rather than being scattered across the UI.
class Workflow {
  const Workflow();

  /// Whether [paper] can currently be submitted (or resubmitted) by an author.
  bool canSubmit(Paper paper) {
    switch (paper.status) {
      case PaperStatus.draft:
      case PaperStatus.revisionRequested:
        return paper.title.trim().isNotEmpty && paper.sections.isNotEmpty;
      default:
        return false;
    }
  }

  /// Whether an editor can assign reviewers / open review.
  bool canStartReview(Paper paper) =>
      paper.status == PaperStatus.submitted ||
      paper.status == PaperStatus.resubmitted;

  /// Whether the editor can record a decision for the current round.
  bool canDecide(Paper paper) =>
      paper.status == PaperStatus.underReview &&
      paper.currentRound != null &&
      !paper.currentRound!.isClosed;

  /// Author submits the paper, opening a fresh review round.
  Paper submit(Paper paper, {required String roundId, required DateTime now}) {
    final isResubmit = paper.status == PaperStatus.revisionRequested;
    final nextNumber = paper.reviewRounds.length + 1;
    final round = ReviewRound(
      id: roundId,
      number: nextNumber,
      openedAt: now,
    );
    return paper.copyWith(
      status: isResubmit ? PaperStatus.resubmitted : PaperStatus.submitted,
      version: isResubmit ? paper.version + 1 : paper.version,
      reviewRounds: [...paper.reviewRounds, round],
      updatedAt: now,
    );
  }

  /// Editor moves a submitted paper into active review.
  Paper startReview(Paper paper, {required DateTime now}) {
    return paper.copyWith(status: PaperStatus.underReview, updatedAt: now);
  }

  /// Editor records the decision for the current round, advancing the status.
  Paper decide(
    Paper paper, {
    required EditorDecision decision,
    required String note,
    required DateTime now,
  }) {
    final round = paper.currentRound;
    if (round == null) return paper;
    final closed = round.copyWith(
      decision: decision,
      decisionNote: note,
      closedAt: now,
    );
    final rounds = [...paper.reviewRounds];
    rounds[rounds.length - 1] = closed;

    final PaperStatus next;
    switch (decision) {
      case EditorDecision.accept:
        next = PaperStatus.accepted;
        break;
      case EditorDecision.reject:
        next = PaperStatus.rejected;
        break;
      case EditorDecision.revise:
        next = PaperStatus.revisionRequested;
        break;
    }
    return paper.copyWith(status: next, reviewRounds: rounds, updatedAt: now);
  }
}
