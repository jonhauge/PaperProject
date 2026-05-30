/// Core enumerations describing the lifecycle of a research paper and the
/// roles people can take in the authoring/review process.

/// The lifecycle state of a paper as it moves through writing, submission,
/// peer review and revision.
enum PaperStatus {
  draft,
  submitted,
  underReview,
  revisionRequested,
  resubmitted,
  accepted,
  rejected;

  String get label {
    switch (this) {
      case PaperStatus.draft:
        return 'Draft';
      case PaperStatus.submitted:
        return 'Submitted';
      case PaperStatus.underReview:
        return 'Under review';
      case PaperStatus.revisionRequested:
        return 'Revision requested';
      case PaperStatus.resubmitted:
        return 'Resubmitted';
      case PaperStatus.accepted:
        return 'Accepted';
      case PaperStatus.rejected:
        return 'Rejected';
    }
  }
}

/// The role a person plays for a given paper. The same user account can hold
/// different roles on different papers.
enum UserRole {
  author,
  editor,
  reviewer;

  String get label {
    switch (this) {
      case UserRole.author:
        return 'Author';
      case UserRole.editor:
        return 'Editor';
      case UserRole.reviewer:
        return 'Reviewer';
    }
  }
}

/// A reviewer's overall recommendation for a paper.
enum ReviewRecommendation {
  accept,
  minorRevision,
  majorRevision,
  reject;

  String get label {
    switch (this) {
      case ReviewRecommendation.accept:
        return 'Accept';
      case ReviewRecommendation.minorRevision:
        return 'Minor revision';
      case ReviewRecommendation.majorRevision:
        return 'Major revision';
      case ReviewRecommendation.reject:
        return 'Reject';
    }
  }
}

/// The editor's decision that closes a review round.
enum EditorDecision {
  accept,
  revise,
  reject;

  String get label {
    switch (this) {
      case EditorDecision.accept:
        return 'Accept';
      case EditorDecision.revise:
        return 'Request revision';
      case EditorDecision.reject:
        return 'Reject';
    }
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

PaperStatus paperStatusFromName(String? name) =>
    _enumFromName(PaperStatus.values, name, PaperStatus.draft);

UserRole userRoleFromName(String? name) =>
    _enumFromName(UserRole.values, name, UserRole.author);

ReviewRecommendation reviewRecommendationFromName(String? name) =>
    _enumFromName(
        ReviewRecommendation.values, name, ReviewRecommendation.majorRevision);

EditorDecision editorDecisionFromName(String? name) =>
    _enumFromName(EditorDecision.values, name, EditorDecision.revise);
