import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';

/// Desktop latency sample for the same words the test budget uses.
///
/// This does not measure a phone. Run from the package root:
/// `dart run benchmark/latency.dart`
void main() {
  final engine = GujaratiTransliterator();
  const words = <String>[
    'Kem',
    'Namaste',
    'Shukravar',
    'Surendranagar',
    'Gujarat',
    'Pani',
    'Aabhar',
    'Mitra',
    'Patel',
    'Ahmedabad',
    'kem cho',
    'hu gujarat ma rahu chhu',
    'shraddhanjali',
    'sanskriti',
    'vyakhya',
  ];
  for (var i = 0; i < 50; i++) {
    for (final word in words) {
      engine.transliterate(word);
    }
  }

  final samples = <int>[];
  final watch = Stopwatch();
  for (var i = 0; i < 200; i++) {
    for (final word in words) {
      watch.start();
      engine.transliterate(word);
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
      watch.reset();
    }
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  final p95 = samples[(samples.length * 0.95).floor()];
  stdout.writeln(
    'BENCH median=${median}us (${(median / 1000).toStringAsFixed(3)} ms) '
    'p95=${p95}us (${(p95 / 1000).toStringAsFixed(3)} ms) '
    'n=${samples.length}',
  );
}
