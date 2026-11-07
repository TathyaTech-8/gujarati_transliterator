import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:gujarati_transliterator/src/dictionary/builtin_lexicon.dart';
import 'package:gujarati_transliterator/src/dictionary/custom_dictionary.dart';
import 'package:gujarati_transliterator/src/engine/candidate_resolver.dart';
import 'package:gujarati_transliterator/src/engine/phonetic_parser.dart';

/// Times one-word candidate generation apart from full-string rendering.
///
/// Run from the package root: `dart run benchmark/candidates.dart`
void main() {
  final resolver = CandidateResolver(
    parser: PhoneticParser(),
    dictionary: createBuiltinDictionary(),
    custom: CustomDictionary(),
  );
  final engine = GujaratiTransliterator();
  const words = <String>[
    'kem',
    'ghaar',
    'tme',
    'paani',
    'bolu',
    'shikshan',
    'prakriya',
    'raajkot',
    'krishna',
    'shraddhanjali',
  ];
  const hard = <String>[
    'shraddhanjali',
    'sanskriti',
    'vyakhya',
    'krishna',
    'surendranagar',
  ];
  const sentences = <String>[
    'hu gujarati bolu chu',
    'aaje bahu saru che',
    'mare ghar javu che',
    'tame kem cho',
    'aapnu gujarat',
  ];

  final candidates = _time(
    words,
    (word) => resolver.resolve(
      word: word,
      mode: TransliterationMode.intelligent,
    ),
  );
  final hardCandidates = _time(
    hard,
    (word) => resolver.resolve(
      word: word,
      mode: TransliterationMode.intelligent,
    ),
  );
  final rendered = _time(sentences, engine.transliterate);
  _write('CANDIDATES', candidates);
  _write('CANDIDATES_HARD', hardCandidates);
  _write('SENTENCES', rendered);
}

void _write(String label, List<int> samples) {
  samples.sort();
  final median = samples[samples.length ~/ 2];
  final p95 = samples[(samples.length * 0.95).floor()];
  stdout.writeln(
    '$label median=${median}us (${(median / 1000).toStringAsFixed(3)} ms) '
    'p95=${p95}us (${(p95 / 1000).toStringAsFixed(3)} ms) '
    'n=${samples.length}',
  );
}

List<int> _time(List<String> inputs, void Function(String input) body) {
  for (var i = 0; i < 40; i++) {
    for (final input in inputs) {
      body(input);
    }
  }
  final samples = <int>[];
  final watch = Stopwatch();
  for (var i = 0; i < 200; i++) {
    for (final input in inputs) {
      watch.start();
      body(input);
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
      watch.reset();
    }
  }
  return samples;
}
