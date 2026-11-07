import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  test('specification examples use intelligent mode', () {
    final expected = <String, List<int>>{
      'Kem': [0x0A95, 0x0AC7, 0x0AAE],
      'Namaste': [0x0AA8, 0x0AAE, 0x0AB8, 0x0ACD, 0x0AA4, 0x0AC7],
      'Shukravar': [
        0x0AB6,
        0x0AC1,
        0x0A95,
        0x0ACD,
        0x0AB0,
        0x0AB5,
        0x0ABE,
        0x0AB0,
      ],
      'Surendranagar': [
        0x0AB8,
        0x0AC1,
        0x0AB0,
        0x0AC7,
        0x0AA8,
        0x0ACD,
        0x0AA6,
        0x0ACD,
        0x0AB0,
        0x0AA8,
        0x0A97,
        0x0AB0,
      ],
      'Gujarat': [0x0A97, 0x0AC1, 0x0A9C, 0x0AB0, 0x0ABE, 0x0AA4],
      'Pani': [0x0AAA, 0x0ABE, 0x0AA3, 0x0AC0],
      'Aabhar': [0x0A86, 0x0AAD, 0x0ABE, 0x0AB0],
      'Mitra': [0x0AAE, 0x0ABF, 0x0AA4, 0x0ACD, 0x0AB0],
    };
    for (final entry in expected.entries) {
      expect(
        engine.transliterate(entry.key).text.runes.toList(),
        entry.value,
        reason: entry.key,
      );
    }
    expect(engine.transliterate('Kem cho?').text.runes.toList(), [
      0x0A95,
      0x0AC7,
      0x0AAE,
      0x20,
      0x0A9B,
      0x0ACB,
      0x3F,
    ]);
  });

  test('modes disagree when spelling and pronunciation differ', () {
    expect(
      engine.transliterate('Pani', mode: TransliterationMode.phonetic).text,
      'પનિ',
    );
    expect(
      engine.transliterate('Pani', mode: TransliterationMode.standard).text,
      'પાણી',
    );
    expect(
      engine
          .transliterate('Shukravar', mode: TransliterationMode.phonetic)
          .text,
      'શુક્રવર',
    );
    expect(
      engine.transliterate('Patel', mode: TransliterationMode.phonetic).text,
      'પતેલ',
    );
    expect(engine.transliterate('Patel').text, 'પટેલ');
    expect(
      engine.transliterate('Kem cho', mode: TransliterationMode.phonetic).text,
      'કેમ ચો',
    );
    expect(engine.transliterate('Kem cho').text, 'કેમ છો');
  });

  test('Kal offers ranked candidates', () {
    final suggestions = engine.suggest('Kal');
    expect(suggestions.first.text, 'કાલ');
    expect(suggestions.map((item) => item.text), contains('કલ'));
    expect(
      suggestions.first.confidence,
      greaterThan(suggestions[1].confidence),
    );
    expect(suggestions.first.rank, 1);
    expect(suggestions[1].rank, 2);
    expect(
      engine.transliterate('Kal', mode: TransliterationMode.phonetic).text,
      'કલ',
    );
  });

  test('the top suggestion is the transliteration', () {
    for (final input in ['Kal', 'Pani', 'Kem cho', 'Kem cho?']) {
      expect(
        engine.suggest(input).first.text,
        engine.transliterate(input).text,
        reason: input,
      );
    }
  });

  test('results are deterministic', () {
    final first = engine.transliterate('Shukravar kem cho');
    final second = engine.transliterate('Shukravar kem cho');
    expect(second.text, first.text);
    expect(
      second.suggestions.map((item) => item.text).toList(),
      first.suggestions.map((item) => item.text).toList(),
    );
  });

  test('preceding word can change an ambiguous spelling', () {
    expect(engine.transliterate('ma').text, 'માં');
    expect(engine.transliterate('mari ma').text, 'મારી મા');
    expect(engine.transliterate('mari  ma').text, 'મારી  મા');
  });

  test('spacing, digits, punctuation, and Gujarati text are preserved', () {
    expect(engine.transliterate('Kem  cho').text, 'કેમ  છો');
    expect(engine.transliterate('Kem\ncho').text, 'કેમ\nછો');
    expect(engine.transliterate('Kem, cho!').text, 'કેમ, છો!');
    expect(engine.transliterate('123 kem').text, '123 કેમ');
    expect(engine.transliterate('કેમ cho').text, 'કેમ છો');
    expect(engine.transliterate('  Kem  ').text, '  કેમ  ');
    expect(engine.transliterate('').text, '');
  });

  test('a multi-word name can collapse to one spelling', () {
    expect(engine.transliterate('narvir sinh').text, 'નરવીરસિંહ');
    expect(engine.transliterate('narvir').text, 'નરવીર');
    expect(engine.transliterate('sinh').text, 'સિંહ');
  });

  test('everyday sentence', () {
    expect(
      engine.transliterate('hu gujarat ma rahu chhu').text,
      'હું ગુજરાત માં રહું છું',
    );
  });

  test('anusvara is preferred for a short nasal cluster', () {
    final result = engine.transliterate('sanpa');
    expect(result.text.runes.toList(), [0x0AB8, 0x0A82, 0x0AAA]);
    expect(
      result.activeSuggestions.map((item) => item.text),
      contains('સન્પ'),
    );
    expect(
      engine.transliterate('sanpa', mode: TransliterationMode.phonetic).text,
      'સન્પ',
    );
  });

  test('every lexicon key has one top frequency', () {
    final groups = <String, List<DictionaryEntry>>{};
    for (final entry in engine.dictionary.entries) {
      groups.putIfAbsent(entry.roman, () => []).add(entry);
    }
    for (final group in groups.values) {
      final top =
          group.map((entry) => entry.frequency).reduce((a, b) => a > b ? a : b);
      final winners = group.where((entry) => entry.frequency == top).length;
      expect(winners, 1, reason: group.first.roman);
    }
  });

  test('top lexicon spellings round-trip', () {
    final best = <String, DictionaryEntry>{};
    for (final entry in engine.dictionary.entries) {
      final current = best[entry.roman];
      if (current == null || entry.frequency > current.frequency) {
        best[entry.roman] = entry;
      }
    }
    for (final entry in best.values) {
      expect(
        engine.transliterate(entry.roman).text,
        entry.gujarati,
        reason: entry.roman,
      );
    }
  });

  test('extra vocabulary JSON extends one engine only', () {
    final json = File(
      'assets/dictionaries/extra_vocabulary.json',
    ).readAsStringSync();
    DictionaryLoader.addJson(engine.dictionary, json);
    expect(engine.transliterate('saputara').text, 'સાપુતારા');
    expect(engine.transliterate('kevadiya').text, 'કેવડિયા');
    expect(GujaratiTransliterator().transliterate('saputara').text,
        isNot('સાપુતારા'));
  });

  test('the core library does not import Flutter, IO, or HTTP', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (path.endsWith('src/dictionary/file_vocabulary_store.dart')) continue;
      final text = file.readAsStringSync();
      expect(text.contains("import 'dart:io'"), isFalse, reason: path);
      expect(text.contains('package:flutter'), isFalse, reason: path);
      expect(text.contains('package:http'), isFalse, reason: path);
      expect(text.contains('dart:html'), isFalse, reason: path);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('flutter'), isFalse);
  });
}
