import 'enums.dart';

/// A single reviewer's review for a paper within a given review round.
class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;

  /// Confidential summary visible to editor and (after the round) the author.
  final String summary;

  /// Detailed comments to the authors.
  final String commentsToAuthors;

  /// Private comments only the editor sees.
  final String commentsToEditor;

  final ReviewRecommendation recommendation;

  /// Overall score, 1..5.
  final int score;
  final bool submitted;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.summary = '',
    this.commentsToAuthors = '',
    this.commentsToEditor = '',
    this.recommendation = ReviewRecommendation.majorRevision,
    this.score = 3,
    this.submitted = false,
    required this.updatedAt,
  });

  Review copyWith({
    String? reviewerName,
    String? summary,
    String? commentsToAuthors,
    String? commentsToEditor,
    ReviewRecommendation? recommendation,
    int? score,
    bool? submitted,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id,
      reviewerId: reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      summary: summary ?? this.summary,
      commentsToAuthors: commentsToAuthors ?? this.commentsToAuthors,
      commentsToEditor: commentsToEditor ?? this.commentsToEditor,
      recommendation: recommendation ?? this.recommendation,
      score: score ?? this.score,
      submitted: submitted ?? this.submitted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'summary': summary,
        'commentsToAuthors': commentsToAuthors,
        'commentsToEditor': commentsToEditor,
        'recommendation': recommendation.name,
        'score': score,
        'submitted': submitted,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        reviewerId: json['reviewerId'] as String? ?? '',
        reviewerName: json['reviewerName'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        commentsToAuthors: json['commentsToAuthors'] as String? ?? '',
        commentsToEditor: json['commentsToEditor'] as String? ?? '',
        recommendation:
            reviewRecommendationFromName(json['recommendation'] as String?),
        score: json['score'] as int? ?? 3,
        submitted: json['submitted'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A round of peer review. A paper accrues one round per submission/revision
/// cycle. The editor closes a round with a [decision].
class ReviewRound {
  final String id;
  final int number;
  final List<Review> reviews;
  final EditorDecision? decision;
  final String decisionNote;

  /// The author's point-by-point response, written during revision.
  final String authorResponse;
  final DateTime openedAt;
  final DateTime? closedAt;

  const ReviewRound({
    required this.id,
    required this.number,
    this.reviews = const [],
    this.decision,
    this.decisionNote = '',
    this.authorResponse = '',
    required this.openedAt,
    this.closedAt,
  });

  bool get isClosed => decision != null;

  ReviewRound copyWith({
    List<Review>? reviews,
    EditorDecision? decision,
    String? decisionNote,
    String? authorResponse,
    DateTime? closedAt,
  }) {
    return ReviewRound(
      id: id,
      number: number,
      reviews: reviews ?? this.reviews,
      decision: decision ?? this.decision,
      decisionNote: decisionNote ?? this.decisionNote,
      authorResponse: authorResponse ?? this.authorResponse,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'decision': decision?.name,
        'decisionNote': decisionNote,
        'authorResponse': authorResponse,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
      };

  factory ReviewRound.fromJson(Map<String, dynamic> json) => ReviewRound(
        id: json['id'] as String,
        number: json['number'] as int? ?? 1,
        reviews: (json['reviews'] as List<dynamic>? ?? [])
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        decision: json['decision'] == null
            ? null
            : editorDecisionFromName(json['decision'] as String?),
        decisionNote: json['decisionNote'] as String? ?? '',
        authorResponse: json['authorResponse'] as String? ?? '',
        openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '') ??
            DateTime.now(),
        closedAt: json['closedAt'] == null
            ? null
            : DateTime.tryParse(json['closedAt'] as String),
      );
}
