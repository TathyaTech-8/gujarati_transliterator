import 'dart:io';
import 'dart:math' as math;

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  test('the checked corpus meets the accuracy bar', () {
    final verified = [
      ..._read('test/corpus/verified_pairs.tsv'),
      ..._read('test/corpus/phrases.tsv'),
    ];
    final rules = _read('test/corpus/rule_pairs.tsv');
    final alternates = _read('test/corpus/alternate_spellings.tsv');
    expect(verified.length + rules.length, greaterThanOrEqualTo(1000));
    expect(verified.where((row) => row.origin == 'verified'), isNotEmpty);
    expect(rules.every((row) => row.origin == 'rule'), isTrue);

    final intelligent = GujaratiTransliterator();
    final phoneticOnly = GujaratiTransliterator(dictionary: WordDictionary());
    final learned =
        _score(intelligent, verified, TransliterationMode.intelligent);
    final letters = _score(
      phoneticOnly,
      verified,
      TransliterationMode.phonetic,
    );
    final structural = _score(intelligent, rules, TransliterationMode.phonetic);
    final names = _score(
      intelligent,
      verified
          .where((row) => row.category == 'name' || row.category == 'place'),
      TransliterationMode.intelligent,
    );

    stdout.writeln(
      'CORPUS verified=${verified.length} rule=${rules.length} '
      'total=${verified.length + rules.length} alternates=${alternates.length}',
    );
    stdout.writeln(
      'ACCURACY intelligent_top1=${learned.top1.toStringAsFixed(3)} '
      'intelligent_top3=${learned.top3.toStringAsFixed(3)} '
      'intelligent_words=${learned.words.toStringAsFixed(3)} '
      'intelligent_cer=${learned.cer.toStringAsFixed(3)} '
      'proper_noun_top1=${names.top1.toStringAsFixed(3)} '
      'phonetic_only_top1=${letters.top1.toStringAsFixed(3)} '
      'phonetic_only_cer=${letters.cer.toStringAsFixed(3)} '
      'rule_top1=${structural.top1.toStringAsFixed(3)}',
    );

    expect(learned.top1, 1);
    expect(learned.top3, 1);
    expect(learned.words, 1);
    expect(learned.cer, 0);
    expect(names.top1, 1);
    expect(structural.top1, 1);
    expect(letters.top1, lessThan(1));

    for (final row in alternates) {
      final suggestions = intelligent.suggest(
        row.roman,
        limit: 20,
      );
      expect(
        suggestions.map((item) => item.text),
        contains(row.gujarati),
        reason: row.roman,
      );
      expect(suggestions.first.text, isNot(row.gujarati), reason: row.roman);
    }

    final kinds = <String, int>{};
    for (final entry in intelligent.dictionary.entries) {
      kinds[entry.kind.name] = (kinds[entry.kind.name] ?? 0) + 1;
    }
    stdout.writeln(
      'LEXICON entries=${intelligent.dictionary.entries.length} $kinds',
    );
  });
}

class _Row {
  const _Row(this.origin, this.roman, this.gujarati, this.category);

  final String origin;
  final String roman;
  final String gujarati;
  final String category;
}

class _Score {
  const _Score(this.top1, this.top3, this.words, this.cer);

  final double top1;
  final double top3;
  final double words;
  final double cer;
}

List<_Row> _read(String path) {
  final rows = <_Row>[];
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('\t');
    if (parts.length != 4) {
      throw FormatException('Bad corpus row in $path: $trimmed');
    }
    rows.add(_Row(parts[0], parts[1], parts[2], parts[3]));
  }
  return rows;
}

_Score _score(
  GujaratiTransliterator engine,
  Iterable<_Row> rows,
  TransliterationMode mode,
) {
  final list = rows.toList();
  if (list.isEmpty) return const _Score(1, 1, 1, 0);
  var top1 = 0;
  var top3 = 0;
  var wordHits = 0;
  var wordTotal = 0;
  var edits = 0;
  var chars = 0;
  for (final row in list) {
    final result = engine.transliterate(row.roman, mode: mode);
    final suggestions = engine.suggest(row.roman, mode: mode, limit: 3);
    if (result.text == row.gujarati) top1++;
    if (suggestions.any((item) => item.text == row.gujarati)) top3++;
    final expectedWords = _words(row.gujarati);
    final actualWords = _words(result.text);
    final compared = math.max(expectedWords.length, actualWords.length);
    wordTotal += compared;
    for (var i = 0; i < compared; i++) {
      final expected = i < expectedWords.length ? expectedWords[i] : '';
      final actual = i < actualWords.length ? actualWords[i] : '';
      if (expected == actual) wordHits++;
    }
    final expectedRunes = row.gujarati.runes.toList();
    edits += _levenshtein(expectedRunes, result.text.runes.toList());
    chars += math.max(expectedRunes.length, 1);
  }
  final count = list.length;
  return _Score(
    top1 / count,
    top3 / count,
    wordHits / wordTotal,
    edits / chars,
  );
}

List<String> _words(String text) {
  return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
}

int _levenshtein(List<int> left, List<int> right) {
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;
  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 0; i < left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < right.length; j++) {
      final cost = left[i] == right[j] ? 0 : 1;
      final insert = current[j] + 1;
      final delete = previous[j + 1] + 1;
      final replace = previous[j] + cost;
      current[j + 1] = math.min(insert, math.min(delete, replace));
    }
    previous = current;
  }
  return previous.last;
}
