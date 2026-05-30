import 'asset.dart';
import 'author.dart';
import 'enums.dart';
import 'reference.dart';
import 'review.dart';
import 'section.dart';

/// The aggregate root: a research paper project bundling its content,
/// graphics, bibliography and review history.
///
/// Serialises to a git-friendly shape (see [toJson]) mirroring an on-disk
/// layout: `paper.json` + `content/*.md` + `assets/*` + `references.json` +
/// `reviews/round-N/`.
class Paper {
  final String id;
  final String title;
  final String abstractText;
  final List<String> keywords;
  final PaperStatus status;

  /// Increments on each (re)submission.
  final int version;

  final List<Author> authors;
  final List<Section> sections;
  final List<Reference> references;
  final List<Asset> assets;
  final List<ReviewRound> reviewRounds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Paper({
    required this.id,
    required this.title,
    this.abstractText = '',
    this.keywords = const [],
    this.status = PaperStatus.draft,
    this.version = 1,
    this.authors = const [],
    this.sections = const [],
    this.references = const [],
    this.assets = const [],
    this.reviewRounds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Paper copyWith({
    String? title,
    String? abstractText,
    List<String>? keywords,
    PaperStatus? status,
    int? version,
    List<Author>? authors,
    List<Section>? sections,
    List<Reference>? references,
    List<Asset>? assets,
    List<ReviewRound>? reviewRounds,
    DateTime? updatedAt,
  }) {
    return Paper(
      id: id,
      title: title ?? this.title,
      abstractText: abstractText ?? this.abstractText,
      keywords: keywords ?? this.keywords,
      status: status ?? this.status,
      version: version ?? this.version,
      authors: authors ?? this.authors,
      sections: sections ?? this.sections,
      references: references ?? this.references,
      assets: assets ?? this.assets,
      reviewRounds: reviewRounds ?? this.reviewRounds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  ReviewRound? get currentRound =>
      reviewRounds.isEmpty ? null : reviewRounds.last;

  int get totalWordCount =>
      sections.fold(0, (sum, s) => sum + s.wordCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'abstractText': abstractText,
        'keywords': keywords,
        'status': status.name,
        'version': version,
        'authors': authors.map((a) => a.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'references': references.map((r) => r.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
        'reviewRounds': reviewRounds.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Paper.fromJson(Map<String, dynamic> json) => Paper(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled',
        abstractText: json['abstractText'] as String? ?? '',
        keywords: (json['keywords'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        status: paperStatusFromName(json['status'] as String?),
        version: json['version'] as int? ?? 1,
        authors: (json['authors'] as List<dynamic>? ?? [])
            .map((e) => Author.fromJson(e as Map<String, dynamic>))
            .toList(),
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => Section.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
        references: (json['references'] as List<dynamic>? ?? [])
            .map((e) => Reference.fromJson(e as Map<String, dynamic>))
            .toList(),
        assets: (json['assets'] as List<dynamic>? ?? [])
            .map((e) => Asset.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviewRounds: (json['reviewRounds'] as List<dynamic>? ?? [])
            .map((e) => ReviewRound.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
