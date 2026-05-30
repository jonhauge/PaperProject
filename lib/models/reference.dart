/// A bibliographic reference stored in the paper's `references.json`.
class Reference {
  final String id;
  final String citationKey;
  final String title;
  final String authors;
  final String venue;
  final int? year;
  final String doi;

  const Reference({
    required this.id,
    required this.citationKey,
    required this.title,
    this.authors = '',
    this.venue = '',
    this.year,
    this.doi = '',
  });

  Reference copyWith({
    String? citationKey,
    String? title,
    String? authors,
    String? venue,
    int? year,
    String? doi,
  }) {
    return Reference(
      id: id,
      citationKey: citationKey ?? this.citationKey,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      venue: venue ?? this.venue,
      year: year ?? this.year,
      doi: doi ?? this.doi,
    );
  }

  /// A short human-readable rendering, e.g. "Smith et al. (2021)".
  String get shortLabel {
    final y = year != null ? ' ($year)' : '';
    final a = authors.isNotEmpty ? authors : citationKey;
    return '$a$y';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'citationKey': citationKey,
        'title': title,
        'authors': authors,
        'venue': venue,
        'year': year,
        'doi': doi,
      };

  factory Reference.fromJson(Map<String, dynamic> json) => Reference(
        id: json['id'] as String,
        citationKey: json['citationKey'] as String? ?? '',
        title: json['title'] as String? ?? '',
        authors: json['authors'] as String? ?? '',
        venue: json['venue'] as String? ?? '',
        year: json['year'] as int?,
        doi: json['doi'] as String? ?? '',
      );
}
