import '../utils/input_normalizer.dart';

/// What a built-in entry is mostly used for.
enum EntryKind { common, name, place, phrase, culture, loan }

/// One built-in or app-supplied Gujarati reading.
class DictionaryEntry {
  /// Creates a dictionary entry.
  const DictionaryEntry({
    required this.roman,
    required this.gujarati,
    required this.frequency,
    required this.kind,
  });

  /// Normalized roman key.
  final String roman;

  /// Standard Gujarati spelling.
  final String gujarati;

  /// Relative frequency from 1 to 100. Higher wins ties inside the lexicon.
  final int frequency;

  /// Coarse category, used when an app inspects the lexicon.
  final EntryKind kind;
}

/// A boost applied when [previous] was just transliterated.
class ContextHint {
  /// Creates a context hint.
  const ContextHint({
    required this.previous,
    required this.roman,
    required this.gujarati,
    required this.boostThousandths,
  });

  /// Gujarati text of the preceding word.
  final String previous;

  /// Normalized roman key of the current word.
  final String roman;

  /// Reading to boost.
  final String gujarati;

  /// Added to the candidate score, in thousandths of a confidence point.
  final int boostThousandths;
}

/// In-memory Gujarati lexicon.
class WordDictionary {
  /// Creates an empty dictionary.
  WordDictionary();

  final Map<String, List<DictionaryEntry>> _words = {};
  final Map<String, List<DictionaryEntry>> _phrases = {};
  final Map<String, List<ContextHint>> _context = {};

  /// Every word and phrase entry currently stored.
  List<DictionaryEntry> get entries => List.unmodifiable([
        for (final list in _words.values) ...list,
        for (final list in _phrases.values) ...list,
      ]);

  /// Adds a word or, when [roman] contains a space, a phrase.
  ///
  /// The same roman key can have more than one spelling. A repeated spelling
  /// keeps the higher frequency.
  void add(
    String roman,
    String gujarati, {
    int frequency = 50,
    EntryKind kind = EntryKind.common,
  }) {
    final key = _normalize(roman);
    final spelling = gujarati.trim();
    if (key.isEmpty || spelling.isEmpty) {
      throw ArgumentError('Dictionary entries need a roman form and Gujarati.');
    }
    final entry = DictionaryEntry(
      roman: key,
      gujarati: spelling,
      frequency: frequency.clamp(1, 100),
      kind: key.contains(' ') ? EntryKind.phrase : kind,
    );
    final map = key.contains(' ') ? _phrases : _words;
    final list = map.putIfAbsent(key, () => <DictionaryEntry>[]);
    final index = list.indexWhere((item) => item.gujarati == spelling);
    if (index < 0) {
      list.add(entry);
    } else if (entry.frequency > list[index].frequency) {
      list[index] = entry;
    }
  }

  /// Records that [gujarati] is more likely after [previous].
  void addContext(
    String previous,
    String roman,
    String gujarati, {
    int boostThousandths = 120,
  }) {
    final hint = ContextHint(
      previous: previous.trim(),
      roman: dictionaryKey(roman),
      gujarati: gujarati.trim(),
      boostThousandths: boostThousandths,
    );
    if (hint.previous.isEmpty || hint.roman.isEmpty || hint.gujarati.isEmpty) {
      throw ArgumentError(
          'Context hints need a previous word, roman, and spelling.');
    }
    _context
        .putIfAbsent('${hint.previous}|${hint.roman}', () => <ContextHint>[])
        .add(hint);
  }

  /// Readings stored for a single word.
  List<DictionaryEntry> lookupWord(String word) {
    return List.unmodifiable(_words[dictionaryKey(word)] ?? const []);
  }

  /// Readings stored for a phrase key such as `kem cho`.
  List<DictionaryEntry> lookupPhrase(String phrase) {
    return List.unmodifiable(_phrases[_normalize(phrase)] ?? const []);
  }

  /// Context hints for [word] when the previous output was [previous].
  List<ContextHint> hintsFor(String? previous, String word) {
    if (previous == null || previous.isEmpty) return const [];
    final hints = _context['$previous|${dictionaryKey(word)}'];
    if (hints == null) return const [];
    return List.unmodifiable(hints);
  }

  String _normalize(String roman) {
    return roman
        .trim()
        .split(RegExp(r'\s+'))
        .map(dictionaryKey)
        .where((part) => part.isNotEmpty)
        .join(' ');
  }
}
