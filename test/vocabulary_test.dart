import 'dart:io';

import 'package:gujarati_transliterator/file.dart';
import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  test('a preferred custom mapping wins in every mode', () async {
    final engine = GujaratiTransliterator();
    await engine.addCustomMapping('pani', 'પાની');
    expect(engine.transliterate('Pani').text, 'પાની');
    expect(
      engine.transliterate('Pani', mode: TransliterationMode.phonetic).text,
      'પાની',
    );
    expect(engine.suggest('pani').map((item) => item.text), contains('પાણી'));
    expect(engine.suggest('pani').first.confidence, 1);
    expect(engine.suggest('pani').first.source, SuggestionSource.custom);

    await engine.removeCustomMapping('pani');
    expect(engine.transliterate('pani').text, 'પાણી');
  });

  test('a non-preferred mapping stays a suggestion', () async {
    final engine = GujaratiTransliterator();
    await engine.addCustomMapping('pani', 'પાની', prefer: false);
    expect(engine.transliterate('pani').text, 'પાણી');
    expect(engine.suggest('pani').map((item) => item.text), contains('પાની'));
  });

  test('a correction is local and reusable', () async {
    final corrected = GujaratiTransliterator();
    final untouched = GujaratiTransliterator();
    await corrected.addCorrection('kal', 'કલ્પ');
    expect(corrected.transliterate('kal').text, 'કલ્પ');
    expect(corrected.suggest('kal').map((item) => item.text), contains('કાલ'));
    expect(untouched.transliterate('kal').text, 'કાલ');

    await corrected.learnSelection('kal', 'કલ્પ');
    expect(corrected.customEntries.single.hits, 2);
    expect(corrected.customEntries.single.origin, CustomOrigin.correction);
  });

  test('a newer correction outranks an older one', () async {
    final engine = GujaratiTransliterator();
    await engine.addCorrection('kal', 'કલ્પ');
    await engine.addCorrection('kal', 'કાળ');
    expect(engine.transliterate('kal').text, 'કાળ');
    expect(engine.suggest('kal').map((item) => item.text), contains('કલ્પ'));
    expect(GujaratiTransliterator().transliterate('kal').text, 'કાલ');
  });

  test('a custom word blocks a built-in phrase', () async {
    final engine = GujaratiTransliterator();
    await engine.addCustomMapping('cho', 'ચૌ');
    expect(engine.transliterate('Kem cho').text, 'કેમ ચૌ');
  });

  test('a custom phrase is kept even in phonetic mode', () async {
    final engine = GujaratiTransliterator();
    await engine.addCustomMapping('abc xyz', 'કેમ');
    expect(engine.transliterate('abc xyz').text, 'કેમ');
    expect(
      engine.transliterate('abc xyz', mode: TransliterationMode.phonetic).text,
      'કેમ',
    );
  });

  test('vocabulary JSON round-trips through another engine', () async {
    final engine = GujaratiTransliterator();
    await engine.addCustomMapping('Narvirsinh', 'નરવીરસિંહ');
    final copy = GujaratiTransliterator();
    await copy.importVocabulary(await engine.exportVocabulary());
    expect(copy.transliterate('narvirsinh').text, 'નરવીરસિંહ');
  });

  test('empty mappings are rejected', () async {
    final engine = GujaratiTransliterator();
    expect(engine.addCustomMapping('   ', 'ક'), throwsArgumentError);
    expect(engine.addCustomMapping('kem', '  '), throwsArgumentError);
  });

  test('a delegating store reloads the saved JSON', () async {
    String? saved;
    final store = DelegatingVocabularyStore(
      read: () async => saved,
      write: (contents) async {
        saved = contents;
      },
    );
    final engine = await GujaratiTransliterator.open(store: store);
    await engine.addCustomMapping('mitra', 'મીત્ર');
    final reopened = await GujaratiTransliterator.open(store: store);
    expect(reopened.transliterate('mitra').text, 'મીત્ર');
  });

  test('a file store survives a new process-local engine', () async {
    final directory = await Directory.systemTemp.createTemp('guj_vocab');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}vocab.json';
    final engine = await GujaratiTransliterator.open(
      store: FileVocabularyStore(path),
    );
    await engine.addCustomMapping('Narvirsinh', 'નરવીરસિંહ');

    final reopened = await GujaratiTransliterator.open(
      store: FileVocabularyStore(path),
    );
    expect(reopened.transliterate('Narvirsinh').text, 'નરવીરસિંહ');
    expect(reopened.isLoaded, isTrue);
  });
}
