import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the review packet is large and not yet native-validated', () {
    final rows = <_Row>[];
    for (final line
        in File('test/corpus/validation_review.tsv').readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('\t');
      if (parts.length < 6) {
        throw FormatException('Bad review row: $trimmed');
      }
      rows.add(_Row(parts[1], parts[5]));
    }
    expect(rows.length, greaterThanOrEqualTo(1500));
    final validated = rows.where((row) => row.status == 'validated').length;
    expect(validated, 0);
    final categories = rows.map((row) => row.category).toSet();
    for (final category in const [
      'common',
      'informal',
      'family',
      'office',
      'formal',
      'proper',
      'religious',
      'loan',
      'sentence',
    ]) {
      expect(categories, contains(category), reason: category);
    }
    stdout.writeln(
      'VALIDATION_PACKET n=${rows.length} native_validated=$validated '
      'native_accuracy=not_measured',
    );
    stdout.writeln(
      'VALIDATION_NOTE editor-written spellings only; '
      'no fluent-speaker review has been recorded',
    );
  });
}

class _Row {
  const _Row(this.category, this.status);
  final String category;
  final String status;
}
