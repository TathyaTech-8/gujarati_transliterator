import '../dictionary/builtin_lexicon.dart';
import '../dictionary/custom_dictionary.dart';
import '../dictionary/vocabulary_store.dart';
import '../dictionary/word_dictionary.dart';
import '../models/custom_entry.dart';
import '../models/suggestion.dart';
import '../models/transliteration_mode.dart';
import '../models/transliteration_result.dart';
import '../utils/input_normalizer.dart';
import 'candidate_resolver.dart';
import 'english_guard.dart';
import 'phonetic_parser.dart';

part 'incremental_session.dart';

/// Offline English-to-Gujarati transliterator.
///
/// The engine is pure Dart. It does not need Flutter, a font, or a network
/// connection. Intelligent mode is the default: pronunciation, the built-in
/// lexicon, and the previous word are scored together.
///
/// Custom mappings stay in the [VocabularyStore] you supply. They are not
/// written into the shared lexicon. Use [GujaratiTransliterator.open] when the
/// store loads asynchronously.
class GujaratiTransliterator {
  /// Creates an engine. A memory store is used when [store] is omitted.
  ///
  /// A [MemoryVocabularyStore] is loaded immediately. Call [load] or [open]
  /// before reading a file-backed store.
  GujaratiTransliterator({VocabularyStore? store, WordDictionary? dictionary})
      : this._(store ?? MemoryVocabularyStore(),
            dictionary ?? createBuiltinDictionary());

  GujaratiTransliterator._(VocabularyStore store, this.dictionary)
      : _store = store,
        _custom = CustomDictionary(),
        _parser = PhoneticParser() {
    _resolver = CandidateResolver(
      parser: _parser,
      dictionary: dictionary,
      custom: _custom,
    );
    if (store is MemoryVocabularyStore) {
      _custom.replaceAll(store.peek());
      _loaded = true;
    }
  }

  /// Loads [store] and returns an engine that already knows its saved words.
  static Future<GujaratiTransliterator> open({
    VocabularyStore? store,
    WordDictionary? dictionary,
  }) async {
    final engine = GujaratiTransliterator(store: store, dictionary: dictionary);
    await engine.load();
    return engine;
  }

  final VocabularyStore _store;

  /// Built-in lexicon plus any entries added for this engine.
  final WordDictionary dictionary;

  final CustomDictionary _custom;
  final PhoneticParser _parser;
  late final CandidateResolver _resolver;
  bool _loaded = false;
  Future<void> _queue = Future<void>.value();

  /// Whether [load] has finished. Memory stores start loaded.
  bool get isLoaded => _loaded;

  /// Saved custom entries currently held in memory.
  List<CustomEntry> get customEntries => _custom.entries;

  /// Reads the store into memory. Safe to call more than once.
  Future<void> load() async {
    _custom.replaceAll(await _store.load());
    _loaded = true;
  }

  /// Transliterates [input]. Word spacing, numbers, and punctuation stay put.
  TransliterationResult transliterate(
    String input, {
    TransliterationMode mode = TransliterationMode.intelligent,
  }) {
    return _render(input, mode: mode);
  }

  /// Ranked readings of [input]. The first item matches [transliterate].
  List<Suggestion> suggest(
    String input, {
    TransliterationMode mode = TransliterationMode.intelligent,
    int limit = 8,
  }) {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
    return transliterate(input, mode: mode).suggestions.take(limit).toList();
  }

  /// Saves a mapping that outranks the built-in lexicon when [prefer] is true.
  Future<void> addCustomMapping(
    String input,
    String gujarati, {
    bool prefer = true,
  }) {
    return _saveMapping(
      input,
      gujarati,
      prefer: prefer,
      origin: CustomOrigin.custom,
      increment: false,
    );
  }

  /// Saves a user's correction locally and prefers it next time.
  ///
  /// The built-in lexicon is left unchanged, and the old reading remains
  /// available as a lower suggestion.
  Future<void> addCorrection(String input, String corrected) {
    return _saveMapping(
      input,
      corrected,
      prefer: true,
      origin: CustomOrigin.correction,
      increment: true,
    );
  }

