/// Where a Gujarati candidate came from.
enum SuggestionSource {
  phonetic,
  orthographic,
  dictionary,
  context,
  custom,
  correction,
}

/// One ranked Gujarati reading of an English phonetic input.
class Suggestion {
  /// Creates a ranked suggestion.
  const Suggestion({
    required this.text,
    required this.confidence,
    required this.source,
    required this.rank,
    this.weight = 0,
  });

  /// Gujarati Unicode text.
  final String text;

  /// Relative confidence from 0 to 1. Higher is a stronger reading.
  final double confidence;

  /// Evidence that produced [text].
  final SuggestionSource source;

  /// 1-based rank within the returned list.
  final int rank;

  /// Learning weight from a saved custom entry. Zero for built-in candidates.
  final int weight;

  @override
  String toString() =>
      '$text (${confidence.toStringAsFixed(3)}, ${source.name})';

  @override
  bool operator ==(Object other) {
    return other is Suggestion &&
        other.text == text &&
        other.confidence == confidence &&
        other.source == source &&
        other.rank == rank &&
        other.weight == weight;
  }

  @override
  int get hashCode => Object.hash(text, confidence, source, rank, weight);
}
