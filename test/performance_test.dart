import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  test('ordinary words stay inside the latency budget', () {
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
      'PERF median=${median}us (${(median / 1000).toStringAsFixed(3)} ms) '
      'p95=${p95}us (${(p95 / 1000).toStringAsFixed(3)} ms) '
      'n=${samples.length}',
    );
    expect(median, lessThan(10000), reason: 'median should be under 10 ms');
    expect(p95, lessThan(30000), reason: 'p95 should be under 30 ms');
  });
}