  /// Remembers that the user picked [chosen] for [input].
  Future<void> learnSelection(String input, String chosen) {
    return addCorrection(input, chosen);
  }

  /// Forgets every custom spelling saved for [input].
  Future<void> removeCustomMapping(String input) async {
    if (normalizeMappingKey(input).isEmpty) {
      throw ArgumentError.value(
        input,
        'input',
        'must contain at least one word',
      );
    }
    if (!_loaded) await load();
    _custom.remove(input);
    await _persist();
  }

  /// JSON document for the saved vocabulary.
  Future<String> exportVocabulary() async {
    if (!_loaded) await load();
    return VocabularyCodec.encode(_custom.entries);
  }

  /// Loads a document from [exportVocabulary].
  ///
  /// When [replace] is false, entries are merged. When it is true, the saved
  /// set is replaced.
  Future<void> importVocabulary(String json, {bool replace = false}) async {
    if (!_loaded) await load();
    final entries = VocabularyCodec.decode(json);
    if (replace) {
      _custom.replaceAll(entries);
    } else {
      for (final entry in entries) {
        _custom.upsert(entry);
      }
    }
    await _persist();
  }

  /// Starts a typing session that keeps completed words stable.
  IncrementalSession startSession({
    TransliterationMode mode = TransliterationMode.intelligent,
  }) {
    return IncrementalSession._(this, mode);
  }

  Future<void> _saveMapping(
    String input,
    String gujarati, {
    required bool prefer,
    required CustomOrigin origin,
    required bool increment,
  }) async {
    _checkMapping(input, gujarati);
    if (!_loaded) await load();
    var updatedAt = DateTime.now().toUtc();
    for (final entry in _custom.lookup(input)) {
      final previous = entry.updatedAt;
      if (previous != null && !updatedAt.isAfter(previous)) {
        updatedAt = previous.add(const Duration(milliseconds: 1));
      }
    }
    _custom.upsert(
      CustomEntry(
        input: input,
        output: gujarati.trim(),
        prefer: prefer,
        origin: origin,
        hits: 1,
        updatedAt: updatedAt,
      ),
      incrementHits: increment,
    );
    await _persist();
  }

  void _checkMapping(String input, String gujarati) {
    if (normalizeMappingKey(input).isEmpty) {
      throw ArgumentError.value(
        input,
        'input',
        'must contain at least one word',
      );
    }
    if (gujarati.trim().isEmpty) {
      throw ArgumentError.value(gujarati, 'gujarati', 'must not be empty');
    }
  }

  Future<void> _persist() {
    final snapshot = List<CustomEntry>.of(_custom.entries);
    final result = _queue.then((_) => _store.save(snapshot));
    _queue = result.catchError((Object _) {});
    return result;
  }

