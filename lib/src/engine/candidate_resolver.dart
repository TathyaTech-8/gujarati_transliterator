import '../dictionary/custom_dictionary.dart';
import '../dictionary/word_dictionary.dart';
import '../models/custom_entry.dart';
import '../models/suggestion.dart';
import '../models/transliteration_mode.dart';
import '../utils/input_normalizer.dart';
import '../utils/unicode_utils.dart';
import 'grammar.dart';
import 'informal_readings.dart';
import 'phonetic_parser.dart';

/// Builds ranked Gujarati readings for one roman word.
class CandidateResolver {
  /// Creates a resolver over the shared phonetic parser and the given lexicons.
  CandidateResolver({
    required PhoneticParser parser,
    required this.dictionary,
    required this.custom,
  }) : _parser = parser;

  final PhoneticParser _parser;

  /// Built-in and application lexicon.
  final WordDictionary dictionary;

  /// Local custom mappings.
  final CustomDictionary custom;

  /// Ranked readings of [word]. [previous] is the Gujarati word before it.
  List<Suggestion> resolve({
    required String word,
    required TransliterationMode mode,
    String? previous,
    String? next,
  }) {
    final prepared = preparePhoneticInput(word);
    final phonetic = _parser.parse(prepared);
    final best = <String, _Candidate>{};

    void consider({
      required String text,
      required int score,
      required SuggestionSource source,
      int weight = 0,
      DateTime? updatedAt,
      bool absolute = false,
    }) {
      if (text.isEmpty) return;
      final next = _Candidate(
        text: text,
        score: absolute ? score.clamp(0, 1000) : score.clamp(0, 990),
        source: source,
        weight: weight,
        updatedAt: updatedAt,
      );
      final current = best[text];
      if (current == null || next.outranks(current)) {
        best[text] = next;
      }
    }

    final literal = phonetic.isEmpty ? word : phonetic;
    consider(
      text: literal,
      score: _phoneticScore(mode),
      source: SuggestionSource.phonetic,
    );
    for (final variant in GujaratiUnicode.anusvaraVariants(literal)) {
      consider(
        text: variant,
        score: _orthographicScore(mode),
        source: SuggestionSource.orthographic,
      );
      consider(
        text: variant.replaceFirst(
          GujaratiUnicode.anusvara,
          GujaratiUnicode.chandrabindu,
        ),
        score: _editScore(455, mode),
        source: SuggestionSource.orthographic,
      );
    }
    // Ambiguous letter groups stay suggestions. They rank under the plain
    // phonetic reading, so an unknown name such as Trilok stays ત્રિલોક.
    for (final variant in GujaratiUnicode.vocalicRVariants(literal)) {
      consider(
        text: variant,
        score: _editScore(470, mode),
        source: SuggestionSource.orthographic,
      );
    }
    for (final edit in GujaratiUnicode.orthographicEdits(literal)) {
      consider(
        text: edit.text,
        score: _editScore(_editRankScore(edit.rank), mode),
        source: SuggestionSource.orthographic,
      );
    }
    if (prepared.contains('shh')) {
      consider(
        text: _parser.parse(prepared.replaceFirst('shh', '.sh')),
        score: _patternScore(mode),
        source: SuggestionSource.orthographic,
      );
    }
    final grammar = _properNoun(word)
        ? const <GrammarReading>[]
        : GrammarReadings.generate(
            parser: _parser,
            original: word,
            prepared: prepared,
            literal: literal,
            nextRoman: next,
          );
    for (final reading in InformalReadings.generate(
      parser: _parser,
      dictionary: dictionary,
      original: word,
      prepared: prepared,
      literal: literal,
      nextRoman: next,
    )) {
      // A real ending outranks a one-character lexicon bridge. શ/સ and the
      // other weak alternates stay, because those readings are not strong.
      if (grammar.isNotEmpty &&
          reading.strong &&
          reading.source == SuggestionSource.dictionary) {
        continue;
      }
      consider(
        text: reading.text,
        score: reading.strong
            ? _strongScore(reading.score, mode)
            : _editScore(reading.score, mode),
        source: reading.source,
      );
    }
    for (final reading in grammar) {
      consider(
        text: reading.text,
        score: _strongScore(reading.score, mode),
        source: reading.source,
      );
    }
    for (final entry in dictionary.lookupWord(word)) {
      consider(
        text: entry.gujarati,
        score: _dictionaryScore(entry.frequency, mode),
        source: SuggestionSource.dictionary,
      );
    }
    for (final entry in custom.lookup(word)) {
      consider(
        text: entry.output,
        score: entry.prefer ? 1000 : _dictionaryScore(90, mode),
        source: entry.origin == CustomOrigin.correction
            ? SuggestionSource.correction
            : SuggestionSource.custom,
        weight: entry.hits,
        updatedAt: entry.updatedAt,
        absolute: entry.prefer,
      );
    }
    if (mode != TransliterationMode.phonetic) {
      for (final hint in dictionary.hintsFor(previous, word)) {
        final current = best[hint.gujarati];
        if (current != null && current.score >= 1000) continue;
        final base = current?.score ?? _phoneticScore(mode);
        consider(
          text: hint.gujarati,
          score: base + hint.boostThousandths,
          source: SuggestionSource.context,
          weight: current?.weight ?? 0,
          updatedAt: current?.updatedAt,
        );
      }
    }

    final ranked = best.values.toList()..sort(_Candidate.compare);
    if (ranked.isEmpty) {
      ranked.add(
        _Candidate(
          text: word,
          score: _phoneticScore(mode),
          source: SuggestionSource.phonetic,
        ),
      );
    }
    return [
      for (var i = 0; i < ranked.length; i++)
        Suggestion(
          text: ranked[i].text,
          confidence: ranked[i].score / 1000,
          source: ranked[i].source,
          rank: i + 1,
          weight: ranked[i].weight,
        ),
    ];
  }

