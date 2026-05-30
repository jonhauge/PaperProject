/// A graphics/figure file referenced from the markdown content.
///
/// On native platforms the bytes live on disk under the paper's `assets/`
/// folder; on web they are kept as base64 in storage. Markdown content refers
/// to an asset by its [fileName], e.g. `![Figure 1](assets/figure1.png)`.
class Asset {
  final String id;
  final String fileName;
  final String caption;

  /// Base64-encoded bytes. Kept inline so a paper is fully self-contained and
  /// easy to serialise into a git-friendly bundle. May be empty if the file is
  /// stored out-of-band on disk.
  final String base64Data;

  const Asset({
    required this.id,
    required this.fileName,
    this.caption = '',
    this.base64Data = '',
  });

  Asset copyWith({String? fileName, String? caption, String? base64Data}) {
    return Asset(
      id: id,
      fileName: fileName ?? this.fileName,
      caption: caption ?? this.caption,
      base64Data: base64Data ?? this.base64Data,
    );
  }

  /// The path used inside markdown to reference this asset.
  String get markdownPath => 'assets/$fileName';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'caption': caption,
        'base64Data': base64Data,
      };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String,
        fileName: json['fileName'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        base64Data: json['base64Data'] as String? ?? '',
      );
}