  TransliterationResult _render(
    String input, {
    required TransliterationMode mode,
    _CommitMemory? memory,
  }) {
    memory?.begin();
    final tokens = InputNormalizer.tokenize(input);
    final wordAt = <int>[
      for (var i = 0; i < tokens.length; i++)
        if (tokens[i].type == SpanType.word) i,
    ];
    final words = _InputWords(tokens, wordAt);
    final liveTail = tokens.isNotEmpty && tokens.last.type == SpanType.word;
    bool committedAt(int index) => index < words.length - 1 || !liveTail;
    final english = mode != TransliterationMode.phonetic &&
        EnglishGuard.isEnglishSentence(dictionary, [
          for (final index in wordAt) tokens[index].text,
        ]);

    final spans = <TransliteratedSpan>[];
    var wordIndex = 0;
    var tokenIndex = 0;
    while (tokenIndex < tokens.length) {
      final token = tokens[tokenIndex];
      if (token.type != SpanType.word) {
        spans.add(TransliteratedSpan.literal(token.text, token.type));
        tokenIndex++;
        continue;
      }

      final multi = _takeMulti(memory, words, wordIndex, committedAt);
      if (multi != null) {
        spans.add(multi.span);
        wordIndex += multi.wordCount;
        tokenIndex = words.wordAt[wordIndex - 1] + 1;
        continue;
      }

      if (committedAt(wordIndex)) {
        final reused = memory?.takeSingle(token.text);
        if (reused != null) {
          spans.add(reused);
          wordIndex++;
          tokenIndex++;
          continue;
        }
      }

      final forward = english ? null : _findPhrase(words, wordIndex, mode);
      if (forward != null &&
          !_blocked(memory, words, wordIndex, forward.wordCount, committedAt)) {
        tokenIndex = _emitPhrase(
          words: words,
          spans: spans,
          phrase: forward,
          wordIndex: wordIndex,
          mode: mode,
          memory: memory,
          committedAt: committedAt,
        );
        wordIndex += forward.wordCount;
        continue;
      }

      final preferred = _custom.lookup(token.text).any((entry) => entry.prefer);
      final keepLatin = english && !preferred;
      final backward =
          keepLatin ? null : _phraseEndingAt(words, wordIndex, mode);
      final suggestions = _resolver.resolve(
        word: token.text,
        mode: mode,
        previous: _previousOutput(spans),
        next: wordIndex + 1 < words.length ? words[wordIndex + 1] : null,
      );
      final ranked = backward == null || backward.parts == null
          ? suggestions
          : _choose(
              suggestions,
              backward.partFor(wordIndex),
              backward.score,
              backward.source,
            );
      final chosen = keepLatin ? _latinFirst(token.text, ranked) : ranked;
      final span = TransliteratedSpan(
        input: token.text,
        output: chosen.first.text,
        type: SpanType.word,
        committed: committedAt(wordIndex),
        suggestions: chosen,
      );
      spans.add(span);
      if (span.committed) {
        memory?.remember(words.key(wordIndex), 1, span);
      }
      wordIndex++;
      tokenIndex++;
    }

    memory?.commit();
    final text = spans.map((span) => span.output).join();
    return TransliterationResult(
      input: input,
      text: text,
      mode: mode,
      spans: List.unmodifiable(spans),
      suggestions: List.unmodifiable(_packageSuggestions(spans, text)),
    );
  }

  List<Suggestion> _latinFirst(String original, List<Suggestion> gujarati) {
    final rest = <Suggestion>[
      for (final item in gujarati)
        if (item.text != original) item,
    ];
    final ranked = <Suggestion>[
      Suggestion(
        text: original,
        confidence: 0.97,
        source: SuggestionSource.phonetic,
        rank: 1,
      ),
      ...rest,
    ];
    return [
      for (var i = 0; i < ranked.length; i++)
        Suggestion(
          text: ranked[i].text,
          confidence: i == 0 ? 0.97 : ranked[i].confidence,
          source: ranked[i].source,
          rank: i + 1,
          weight: ranked[i].weight,
        ),
    ];
  }

  _Reuse? _takeMulti(
    _CommitMemory? memory,
    _InputWords words,
    int wordIndex,
    bool Function(int index) committedAt,
  ) {
    if (memory == null) return null;
    final remaining = words.length - wordIndex;
    final max = remaining > 6 ? 6 : remaining;
    for (var count = max; count >= 2; count--) {
      if (!committedAt(wordIndex + count - 1)) continue;
      final key = words.phraseKey(wordIndex, count);
      if (!memory.wouldReuseMulti(key, count)) continue;
      final span = memory.takeMulti(
        raw: words.raw(wordIndex, count),
        matchKey: key,
        wordCount: count,
      );
      if (span != null) return _Reuse(span, count);
    }
    return null;
  }

  bool _blocked(
    _CommitMemory? memory,
    _InputWords words,
    int wordIndex,
    int count,
    bool Function(int index) committedAt,
  ) {
    if (memory == null) return false;
    for (var offset = 1; offset < count; offset++) {
      final index = wordIndex + offset;
      if (!committedAt(index)) continue;
      if (memory.wouldReuseSingle(words[index])) return true;
    }
    return false;
  }

