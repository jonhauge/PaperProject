/// A single section of the paper, stored as a markdown file under `content/`.
///
/// The [body] is markdown that may reference graphics via standard image
/// syntax, e.g. `![Figure 1](assets/figure1.png)`.
class Section {
  final String id;
  final String title;

  /// File name used when persisting, e.g. `introduction.md`.
  final String fileName;
  final String body;

  /// Ordering within the paper.
  final int order;

  const Section({
    required this.id,
    required this.title,
    required this.fileName,
    this.body = '',
    this.order = 0,
  });

  Section copyWith({
    String? title,
    String? fileName,
    String? body,
    int? order,
  }) {
    return Section(
      id: id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      body: body ?? this.body,
      order: order ?? this.order,
    );
  }

  /// Rough word count, used for progress indicators.
  int get wordCount =>
      body.trim().isEmpty ? 0 : body.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'fileName': fileName,
        'body': body,
        'order': order,
      };

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        fileName: json['fileName'] as String? ?? 'section.md',
        body: json['body'] as String? ?? '',
        order: json['order'] as int? ?? 0,
      );
}
