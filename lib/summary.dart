const acceptableImageFormats = <String>['png', 'jpg', 'jpeg'];

class ImageFile {
  const ImageFile({required this.source});

  final String source;

  static ImageFile fromJson(Map<String, Object?> json) {
    return ImageFile(source: (json['source'] as String?) ?? '');
  }
}

class TitlesSet {
  const TitlesSet({
    required this.canonical,
    required this.normalized,
    required this.display,
  });

  final String canonical;
  final String normalized;
  final String display;

  static TitlesSet fromJson(Map<String, Object?> json) {
    return TitlesSet(
      canonical: (json['canonical'] as String?) ?? '',
      normalized: (json['normalized'] as String?) ?? '',
      display: (json['display'] as String?) ?? '',
    );
  }
}

class Summary {
  const Summary({
    required this.titles,
    required this.pageid,
    required this.extract,
    required this.extractHtml,
    this.thumbnail,
    this.originalImage,
    this.description,
    this.url,
  });

  final TitlesSet titles;
  final int pageid;
  final String extract;
  final String extractHtml;
  final ImageFile? thumbnail;
  final ImageFile? originalImage;
  final String? description;
  final String? url;

  ImageFile? get preferredSource {
    if (_isAccepted(originalImage?.source)) {
      return originalImage;
    }
    if (_isAccepted(thumbnail?.source)) {
      return thumbnail;
    }
    return null;
  }

  bool get hasImage => preferredSource != null;

  static Summary fromJson(Map<String, Object?> json) {
    return Summary(
      titles: TitlesSet.fromJson(
        (json['titles'] as Map?)?.cast<String, Object?>() ??
            <String, Object?>{},
      ),
      pageid: (json['pageid'] as num?)?.toInt() ?? 0,
      extract: (json['extract'] as String?) ?? '',
      extractHtml: (json['extract_html'] as String?) ?? '',
      thumbnail: _toImage(json['thumbnail']),
      originalImage: _toImage(json['originalimage']),
      description: json['description'] as String?,
      url: _extractPageUrl(json['content_urls']),
    );
  }

  static String? _extractPageUrl(Object? rawContentUrls) {
    final contentUrls = (rawContentUrls as Map?)?.cast<String, Object?>();
    final desktop = (contentUrls?['desktop'] as Map?)?.cast<String, Object?>();
    return desktop?['page'] as String?;
  }

  static ImageFile? _toImage(Object? raw) {
    final map = (raw as Map?)?.cast<String, Object?>();
    if (map == null) {
      return null;
    }
    final image = ImageFile.fromJson(map);
    return image.source.isEmpty ? null : image;
  }

  static bool _isAccepted(String? source) {
    if (source == null || source.isEmpty) {
      return false;
    }
    final ext = source.split('.').last.toLowerCase();
    return acceptableImageFormats.contains(ext);
  }
}