  int _emitPhrase({
    required _InputWords words,
    required List<TransliteratedSpan> spans,
    required _PhraseHit phrase,
    required int wordIndex,
    required TransliterationMode mode,
    required _CommitMemory? memory,
    required bool Function(int index) committedAt,
  }) {
    final parts = phrase.parts;
    if (parts != null) {
      for (var offset = 0; offset < phrase.wordCount; offset++) {
        final index = wordIndex + offset;
        if (offset > 0) {
          final from = words.wordAt[index - 1] + 1;
          final to = words.wordAt[index];
          for (var tokenIndex = from; tokenIndex < to; tokenIndex++) {
            final token = words.tokens[tokenIndex];
            spans.add(TransliteratedSpan.literal(token.text, token.type));
          }
        }
        final suggestions = _choose(
          _resolver.resolve(
            word: words[index],
            mode: mode,
            previous: _previousOutput(spans),
            next: index + 1 < words.length ? words[index + 1] : null,
          ),
          parts[offset],
          phrase.score,
          phrase.source,
        );
        final span = TransliteratedSpan(
          input: words[index],
          output: parts[offset],
          type: SpanType.word,
          committed: committedAt(index),
          suggestions: suggestions,
        );
        spans.add(span);
        if (span.committed) memory?.remember(words.key(index), 1, span);
      }
    } else {
      final end = wordIndex + phrase.wordCount - 1;
      final span = TransliteratedSpan(
        input: words.raw(wordIndex, phrase.wordCount),
        output: phrase.gujarati,
        type: SpanType.word,
        committed: committedAt(end),
        suggestions: _choose(
          const [],
          phrase.gujarati,
          phrase.score,
          phrase.source,
        ),
      );
      spans.add(span);
      if (span.committed) {
        memory?.remember(
          words.phraseKey(wordIndex, phrase.wordCount),
          phrase.wordCount,
          span,
        );
      }
    }
    return words.wordAt[wordIndex + phrase.wordCount - 1] + 1;
  }

  _PhraseHit? _findPhrase(
    _InputWords words,
    int start,
    TransliterationMode mode, {
    int? exactLength,
  }) {
    final available = words.length - start;
    if (available < 2) return null;
    if (exactLength != null && (exactLength < 2 || exactLength > available)) {
      return null;
    }
    final max = exactLength ?? (available > 6 ? 6 : available);
    final lengths = exactLength == null
        ? [for (var length = max; length >= 2; length--) length]
        : <int>[exactLength];

    for (final length in lengths) {
      final custom = _bestCustom(words, start, length, mode);
      if (custom != null && custom.entry.prefer) {
        return _hitFromCustom(start, length, custom.entry, mode);
      }
    }
    if (mode == TransliterationMode.phonetic) return null;

    for (final length in lengths) {
      if (_anyPreferredWord(words, start, length)) continue;
      final custom = _bestCustom(words, start, length, mode);
      if (custom != null) {
        return _hitFromCustom(start, length, custom.entry, mode);
      }
      final builtin = _bestBuiltin(words, start, length);
      if (builtin != null) {
        return _hitFromBuiltin(start, length, builtin, mode);
      }
    }
    return null;
  }

  _PhraseHit? _phraseEndingAt(
    _InputWords words,
    int wordIndex,
    TransliterationMode mode,
  ) {
    final earliest = wordIndex - 5 < 0 ? 0 : wordIndex - 5;
    _PhraseHit? best;
    for (var start = wordIndex - 1; start >= earliest; start--) {
      final phrase = _findPhrase(
        words,
        start,
        mode,
        exactLength: wordIndex - start + 1,
      );
      if (phrase != null && phrase.parts != null) best = phrase;
    }
    return best;
  }

  bool _anyPreferredWord(_InputWords words, int start, int length) {
    for (var offset = 0; offset < length; offset++) {
      final preferred =
          _custom.lookup(words[start + offset]).any((entry) => entry.prefer);
      if (preferred) return true;
    }
    return false;
  }

  _RankedCustom? _bestCustom(
    _InputWords words,
    int start,
    int length,
    TransliterationMode mode,
  ) {
    final entries = _custom.lookup(words.phraseKey(start, length));
    final best = _resolver.bestCustom(entries, mode);
    if (best == null) return null;
    return _RankedCustom(best);
  }

