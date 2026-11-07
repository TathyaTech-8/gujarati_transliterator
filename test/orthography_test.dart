import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  test('difficult spellings use the standard orthography', () {
    final expected = <String, List<int>>{
      'shraddhanjali': [
        0x0AB6,
        0x0ACD,
        0x0AB0,
        0x0AA6,
        0x0ACD,
        0x0AA7,
        0x0ABE,
        0x0A82,
        0x0A9C,
        0x0AB2,
        0x0ABF,
      ],
      'pragya': [0x0AAA, 0x0ACD, 0x0AB0, 0x0A9C, 0x0ACD, 0x0A9E, 0x0ABE],
      'prajna': [0x0AAA, 0x0ACD, 0x0AB0, 0x0A9C, 0x0ACD, 0x0A9E, 0x0ABE],
      'gyan': [0x0A9C, 0x0ACD, 0x0A9E, 0x0ABE, 0x0AA8],
      'kshatriya': [
        0x0A95,
        0x0ACD,
        0x0AB7,
        0x0AA4,
        0x0ACD,
        0x0AB0,
        0x0ABF,
        0x0AAF,
      ],
      'trivedi': [
        0x0AA4,
        0x0ACD,
        0x0AB0,
        0x0ABF,
        0x0AB5,
        0x0AC7,
        0x0AA6,
        0x0AC0,
      ],
      'krishna': [0x0A95, 0x0AC3, 0x0AB7, 0x0ACD, 0x0AA3],
      'swagat': [0x0AB8, 0x0ACD, 0x0AB5, 0x0ABE, 0x0A97, 0x0AA4],
      'utsav': [0x0A89, 0x0AA4, 0x0ACD, 0x0AB8, 0x0AB5],
      'vyakhya': [
        0x0AB5,
        0x0ACD,
        0x0AAF,
        0x0ABE,
        0x0A96,
        0x0ACD,
        0x0AAF,
        0x0ABE,
      ],
      'sanskriti': [
        0x0AB8,
        0x0A82,
        0x0AB8,
        0x0ACD,
        0x0A95,
        0x0AC3,
        0x0AA4,
        0x0ABF,
      ],
    };
    for (final entry in expected.entries) {
      expect(
        engine.transliterate(entry.key).text.runes.toList(),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('ri and ru stay conjuncts unless a better reading wins', () {
    expect(engine.transliterate('tri').text, 'ત્રિ');
    expect(
      engine.transliterate('tri', mode: TransliterationMode.phonetic).text,
      'ત્રિ',
    );
    expect(engine.suggest('tri').map((item) => item.text), contains('તૃ'));
    expect(engine.transliterate('kru').text, 'ક્રુ');
    expect(engine.suggest('kru').map((item) => item.text), contains('કૃ'));
    expect(engine.transliterate('trivedi').text, 'ત્રિવેદી');
    expect(
      engine.suggest('krishna').map((item) => item.text),
      contains('ક્રિશ્ન'),
    );
  });

  test('shh offers retroflex sha without replacing the phonetic reading', () {
    final suggestions = engine.suggest('shh');
    expect(suggestions.first.text, 'શ્હ');
    expect(suggestions.map((item) => item.text), contains('ષ'));
  });

  test('an unfamiliar name is not replaced by a dictionary word', () {
    expect(engine.transliterate('patelji').text, isNot('પટેલ'));
    expect(
      engine.transliterate('patelji').text,
      engine.transliterate('patelji', mode: TransliterationMode.phonetic).text,
    );
    expect(engine.transliterate('Trilok').text, 'ત્રિલોક');
    expect(
        engine.suggest('Trilok').map((item) => item.text), contains('તૃલોક'));
    expect(engine.transliterate('qezvol').text, isNot(contains('પટેલ')));
  });

  test('a custom mapping still outranks a pattern alternate', () async {
    final local = GujaratiTransliterator();
    await local.addCustomMapping('tri', 'ત્રી');
    expect(local.transliterate('tri').text, 'ત્રી');
    expect(GujaratiTransliterator().transliterate('tri').text, 'ત્રિ');
  });
}
