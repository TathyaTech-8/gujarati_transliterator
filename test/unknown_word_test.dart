import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  test('an unknown word keeps the typed reading and offers the long vowel', () {
    expect(engine.transliterate('prakriya').text, 'પ્રક્રિય');
    expect(
      engine.suggest('prakriya', limit: 8).map((item) => item.text),
      contains('પ્રક્રિયા'),
    );
    expect(
      engine.transliterate('prakriya', mode: TransliterationMode.phonetic).text,
      'પ્રક્રિય',
    );
  });

  test('retroflex and aspirated alternates stay suggestions', () {
    expect(engine.transliterate('shikshan').text, 'શિક્ષન');
    expect(
      engine.suggest('shikshan', limit: 8).map((item) => item.text),
      contains('શિક્ષણ'),
    );
    expect(engine.transliterate('math').text, 'મથ');
    expect(
      engine.suggest('math', limit: 8).map((item) => item.text),
      contains('મઠ'),
    );
  });

  test('an unfamiliar name is not replaced by a nearby word', () {
    expect(engine.transliterate('Trilok').text, 'ત્રિલોક');
    expect(
      engine.transliterate('patelji').text,
      engine.transliterate('patelji', mode: TransliterationMode.phonetic).text,
    );
  });

  test('a known phrase still uses the preceding word', () {
    expect(engine.transliterate('khub saru').text, 'ખૂબ સારું');
    expect(engine.transliterate('saru').text, 'સારું');
    expect(engine.transliterate('bahu saru').text, 'બહુ સારું');
  });

  test('chandrabindu is offered beside anusvara', () {
    final suggestions = engine.suggest('sanpa', limit: 8);
    expect(suggestions.first.text, 'સંપ');
    expect(
      suggestions.map((item) => item.text),
      contains('સઁપ'),
    );
  });
}