  DictionaryEntry? _bestBuiltin(_InputWords words, int start, int length) {
    final entries = dictionary.lookupPhrase(words.phraseKey(start, length));
    if (entries.isEmpty) return null;
    DictionaryEntry best = entries.first;
    for (final entry in entries.skip(1)) {
      if (entry.frequency > best.frequency) best = entry;
      if (entry.frequency == best.frequency &&
          entry.gujarati.compareTo(best.gujarati) < 0) {
        best = entry;
      }
    }
    return best;
  }

  _PhraseHit _hitFromCustom(
    int start,
    int length,
    CustomEntry entry,
    TransliterationMode mode,
  ) {
    return _PhraseHit(
      start: start,
      wordCount: length,
      gujarati: entry.output,
      score: _resolver.customScore(entry, mode),
      source: entry.origin == CustomOrigin.correction
          ? SuggestionSource.correction
          : SuggestionSource.custom,
    );
  }

  _PhraseHit _hitFromBuiltin(
    int start,
    int length,
    DictionaryEntry entry,
    TransliterationMode mode,
  ) {
    final boosted = _resolver.dictionaryScore(entry.frequency, mode) + 40;
    return _PhraseHit(
      start: start,
      wordCount: length,
      gujarati: entry.gujarati,
      score: boosted > 990 ? 990 : boosted,
      source: SuggestionSource.dictionary,
    );
  }
}

class _InputWords {
  _InputWords(this.tokens, this.wordAt);

  final List<InputToken> tokens;
  final List<int> wordAt;

  int get length => wordAt.length;

  String operator [](int index) => tokens[wordAt[index]].text;

  String key(int index) => dictionaryKey(this[index]);

  String phraseKey(int start, int count) {
    return [for (var i = 0; i < count; i++) key(start + i)].join(' ');
  }

  String raw(int start, int count) {
    final from = wordAt[start];
    final to = wordAt[start + count - 1];
    return tokens.sublist(from, to + 1).map((token) => token.text).join();
  }
}

class _PhraseHit {
  _PhraseHit({
    required this.start,
    required this.wordCount,
    required this.gujarati,
    required this.score,
    required this.source,
  }) : parts = _partsOf(gujarati, wordCount);

  final int start;
  final int wordCount;
  final String gujarati;
  final int score;
  final SuggestionSource source;
  final List<String>? parts;

  String partFor(int wordIndex) {
    final pieces = parts;
    if (pieces == null) return gujarati;
    return pieces[wordIndex - start];
  }

  static List<String>? _partsOf(String gujarati, int wordCount) {
    final pieces = gujarati.split(' ');
    if (pieces.length != wordCount || pieces.any((piece) => piece.isEmpty)) {
      return null;
    }
    return pieces;
  }
}

class _RankedCustom {
  _RankedCustom(this.entry);
  final CustomEntry entry;
}

class _Reuse {
  _Reuse(this.span, this.wordCount);
  final TransliteratedSpan span;
  final int wordCount;
}

class _Frozen {
  _Frozen(
      {required this.matchKey, required this.wordCount, required this.span});

  final String matchKey;
  final int wordCount;
  final TransliteratedSpan span;
}

class _CommitMemory {
  final List<_Frozen> _previous = [];
  final List<_Frozen> _built = [];
  var _cursor = 0;

  void begin() {
    _cursor = 0;
    _built.clear();
  }

  void commit() {
    _previous
      ..clear()
      ..addAll(_built);
  }

  void clear() {
    _previous.clear();
    _built.clear();
    _cursor = 0;
  }

  bool wouldReuseSingle(String raw) {
    final key = dictionaryKey(raw);
    return _indexWhere(
          (item) => item.wordCount == 1 && item.matchKey == key,
        ) >=
        0;
  }

  bool wouldReuseMulti(String matchKey, int wordCount) {
    return _indexWhere(
          (item) => item.wordCount == wordCount && item.matchKey == matchKey,
        ) >=
        0;
  }

  TransliteratedSpan? takeSingle(String raw) {
    final key = dictionaryKey(raw);
    final index = _indexWhere(
      (item) => item.wordCount == 1 && item.matchKey == key,
    );
    if (index < 0) return null;
    return _consume(index, raw);
  }

