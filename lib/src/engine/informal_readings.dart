import '../dictionary/word_dictionary.dart';
import '../models/suggestion.dart';
import '../utils/input_normalizer.dart';
import '../utils/unicode_utils.dart';
import 'name_reading.dart';
import 'phonetic_parser.dart';

/// One extra reading of an informal roman word.
class InformalReading {
  /// Creates a reading.
  const InformalReading({
    required this.text,
    required this.score,
    required this.strong,
    required this.source,
  });

  /// Gujarati spelling.
  final String text;

  /// Intelligent-mode score in thousandths. Strong readings sit above the
  /// plain phonetic score of 500 and below a freq-1 dictionary score of 554
  /// only when [score] is 530. Lexicon bridges use 560 or 620 and are added
  /// only when the typed key itself is absent, so they cannot hide an exact
  /// entry.
  final int score;

  /// Whether intelligent mode may rank this ahead of the typed reading.
  final bool strong;

  /// Why this reading was produced.
  final SuggestionSource source;
}

/// Bounded alternate readings for roman text that does not follow the scheme.
///
/// Lookups are hash probes of a handful of edited keys. The method never
/// walks the lexicon. Consonant-class changes (શ/સ, ચ/છ, aspiration) stay
/// weak suggestions so a real pronunciation difference is not erased.
abstract final class InformalReadings {
  /// Readings for one already-parsed word.
  static List<InformalReading> generate({
    required PhoneticParser parser,
    required WordDictionary dictionary,
    required String original,
    required String prepared,
    required String literal,
    String? nextRoman,
  }) {
    if (prepared.isEmpty || literal.isEmpty || prepared.length > 32) {
      return const [];
    }
    final readings = <InformalReading>[];
    final seen = <String>{literal};

    void add(InformalReading? reading) {
      if (reading == null || reading.text.isEmpty || !seen.add(reading.text)) {
        return;
      }
      readings.add(reading);
    }

    add(_dative(parser, prepared));
    add(_aapPossessive(parser, prepared));
    add(_firstPerson(dictionary, original, prepared, literal, nextRoman));
    add(_nameCompound(parser, dictionary, prepared, literal));

    if (dictionary.lookupWord(prepared).isEmpty) {
      final bridge = _lexiconBridge(dictionary, prepared, literal);
      if (bridge != null) add(bridge);
    }

    for (final reading in _weakAlternates(parser, prepared, literal)) {
      add(reading);
    }
    return readings;
  }
}

InformalReading? _dative(PhoneticParser parser, String prepared) {
  const keys = <String, String>{
    'mare': 'maare',
    'tare': 'taare',
    'amare': 'amaare',
    'tamare': 'tamaare',
  };
  final alternate = keys[prepared];
  if (alternate == null) return null;
  return InformalReading(
    text: parser.parse(alternate),
    score: 530,
    strong: true,
    source: SuggestionSource.orthographic,
  );
}

InformalReading? _aapPossessive(PhoneticParser parser, String prepared) {
  const keys = <String, String>{
    'aapnu': 'aapa.nu.m',
    'aapni': 'aapa.ni',
    'aapno': 'aapa.no',
    'aapde': 'aapa.ne',
  };
  final alternate = keys[prepared];
  if (alternate == null) return null;
  return InformalReading(
    text: parser.parse(alternate),
    score: 530,
    strong: true,
    source: SuggestionSource.orthographic,
  );
}

InformalReading? _firstPerson(
  WordDictionary dictionary,
  String original,
  String prepared,
  String literal,
  String? nextRoman,
) {
  final runes = literal.runes.toList(growable: false);
  if (runes.isEmpty || runes.last != 0x0AC1) return null;
  final nasal = '$literal${GujaratiUnicode.anusvara}';
  final next = nextRoman == null ? '' : dictionaryKey(nextRoman);
  const auxiliaries = {'chu', 'chhu', 'chhun', 'chum'};
  final strong = auxiliaries.contains(next) &&
      !_titleCase(original) &&
      !_stemIsNameOrPlace(dictionary, prepared);
  return InformalReading(
    text: nasal,
    score: strong ? 530 : 448,
    strong: strong,
    source: strong ? SuggestionSource.context : SuggestionSource.orthographic,
  );
}

