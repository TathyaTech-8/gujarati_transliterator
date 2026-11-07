import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';

Future<void> main() async {
  final engine = GujaratiTransliterator();
  final extra = File('assets/dictionaries/extra_vocabulary.json');
  if (extra.existsSync()) {
    DictionaryLoader.addJson(engine.dictionary, extra.readAsStringSync());
  }

  const samples = <String>[
    'Kem',
    'Namaste',
    'Shukravar',
    'Surendranagar',
    'Gujarat',
    'Pani',
    'Aabhar',
    'Mitra',
    'Kem cho?',
    'saputara',
    'shraddhanjali',
    'krishna',
    'sanskriti',
  ];
  for (final sample in samples) {
    stdout.writeln('$sample → ${engine.transliterate(sample)}');
  }

  stdout.writeln('--- Kal ---');
  for (final suggestion in engine.suggest('Kal')) {
    stdout.writeln(suggestion);
  }

  stdout.writeln('--- modes ---');
  stdout.writeln(
    'phonetic Pani → ${engine.transliterate('Pani', mode: TransliterationMode.phonetic)}',
  );
  stdout.writeln(
    'standard Patel → ${engine.transliterate('Patel', mode: TransliterationMode.standard)}',
  );

  await engine.addCustomMapping('Narvirsinh', 'નરવીરસિંહ');
  stdout.writeln('custom → ${engine.transliterate('Narvirsinh')}');

  final session = engine.startSession();
  stdout.writeln('live → ${session.update('Kem ')}');
  stdout.writeln('live → ${session.update('Kem cho')}');
}
