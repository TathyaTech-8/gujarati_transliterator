import 'package:gujarati_transliterator/gujarati_transliterator.dart';

/// Times sentence transliteration apart from single-word lookup.
void main() {
  const sentences = <String>[
    'hu office ma chu',
    'mare meeting ma javanu che',
    'tame mane call karjo',
    'aaje payment karvanu che',
    'aapde kale vaat karishu',
    'hu ghar thi kaam karu chu',
    'tamaro message mali gayo',
    'aa document mokli aapjo',
    'Please send the document tomorrow',
  ];
  final engine = GujaratiTransliterator();
  for (var i = 0; i < 40; i++) {
    for (final sentence in sentences) {
      engine.transliterate(sentence);
    }
  }
  final samples = <int>[];
  final watch = Stopwatch();
  for (var i = 0; i < 200; i++) {
    for (final sentence in sentences) {
      watch
        ..reset()
        ..start();
      engine.transliterate(sentence);
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
    }
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  final p95 = samples[(samples.length * 0.95).floor() - 1];
  print(
    'SENTENCE_BENCH median=${median}us (${(median / 1000).toStringAsFixed(3)} ms) '
    'p95=${p95}us (${(p95 / 1000).toStringAsFixed(3)} ms) n=${samples.length}',
  );
}
