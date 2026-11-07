import 'dart:io';
import 'dart:math' as math;

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  test('ordinary sentences keep a standard reading available', () {
    expect(
      engine.transliterate('hu gujarati bolu chu').text,
      'હું ગુજરાતી બોલું છું',
    );
    expect(engine.transliterate('aaje bahu saru che').text, 'આજે બહુ સારું છે');
    expect(engine.transliterate('mare ghar javu che').text, 'મારે ઘર જવું છે');
    expect(engine.transliterate('tame kem cho').text, 'તમે કેમ છો');
    expect(engine.transliterate('aapnu gujarat').text, 'આપણું ગુજરાત');
    expect(engine.transliterate('ghaar').text, 'ઘર');
    expect(engine.transliterate('tme').text, 'તમે');
    expect(engine.transliterate('suurat').text, 'સુરત');
    expect(engine.transliterate('bolu chu').text, 'બોલું છું');
    expect(engine.transliterate('raju chu').text, 'રજુ છું');
    expect(engine.transliterate('aapnu').text, 'આપણું');
    expect(
      engine.transliterate('mare', mode: TransliterationMode.phonetic).text,
      'મરે',
    );
    expect(
      engine.transliterate('bolu', mode: TransliterationMode.phonetic).text,
      'બોલુ',
    );
  });

  test('suggestions stay unique and stable', () {
    const inputs = <String>[
      'Kal',
      'paani',
      'sanpa',
      'prakriya',
      'ghaar',
      'bolu chu',
      'shikshan',
      'math',
    ];
    for (final input in inputs) {
      final first = engine.suggest(input).map((item) => item.text).toList();
      final second = engine.suggest(input).map((item) => item.text).toList();
      expect(second, first, reason: input);
      expect(first.toSet().length, first.length, reason: input);
      expect(first.first, engine.transliterate(input).text, reason: input);
    }
  });

  test('a committed word is not rewritten when the next word arrives', () {
    final session = engine.startSession();
    expect(session.update('bolu ').text, 'બોલુ ');
    expect(session.update('bolu chu').text, 'બોલુ છું');
    expect(engine.transliterate('bolu chu').text, 'બોલું છું');
  });

  test('the natural roman corpus is scored by split', () {
    final rows = _read('test/corpus/natural_roman.tsv');
    expect(rows.length, greaterThanOrEqualTo(500));
    for (final split in const [
      'exact',
      'informal',
      'ambiguous',
      'proper',
      'phrase',
    ]) {
      expect(
        rows.where((row) => row.split == split).length,
        greaterThanOrEqualTo(40),
        reason: split,
      );
    }

    final stored = rows.where((row) => _stored(engine, row.roman));
    final unseen = rows.where((row) => !_stored(engine, row.roman));
    final all = _score(engine, rows);
    stdout.writeln(
      'NATURAL_PROVENANCE editor-checked standard orthography; '
      'not exported from the lexicon or the phonetic tables; '
      'no separate native-speaker panel',
    );
    stdout.writeln(
      'NATURAL n=${rows.length} stored=${stored.length} unseen=${unseen.length}',
    );
    for (final split in const [
      'exact',
      'informal',
      'ambiguous',
      'proper',
      'phrase',
    ]) {
      final subset = rows.where((row) => row.split == split);
      final score = _score(engine, subset);
      stdout.writeln(
        'NATURAL_${split.toUpperCase()} n=${subset.length} '
        'top1=${score.top1.toStringAsFixed(3)} '
        'top3=${score.top3.toStringAsFixed(3)} '
        'cer=${score.cer.toStringAsFixed(3)}',
      );
    }
    final storedScore = _score(engine, stored);
    final unseenScore = _score(engine, unseen);
    stdout.writeln(
      'NATURAL_STORED n=${stored.length} '
      'top1=${storedScore.top1.toStringAsFixed(3)} '
      'top3=${storedScore.top3.toStringAsFixed(3)} '
      'cer=${storedScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'NATURAL_UNSEEN n=${unseen.length} '
      'top1=${unseenScore.top1.toStringAsFixed(3)} '
      'top3=${unseenScore.top3.toStringAsFixed(3)} '
      'cer=${unseenScore.cer.toStringAsFixed(3)}',
    );
    const everydayNotes = <String>{
      'demo',
      'daily',
      'greeting',
      'food',
      'family',
      'weather',
      'faith',
      'festival',
      'culture',
      'place',
      'home',
      'time',
    };
    final everyday = rows.where(
      (row) => row.split == 'phrase' && everydayNotes.contains(row.note),
    );
    final mixed = rows.where(
      (row) => row.split == 'phrase' && row.note == 'mixed',
    );
    final everydayScore = _score(engine, everyday);
    final mixedScore = _score(engine, mixed);
    stdout.writeln(
      'NATURAL_PHRASE_EVERYDAY n=${everyday.length} '
      'top1=${everydayScore.top1.toStringAsFixed(3)} '
      'top3=${everydayScore.top3.toStringAsFixed(3)} '
      'cer=${everydayScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'NATURAL_PHRASE_MIXED n=${mixed.length} '
      'top1=${mixedScore.top1.toStringAsFixed(3)} '
      'top3=${mixedScore.top3.toStringAsFixed(3)} '
      'cer=${mixedScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'NATURAL_ALL top1=${all.top1.toStringAsFixed(3)} '
      'top3=${all.top3.toStringAsFixed(3)} '
      'cer=${all.cer.toStringAsFixed(3)}',
    );
    expect(all.top3, greaterThanOrEqualTo(all.top1));
  });
}

bool _stored(GujaratiTransliterator engine, String roman) {
  final words = RegExp(r"[A-Za-z.']+")
      .allMatches(roman)
      .map((match) => match.group(0)!)
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return false;
  if (words.length > 1 &&
      engine.dictionary.lookupPhrase(words.join(' ')).isNotEmpty) {
    return true;
  }
  for (final word in words) {
    if (engine.dictionary.lookupWord(word).isNotEmpty) return true;
  }
  return false;
}

List<_Row> _read(String path) {
  final rows = <_Row>[];
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('\t');
    if (parts.length < 3) {
      throw FormatException('Bad natural row: $trimmed');
    }
    rows.add(
        _Row(parts[0], parts[1], parts[2], parts.length > 3 ? parts[3] : ''));
  }
  return rows;
}

class _Row {
  const _Row(this.split, this.roman, this.gujarati, this.note);

  final String split;
  final String roman;
  final String gujarati;
  final String note;
}

class _Score {
  const _Score(this.top1, this.top3, this.cer);

  final double top1;
  final double top3;
  final double cer;
}

_Score _score(GujaratiTransliterator engine, Iterable<_Row> rows) {
  final list = rows.toList();
  if (list.isEmpty) return const _Score(1, 1, 0);
  var top1 = 0;
  var top3 = 0;
  var edits = 0;
  var chars = 0;
  for (final row in list) {
    final result = engine.transliterate(row.roman);
    final suggestions = engine.suggest(row.roman, limit: 3);
    if (result.text == row.gujarati) top1++;
    if (result.text == row.gujarati ||
        suggestions.any((item) => item.text == row.gujarati)) {
      top3++;
    }
    final expected = row.gujarati.runes.toList();
    edits += _levenshtein(expected, result.text.runes.toList());
    chars += math.max(expected.length, 1);
  }
  final count = list.length;
  return _Score(top1 / count, top3 / count, edits / chars);
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
      current[j + 1] = math.min(
        current[j] + 1,
        math.min(previous[j + 1] + 1, previous[j] + cost),
      );
    }
    previous = current;
  }
  return previous.last;
}
