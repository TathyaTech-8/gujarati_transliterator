import 'dart:io';
import 'dart:math' as math;

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

/// Sandhi-free verb forms. The Gujarati is the stem spelling plus the ending
/// spelling. It is not read back from the engine.
const String _consonantStems = '''
kar|કર
bol|બોલ
lakh|લખ
raakh|રાખ
jov|જોવ
aap|આપ
samaj|સમજ
poochh|પૂછ
sheekh|શીખ
bes|બેસ
has|હસ
khel|ખેલ
bhar|ભર
bhool|ભૂલ
jaa.n|જાણ
maan|માન
pa.d|પડ
u.th|ઉઠ
soch|સોચ
kho.l|ખોળ
banaav|બનાવ
sheekhav|શીખવ
karaav|કરાવ
maang|માંગ
ban|બન
naach|નાચ
chho.d|છોડ
mokal|મોકલ
paka.d|પકડ
ughaa.d|ઉઘાડ
dhov|ધોવ
vaag|વાગ
mook|મૂક
kaa.dh|કાઢ
neeka.l|નીકળ
choom|ચૂમ
taa.n|તાણ
bhaag|ભાગ
do.d|દોડ
kood|કૂદ
tar|તર
kaap|કાપ
dekh|દેખ
baandh|બાંધ
chhaap|છાપ
rok|રોક
ghas|ઘસ
pala.t|પલટ
vaanch|વાંચ
laav|લાવ
mo.d|મોડ
ga.n|ગણ
jo.d|જોડ
foonk|ફૂંક
seench|સીંચ
raandh|રાંધ
phool|ફૂલ
sook|સૂક
ma.l|મળ
vech|વેચ
khareed|ખરીદ
bagaa.d|બગાડ
saachav|સાચવ
bach|બચ
bachaav|બચાવ
shodh|શોધ
tapaas|તપાસ
sudhaar|સુધાર
go.thav|ગોઠવ
sajaav|સજાવ
khul|ખુલ
chalaav|ચલાવ
ferav|ફેરવ
ghoom|ઘૂમ
far|ફર
tol|તોલ
bhaj|ભજ
sek|સેક
''';

const String _consonantEndings = '''
ashe|શે
asho|શો
atu.m|તું
ataa|તા
atee|તી
ato|તો
avu.m|વું
avaa|વા
aay|ાય
ataa.m|તાં
avo|વો
''';

const String _vowelStems = '''
khaa|ખા
pee|પી
le|લે
de|દે
gaa|ગા
dho|ધો
jo|જો
rahe|રહે
''';

const String _vowelEndings = '''
she|શે
sho|શો
to|તો
tee|તી
taa|તા
tu.m|તું
vu.m|વું
vaa|વા
''';

void main() {
  test('held-out Gujarati is scored apart from the lexicon', () {
    final rows = <_Row>[
      ..._generated(),
      ..._readHand('test/corpus/heldout_hand.tsv'),
    ];
    expect(rows.length, greaterThanOrEqualTo(1000));
    expect(rows.where((row) => row.tag == 'ambiguous'), isNotEmpty);

    final engine = GujaratiTransliterator();
    for (final row in rows) {
      for (final key in _keys(row.roman)) {
        expect(engine.dictionary.lookupWord(key), isEmpty, reason: key);
        expect(engine.dictionary.lookupPhrase(key), isEmpty, reason: key);
      }
    }

    final explicit = rows.where((row) => row.tag == 'explicit');
    final ambiguous = rows.where((row) => row.tag == 'ambiguous');
    final phrases = rows.where((row) => row.tag == 'phrase');
    final explicitScore = _score(engine, explicit);
    final ambiguousScore = _score(engine, ambiguous);
    final phraseScore = _score(engine, phrases);
    final all = _score(engine, rows);

    stdout.writeln(
      'VALIDATION editor-checked standard orthography; '
      'no separate native-speaker panel',
    );
    stdout.writeln(
      'HELDOUT n=${rows.length} explicit=${explicit.length} '
      'ambiguous=${ambiguous.length} phrase=${phrases.length}',
    );
    stdout.writeln(
      'HELDOUT_ALL top1=${all.top1.toStringAsFixed(3)} '
      'top3=${all.top3.toStringAsFixed(3)} '
      'words=${all.words.toStringAsFixed(3)} '
      'cer=${all.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'HELDOUT_EXPLICIT top1=${explicitScore.top1.toStringAsFixed(3)} '
      'top3=${explicitScore.top3.toStringAsFixed(3)} '
      'cer=${explicitScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'HELDOUT_AMBIGUOUS top1=${ambiguousScore.top1.toStringAsFixed(3)} '
      'top3=${ambiguousScore.top3.toStringAsFixed(3)} '
      'cer=${ambiguousScore.cer.toStringAsFixed(3)}',
    );
    stdout.writeln(
      'HELDOUT_PHRASE top1=${phraseScore.top1.toStringAsFixed(3)} '
      'top3=${phraseScore.top3.toStringAsFixed(3)} '
      'cer=${phraseScore.cer.toStringAsFixed(3)}',
    );
    if (explicitScore.misses.isNotEmpty) {
      stdout.writeln(
        'EXPLICIT_MISS ${explicitScore.misses.take(12).join(' | ')}',
      );
    }

    expect(explicitScore.top1, greaterThanOrEqualTo(0.95));
    expect(all.top3, greaterThanOrEqualTo(all.top1));
  });
}