  /// Highest-priority custom entry for a phrase or word key.
  CustomEntry? bestCustom(List<CustomEntry> entries, TransliterationMode mode) {
    if (entries.isEmpty) return null;
    final ranked = [...entries]..sort(
        (a, b) => _compareCustom(a, b, mode),
      );
    return ranked.first;
  }

  /// Score for a built-in entry, in thousandths.
  int dictionaryScore(int frequency, TransliterationMode mode) {
    return _dictionaryScore(frequency, mode);
  }

  /// A stored name or place keeps its spelling. Verb endings do not rewrite it.
  bool _properNoun(String word) {
    final hits = dictionary.lookupWord(word);
    if (hits.isEmpty) return false;
    var best = hits.first;
    for (final hit in hits.skip(1)) {
      if (hit.frequency > best.frequency) best = hit;
    }
    return best.kind == EntryKind.name || best.kind == EntryKind.place;
  }

  /// Score for a custom entry, in thousandths.
  int customScore(CustomEntry entry, TransliterationMode mode) {
    return entry.prefer ? 1000 : _dictionaryScore(90, mode);
  }
}

class _Candidate {
  _Candidate({
    required this.text,
    required this.score,
    required this.source,
    this.weight = 0,
    this.updatedAt,
  });

  final String text;
  final int score;
  final SuggestionSource source;
  final int weight;
  final DateTime? updatedAt;

  bool outranks(_Candidate other) => compare(this, other) < 0;

  static int compare(_Candidate a, _Candidate b) {
    if (a.score != b.score) return b.score.compareTo(a.score);
    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final byTime = bTime.compareTo(aTime);
    if (byTime != 0) return byTime;
    if (a.weight != b.weight) return b.weight.compareTo(a.weight);
    final bySource = _priority(b.source) - _priority(a.source);
    if (bySource != 0) return bySource;
    return a.text.compareTo(b.text);
  }
}

int _compareCustom(CustomEntry a, CustomEntry b, TransliterationMode mode) {
  final scoreA = a.prefer ? 1000 : _dictionaryScore(90, mode);
  final scoreB = b.prefer ? 1000 : _dictionaryScore(90, mode);
  if (scoreA != scoreB) return scoreB.compareTo(scoreA);
  final timeA = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final timeB = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final byTime = timeB.compareTo(timeA);
  if (byTime != 0) return byTime;
  if (a.hits != b.hits) return b.hits.compareTo(a.hits);
  if (a.origin != b.origin) {
    return a.origin == CustomOrigin.correction ? -1 : 1;
  }
  return a.output.compareTo(b.output);
}

int _phoneticScore(TransliterationMode mode) => switch (mode) {
      TransliterationMode.phonetic => 920,
      TransliterationMode.standard => 340,
      TransliterationMode.intelligent => 500,
    };

int _orthographicScore(TransliterationMode mode) => switch (mode) {
      TransliterationMode.phonetic => 400,
      TransliterationMode.standard => 600,
      TransliterationMode.intelligent => 520,
    };

/// Score for an ambiguous pattern such as vocalic ર or `shh`.
///
/// Kept below the plain phonetic score in every mode, and below the
/// anusvara score in intelligent and standard mode.
int _patternScore(TransliterationMode mode) => _editScore(460, mode);

/// Maps an [OrthographicEdit.rank] to an intelligent-mode score.
///
/// Every value stays under the plain phonetic score of 500, so an unknown
/// name keeps the letters that were typed. A dictionary entry still wins.
int _editRankScore(int rank) => switch (rank) {
      1 => 492,
      2 => 488,
      3 => 465,
      4 => 455,
      _ => 450,
    };

/// Strong informal evidence: above the typed reading in intelligent mode,
/// still under phonetic-mode's typed reading and under standard-mode anusvara.
int _strongScore(int intelligent, TransliterationMode mode) => switch (mode) {
      TransliterationMode.phonetic => 330,
      TransliterationMode.standard => 490,
      TransliterationMode.intelligent => intelligent,
    };

int _editScore(int intelligent, TransliterationMode mode) => switch (mode) {
      TransliterationMode.phonetic => intelligent - 150,
      TransliterationMode.standard => intelligent - 170,
      TransliterationMode.intelligent => intelligent,
    };

int _dictionaryScore(int frequency, TransliterationMode mode) {
  final freq = frequency.clamp(1, 100);
  final base = (5500 + 40 * freq) ~/ 10;
  return switch (mode) {
    TransliterationMode.phonetic => base * 85 ~/ 100,
    TransliterationMode.standard => base + 80 > 980 ? 980 : base + 80,
    TransliterationMode.intelligent => base > 950 ? 950 : base,
  };
}

int _priority(SuggestionSource source) => switch (source) {
      SuggestionSource.correction => 6,
      SuggestionSource.custom => 5,
      SuggestionSource.context => 4,
      SuggestionSource.dictionary => 3,
      SuggestionSource.orthographic => 2,
      SuggestionSource.phonetic => 1,
    };