bool _titleCase(String word) {
  if (word.length < 2) return false;
  final rest = word.substring(1);
  return word[0].toUpperCase() == word[0] &&
      word[0].toLowerCase() != word[0] &&
      rest == rest.toLowerCase();
}

/// A typed name made of known parts, or an unfamiliar stem plus one.
InformalReading? _nameCompound(
  PhoneticParser parser,
  WordDictionary dictionary,
  String prepared,
  String literal,
) {
  final text = readName(
    parser: parser,
    dictionary: dictionary,
    prepared: prepared,
  );
  if (text == null || text.isEmpty || text == literal) return null;
  return InformalReading(
    text: text,
    score: 546,
    strong: true,
    source: SuggestionSource.orthographic,
  );
}

bool _stemIsNameOrPlace(WordDictionary dictionary, String prepared) {
  if (prepared.length < 2 || !prepared.endsWith('u')) return false;
  if (prepared.endsWith('uu') || prepared.endsWith('oo')) return true;
  final stem = prepared.substring(0, prepared.length - 1);
  final hits = dictionary.lookupWord(stem);
  if (hits.isEmpty) return false;
  var best = hits.first;
  for (final hit in hits) {
    if (hit.frequency > best.frequency) best = hit;
  }
  return best.kind == EntryKind.name || best.kind == EntryKind.place;
}

InformalReading? _lexiconBridge(
  WordDictionary dictionary,
  String prepared,
  String literal,
) {
  final keys = _bridgeKeys(prepared);
  String? bestText;
  var bestFrequency = 0;
  var bestDistance = 99;
  var bestKey = '';
  for (final key in keys) {
    final hits = dictionary.lookupWord(key);
    if (hits.isEmpty) continue;
    var top = hits.first;
    for (final hit in hits) {
      if (hit.frequency > top.frequency) top = hit;
    }
    if (top.frequency < 80 || top.gujarati == literal) continue;
    // One matra or one virama. A larger gap is a different word.
    final distance = _distance(literal, top.gujarati, 1);
    if (distance > 1) continue;
    final insertedSchwa = key.length == prepared.length + 1;
    if (insertedSchwa && !_matrasPreserved(literal, top.gujarati)) continue;
    final betterFrequency = top.frequency > bestFrequency;
    final clearer = top.frequency == bestFrequency &&
        (distance < bestDistance ||
            (distance == bestDistance && key.compareTo(bestKey) < 0));
    if (bestText == null || betterFrequency || clearer) {
      bestText = top.gujarati;
      bestFrequency = top.frequency;
      bestDistance = distance;
      bestKey = key;
    }
  }
  if (bestText == null) return null;
  return InformalReading(
    text: bestText,
    score: bestFrequency >= 90 ? 620 : 560,
    strong: true,
    source: SuggestionSource.dictionary,
  );
}

List<InformalReading> _weakAlternates(
  PhoneticParser parser,
  String prepared,
  String literal,
) {
  final readings = <InformalReading>[];
  for (final key in <String?>[
    _toggleCh(prepared),
    _toggleAspiration(prepared),
    _toggleN(prepared),
    _toggleSh(prepared),
    _toggleDiphthong(prepared),
  ]) {
    if (key == null || key == prepared) continue;
    final text = parser.parse(key);
    if (text == literal || text.isEmpty) continue;
    readings.add(
      InformalReading(
        text: text,
        score: 440,
        strong: false,
        source: SuggestionSource.orthographic,
      ),
    );
  }
  return readings;
}