class _Row {
  const _Row(this.tag, this.roman, this.gujarati, this.category);

  final String tag;
  final String roman;
  final String gujarati;
  final String category;
}

class _Score {
  const _Score(this.top1, this.top3, this.words, this.cer, this.misses);

  final double top1;
  final double top3;
  final double words;
  final double cer;
  final List<String> misses;
}

List<_Row> _generated() {
  final rows = <_Row>[];
  void addTable(String stems, String endings) {
    for (final stem in _table(stems)) {
      for (final ending in _table(endings)) {
        rows.add(
          _Row(
            'explicit',
            '${stem.$1}${ending.$1}',
            '${stem.$2}${ending.$2}',
            'verb',
          ),
        );
      }
    }
  }

  addTable(_consonantStems, _consonantEndings);
  addTable(_vowelStems, _vowelEndings);
  return rows;
}

List<(String, String)> _table(String source) {
  final rows = <(String, String)>[];
  for (final line in source.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split('|');
    rows.add((parts[0], parts[1]));
  }
  return rows;
}

List<_Row> _readHand(String path) {
  final rows = <_Row>[];
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('\t');
    if (parts.length != 4) {
      throw FormatException('Bad held-out row: $trimmed');
    }
    rows.add(_Row(parts[0], parts[1], parts[2], parts[3]));
  }
  return rows;
}

String _key(String word) => word.trim().toLowerCase();

Set<String> _keys(String roman) {
  final keys = <String>{};
  final words = RegExp(r'[A-Za-z.]+')
      .allMatches(roman)
      .map((match) => match.group(0)!)
      .where((word) => word.isNotEmpty)
      .toList();
  keys.addAll(words.map(_key));
  if (words.length > 1) {
    keys.add(words.map(_key).join(' '));
  }
  return keys;
}

_Score _score(GujaratiTransliterator engine, Iterable<_Row> rows) {
  final list = rows.toList();
  if (list.isEmpty) return const _Score(1, 1, 1, 0, []);
  var top1 = 0;
  var top3 = 0;
  var wordHits = 0;
  var wordTotal = 0;
  var edits = 0;
  var chars = 0;
  final misses = <String>[];
  final seen = <String>{};
  for (final row in list) {
    final result = engine.transliterate(row.roman);
    final suggestions = engine.suggest(row.roman, limit: 3);
    final hit = result.text == row.gujarati;
    if (hit) {
      top1++;
    } else {
      final stem = row.roman.replaceFirst(
        RegExp(
          r'(ashe|asho|atu\.m|ataa\.m|ataa|atee|ato|avu\.m|avaa|aay|avo|she|sho|tee|taa|tu\.m|vu\.m|vaa|to)$',
        ),
        '',
      );
      if (seen.add(stem) && misses.length < 40) {
        misses.add('$stem :: ${row.roman} => ${result.text} | ${row.gujarati}');
      }
    }
    if (hit || suggestions.any((item) => item.text == row.gujarati)) top3++;
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
    wordTotal == 0 ? 1 : wordHits / wordTotal,
    edits / chars,
    misses,
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
      current[j + 1] = math.min(
        current[j] + 1,
        math.min(previous[j + 1] + 1, previous[j] + cost),
      );
    }
    previous = current;
  }
  return previous.last;
}