  TransliteratedSpan? takeMulti({
    required String raw,
    required String matchKey,
    required int wordCount,
  }) {
    final index = _indexWhere(
      (item) => item.wordCount == wordCount && item.matchKey == matchKey,
    );
    if (index < 0) return null;
    return _consume(index, raw);
  }

  void remember(String matchKey, int wordCount, TransliteratedSpan span) {
    _built.add(
      _Frozen(matchKey: matchKey, wordCount: wordCount, span: span),
    );
  }

  TransliteratedSpan _consume(int index, String raw) {
    final item = _previous[index];
    _cursor = index + 1;
    _built.add(item);
    return TransliteratedSpan(
      input: raw,
      output: item.span.output,
      type: SpanType.word,
      committed: true,
      suggestions: item.span.suggestions,
    );
  }

  int _indexWhere(bool Function(_Frozen item) test) {
    final limit = _cursor + 6;
    for (var index = _cursor;
        index < _previous.length && index < limit;
        index++) {
      if (test(_previous[index])) return index;
    }
    return -1;
  }
}

List<Suggestion> _choose(
  List<Suggestion> suggestions,
  String output,
  int score,
  SuggestionSource source,
) {
  if (suggestions.isNotEmpty && suggestions.first.text == output) {
    return suggestions;
  }
  final top = suggestions.isEmpty
      ? score
      : (suggestions.first.confidence * 1000).round();
  final chosen = score > top ? score : top;
  final rest = suggestions.where((item) => item.text != output);
  final pinned = Suggestion(
    text: output,
    confidence: chosen / 1000,
    source: source,
    rank: 1,
  );
  final all = <Suggestion>[pinned, ...rest];
  return [
    for (var i = 0; i < all.length; i++)
      Suggestion(
        text: all[i].text,
        confidence: all[i].confidence,
        source: all[i].source,
        rank: i + 1,
        weight: all[i].weight,
      ),
  ];
}

String? _previousOutput(List<TransliteratedSpan> spans) {
  for (var i = spans.length - 1; i >= 0; i--) {
    if (spans[i].type == SpanType.word && spans[i].output.isNotEmpty) {
      return spans[i].output;
    }
  }
  return null;
}

List<Suggestion> _packageSuggestions(
  List<TransliteratedSpan> spans,
  String text,
) {
  final words = spans.where((span) => span.type == SpanType.word).toList();
  if (words.isEmpty) return const [];
  if (spans.length == 1 && spans.first.type == SpanType.word) {
    return spans.first.suggestions;
  }

  var primaryScore = 1.0;
  for (final word in words) {
    if (word.suggestions.isEmpty) continue;
    final confidence = word.suggestions.first.confidence;
    if (confidence < primaryScore) primaryScore = confidence;
  }
  final primarySource = words.last.suggestions.isEmpty
      ? SuggestionSource.phonetic
      : words.last.suggestions.first.source;
  final ordered = <Suggestion>[
    Suggestion(
      text: text,
      confidence: primaryScore,
      source: primarySource,
      rank: 1,
    ),
  ];
  final seen = <String>{text};
  final outputs = [for (final span in spans) span.output];
  final extras = <Suggestion>[];
  for (var i = 0; i < spans.length; i++) {
    final span = spans[i];
    if (span.type != SpanType.word) continue;
    for (final alternative in span.suggestions.skip(1)) {
      final copy = [...outputs];
      copy[i] = alternative.text;
      final candidate = copy.join();
      if (!seen.add(candidate)) continue;
      extras.add(
        Suggestion(
          text: candidate,
          confidence: alternative.confidence,
          source: alternative.source,
          rank: 0,
          weight: alternative.weight,
        ),
      );
    }
  }
  extras.sort((a, b) {
    final byScore = b.confidence.compareTo(a.confidence);
    if (byScore != 0) return byScore;
    return a.text.compareTo(b.text);
  });
  for (final extra in extras) {
    if (ordered.length == 16) break;
    ordered.add(extra);
  }
  return [
    for (var i = 0; i < ordered.length; i++)
      Suggestion(
        text: ordered[i].text,
        confidence: ordered[i].confidence,
        source: ordered[i].source,
        rank: i + 1,
        weight: ordered[i].weight,
      ),
  ];
}