List<String> _bridgeKeys(String prepared) {
  final tokens = _scan(prepared);
  final keys = <String>[];
  void add(String? key) {
    if (key == null || key == prepared || keys.contains(key)) return;
    keys.add(key);
  }

  for (var i = 0; i < tokens.length - 1; i++) {
    if (tokens[i].kind != _Kind.consonant) continue;
    if (tokens[i + 1].kind != _Kind.consonant) continue;
    final at = tokens[i + 1].start;
    add('${prepared.substring(0, at)}a${prepared.substring(at)}');
    break;
  }

  _Vowel? first;
  _Vowel? last;
  for (final token in tokens) {
    if (token.kind != _Kind.vowel) continue;
    final swapped = _swapVowel(token.text);
    if (swapped == null) continue;
    first ??= _Vowel(token.start, token.text.length, swapped);
    last = _Vowel(token.start, token.text.length, swapped);
  }
  if (first != null) add(first.apply(prepared));
  if (last != null && (first == null || last.start != first.start)) {
    add(last.apply(prepared));
  }
  add(_toggleDiphthong(prepared));
  return keys;
}

String? _swapVowel(String vowel) => switch (vowel) {
      'a' => 'aa',
      'aa' => 'a',
      'i' => 'ee',
      'ee' || 'ii' => 'i',
      'u' => 'oo',
      'oo' || 'uu' => 'u',
      _ => null,
    };

String? _toggleCh(String prepared) {
  final chh = prepared.indexOf('chh');
  if (chh >= 0) return prepared.replaceRange(chh, chh + 3, 'ch');
  final ch = prepared.indexOf('ch');
  if (ch >= 0) return prepared.replaceRange(ch, ch + 2, 'chh');
  return null;
}

String? _toggleAspiration(String prepared) {
  final dh = prepared.lastIndexOf('dh');
  if (dh >= 0) return prepared.replaceRange(dh, dh + 2, 'd');
  final th = prepared.lastIndexOf('th');
  if (th >= 0) return prepared.replaceRange(th, th + 2, 't');
  if (prepared.endsWith('d')) {
    return '${prepared.substring(0, prepared.length - 1)}dh';
  }
  if (prepared.endsWith('t')) {
    return '${prepared.substring(0, prepared.length - 1)}th';
  }
  return null;
}

String? _toggleN(String prepared) {
  final doubled = prepared.indexOf('nn');
  if (doubled >= 0) return prepared.replaceRange(doubled, doubled + 2, '.n');
  for (var i = prepared.length - 1; i >= 0; i--) {
    if (prepared[i] != 'n') continue;
    final next = i + 1 < prepared.length ? prepared[i + 1] : '';
    if (next == 'g' || next == 'y') continue;
    final previous = i > 0 ? prepared[i - 1] : '';
    if (previous == '.') continue;
    return '${prepared.substring(0, i)}.n${prepared.substring(i + 1)}';
  }
  return null;
}

String? _toggleSh(String prepared) {
  final sh = prepared.indexOf('sh');
  if (sh >= 0 && (sh == 0 || prepared[sh - 1] != '.')) {
    return prepared.replaceRange(sh, sh + 2, 's');
  }
  final s = prepared.indexOf('s');
  if (s >= 0) return prepared.replaceRange(s, s + 1, 'sh');
  return null;
}

String? _toggleDiphthong(String prepared) {
  final ay = prepared.indexOf('ay');
  if (ay >= 0 && (ay == 0 || prepared[ay - 1] != 'a')) {
    return prepared.replaceRange(ay, ay + 2, 'ai');
  }
  final ow = prepared.indexOf('ow');
  if (ow >= 0) return prepared.replaceRange(ow, ow + 2, 'au');
  final aw = prepared.indexOf('aw');
  if (aw > 0 && prepared[aw - 1] != 'a') {
    return prepared.replaceRange(aw, aw + 2, 'au');
  }
  return null;
}

enum _Kind { consonant, vowel }

class _Token {
  const _Token(this.kind, this.text, this.start);

  final _Kind kind;
  final String text;
  final int start;
}

