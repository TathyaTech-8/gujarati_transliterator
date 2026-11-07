import 'suggestion.dart';
import 'transliteration_mode.dart';

/// Kind of slice preserved from the original input.
enum SpanType { word, whitespace, punctuation, number, passthrough }

/// One slice of an input and the Gujarati text chosen for it.
class TransliteratedSpan {
  /// Creates a span.
  const TransliteratedSpan({
    required this.input,
    required this.output,
    required this.type,
    required this.committed,
    this.suggestions = const [],
  });

  /// Copies [text] through unchanged.
  const TransliteratedSpan.literal(String text, this.type)
      : input = text,
        output = text,
        committed = true,
        suggestions = const [];

  /// Original slice, including its casing.
  final String input;

  /// Text contributed to the transliteration.
  final String output;

  /// What [input] was classified as.
  final SpanType type;

  /// Whether a typing session should keep this word stable.
  ///
  /// Completed words stay put while the user keeps typing. The live word at
  /// the end of the input is not committed.
  final bool committed;

  /// Ranked readings for a word span. Empty for whitespace and punctuation.
  final List<Suggestion> suggestions;
}

/// Full transliteration of one input string.
class TransliterationResult {
  /// Creates a result. [text] is the concatenation of [spans].
  const TransliterationResult({
    required this.input,
    required this.text,
    required this.mode,
    required this.spans,
    required this.suggestions,
  });

  /// Text the caller passed in.
  final String input;

  /// Gujarati Unicode result, with spacing and punctuation preserved.
  final String text;

  /// Mode used to produce [text].
  final TransliterationMode mode;

  /// Spans in order. Joining [TransliteratedSpan.output] reproduces [text].
  final List<TransliteratedSpan> spans;

  /// Ranked readings of the whole input.
  ///
  /// For a single word these are that word's candidates. For more than one
  /// word, the first item is [text] and later items change one word at a time.
  final List<Suggestion> suggestions;

  /// Candidates for the word currently being typed, if there is one.
  List<Suggestion> get activeSuggestions {
    for (var i = spans.length - 1; i >= 0; i--) {
      if (spans[i].type == SpanType.word) return spans[i].suggestions;
    }
    return const [];
  }

  @override
  String toString() => text;
}
