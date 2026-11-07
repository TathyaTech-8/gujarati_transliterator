import 'dart:io';
import 'dart:math' as math;

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  test('the sentence corpus is scored apart from the lexicon', () {
    final rows = _read('test/corpus/sentences.tsv');
    expect(rows.length, greaterThanOrEqualTo(1000));
    final review = rows.where((row) => row.certainty == 'review').length;
    expect(review, greaterThan(0));

    final engine = GujaratiTransliterator();
    final sentence = _sentences(engine, rows);
    final words = _words(engine, rows);
    stdout.writeln(
      'SENTENCE_PROVENANCE editor-written roman and Gujarati; '
      'not exported from the lexicon; not produced by the engine; '
      'review rows are flagged for a native-speaker panel that has not been convened',
    );
    stdout.writeln(
      'SENTENCE n=${rows.length} review=$review '
      'exact=${sentence.exact.toStringAsFixed(3)} '
      'top3=${sentence.top3.toStringAsFixed(3)} '
      'cer=${sentence.cer.toStringAsFixed(3)}',
    );
    for (final note in const [
      'everyday',
      'family',
      'office',
      'business',
      'formal',
      'informal',
      'question',
      'command',
      'mixed',
      'proper',
    ]) {
      final subset = rows.where((row) => row.note == note);
      final score = _sentences(engine, subset);
      stdout.writeln(
        'SENTENCE_${note.toUpperCase()} n=${subset.length} '
        'exact=${score.exact.toStringAsFixed(3)} '
        'top3=${score.top3.toStringAsFixed(3)} '
        'cer=${score.cer.toStringAsFixed(3)}',
      );
    }
    final sure = rows.where((row) => row.certainty == 'sure');
    final sureScore = _sentences(engine, sure);
    stdout.writeln(
      'SENTENCE_SURE n=${sure.length} '
      'exact=${sureScore.exact.toStringAsFixed(3)} '
      'top3=${sureScore.top3.toStringAsFixed(3)} '
      'cer=${sureScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'WORD n=${words.total} unseen=${words.unseen} '
      'stored_top1=${words.storedTop1.toStringAsFixed(3)} '
      'unseen_top1=${words.unseenTop1.toStringAsFixed(3)} '
      'unseen_top3=${words.unseenTop3.toStringAsFixed(3)} '
      'unaligned=${words.unaligned}',
    );
    expect(sentence.top3, greaterThanOrEqualTo(sentence.exact));
    expect(words.unseenTop3, greaterThanOrEqualTo(words.unseenTop1));
  });
}

class _Row {
  const _Row(this.note, this.roman, this.gujarati, this.certainty);
  final String note;
  final String roman;
  final String gujarati;
  final String certainty;
}

class _SentenceScore {
  const _SentenceScore(this.exact, this.top3, this.cer);
  final double exact;
  final double top3;
  final double cer;
}

class _WordScore {
  const _WordScore(
    this.total,
    this.unseen,
    this.storedTop1,
    this.unseenTop1,
    this.unseenTop3,
    this.unaligned,
  );
  final int total;
  final int unseen;
  final double storedTop1;
  final double unseenTop1;
  final double unseenTop3;
  final int unaligned;
}

List<_Row> _read(String path) {
  final rows = <_Row>[];
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('\t');
    if (parts.length < 5) {
      throw FormatException('Bad sentence row: $trimmed');
    }
    rows.add(_Row(parts[3], parts[1], parts[2], parts[4]));
  }
  return rows;
}

_SentenceScore _sentences(GujaratiTransliterator engine, Iterable<_Row> rows) {
  final list = rows.toList();
  if (list.isEmpty) return const _SentenceScore(1, 1, 0);
  var exact = 0;
  var top3 = 0;
  var edits = 0;
  var chars = 0;
  for (final row in list) {
    final result = engine.transliterate(row.roman);
    final suggestions = engine.suggest(row.roman, limit: 3);
    if (result.text == row.gujarati) exact++;
    if (result.text == row.gujarati ||
        suggestions.any((item) => item.text == row.gujarati)) {
      top3++;
    }
    final expected = row.gujarati.runes.toList();
    edits += _levenshtein(expected, result.text.runes.toList());
    chars += math.max(expected.length, 1);
  }
  final count = list.length;
  return _SentenceScore(exact / count, top3 / count, edits / chars);
}

_WordScore _words(GujaratiTransliterator engine, List<_Row> rows) {
  var total = 0;
  var unseen = 0;
  var unseenHit = 0;
  var unseenTop3 = 0;
  var stored = 0;
  var storedHit = 0;
  var unaligned = 0;
  for (final row in rows) {
    final result = engine.transliterate(row.roman);
    final spans =
        result.spans.where((span) => span.type == SpanType.word).toList();
    final romanWords = row.roman.split(RegExp(r'\s+'));
    final expectedWords = row.gujarati.split(RegExp(r'\s+'));
    if (spans.length != expectedWords.length ||
        romanWords.length != expectedWords.length) {
      unaligned++;
      continue;
    }
    for (var i = 0; i < spans.length; i++) {
      total++;
      final known = engine.dictionary.lookupWord(romanWords[i]).isNotEmpty;
      final hit = spans[i].output == expectedWords[i];
      final inTop3 = hit ||
          spans[i]
              .suggestions
              .take(3)
              .any((item) => item.text == expectedWords[i]);
      if (known) {
        stored++;
        if (hit) storedHit++;
      } else {
        unseen++;
        if (hit) unseenHit++;
        if (inTop3) unseenTop3++;
      }
    }
  }
  double ratio(int hits, int count) => count == 0 ? 0 : hits / count;
  return _WordScore(
    total,
    unseen,
    ratio(storedHit, stored),
    ratio(unseenHit, unseen),
    ratio(unseenTop3, unseen),
    unaligned,
  );
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