class _Vowel {
  const _Vowel(this.start, this.length, this.replacement);

  final int start;
  final int length;
  final String replacement;

  String apply(String prepared) {
    return prepared.replaceRange(start, start + length, replacement);
  }
}

List<_Token> _scan(String prepared) {
  const markers = <String>[
    '.th',
    '.dh',
    '.sh',
    '.ng',
    '.ny',
    '.kh',
    '.t',
    '.d',
    '.n',
    '.l',
    '.g',
    '.f',
  ];
  const digraphs = <String>[
    'chh',
    'ksh',
    'th',
    'dh',
    'kh',
    'gh',
    'bh',
    'ph',
    'sh',
    'ch',
    'ng',
    'jn',
    'gy',
    'ny',
  ];
  const vowels = <String>[
    'aa',
    'ai',
    'au',
    'ee',
    'ii',
    'oo',
    'ou',
    'uu',
    'a',
    'e',
    'i',
    'o',
    'u',
  ];
  final tokens = <_Token>[];
  var index = 0;
  while (index < prepared.length) {
    if (prepared.startsWith('.e', index) || prepared.startsWith('.o', index)) {
      tokens.add(
          _Token(_Kind.vowel, prepared.substring(index, index + 2), index));
      index += 2;
      continue;
    }
    String? marker;
    for (final candidate in markers) {
      if (prepared.startsWith(candidate, index)) {
        marker = candidate;
        break;
      }
    }
    if (marker != null) {
      tokens.add(_Token(_Kind.consonant, marker, index));
      index += marker.length;
      continue;
    }
    if (prepared[index] == '.') {
      index++;
      continue;
    }
    String? digraph;
    for (final candidate in digraphs) {
      if (prepared.startsWith(candidate, index)) {
        digraph = candidate;
        break;
      }
    }
    if (digraph != null) {
      tokens.add(_Token(_Kind.consonant, digraph, index));
      index += digraph.length;
      continue;
    }
    String? vowel;
    for (final candidate in vowels) {
      if (prepared.startsWith(candidate, index)) {
        vowel = candidate;
        break;
      }
    }
    if (vowel != null) {
      tokens.add(_Token(_Kind.vowel, vowel, index));
      index += vowel.length;
      continue;
    }
    final unit = prepared.codeUnitAt(index);
    final letter = unit >= 0x61 && unit <= 0x7A;
    if (letter) {
      tokens.add(_Token(_Kind.consonant, prepared[index], index));
    }
    index++;
  }
  return tokens;
}

bool _matrasPreserved(String literal, String candidate) {
  final available = <int>[
    for (final rune in literal.runes)
      if (_isVowelSign(rune)) rune,
  ];
  for (final rune in candidate.runes) {
    if (!_isVowelSign(rune)) continue;
    final at = available.indexOf(rune);
    if (at < 0) return false;
    available.removeAt(at);
  }
  return true;
}

bool _isVowelSign(int rune) =>
    (rune >= 0x0ABE && rune <= 0x0AC5) ||
    (rune >= 0x0AC7 && rune <= 0x0AC9) ||
    (rune >= 0x0ACB && rune <= 0x0ACC) ||
    rune == 0x0AE2 ||
    rune == 0x0AE3;

int _distance(String left, String right, int cap) {
  final a = left.runes.toList(growable: false);
  final b = right.runes.toList(growable: false);
  if ((a.length - b.length).abs() > cap) return cap + 1;
  var previous = List<int>.generate(b.length + 1, (index) => index);
  for (var i = 0; i < a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i + 1;
    var rowMin = current[0];
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      final insert = current[j] + 1;
      final delete = previous[j + 1] + 1;
      final replace = previous[j] + cost;
      var value = insert < delete ? insert : delete;
      if (replace < value) value = replace;
      current[j + 1] = value;
      if (value < rowMin) rowMin = value;
    }
    if (rowMin > cap) return cap + 1;
    previous = current;
  }
  return previous[b.length];
}
