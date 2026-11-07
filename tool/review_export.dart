import 'dart:io';

import 'review_lib.dart';

/// Write review/validated/validated_corpus.tsv from imported human decisions.
///
/// The file contains only rows with a decision and a reviewer spelling.
/// The editor packet is not modified.
void main() {
  exportValidatedCorpus();
  final stats = collectStats();
  stdout.writeln(
    'REVIEW_EXPORT approved_spellings=${stats.approved} path=review/validated/validated_corpus.tsv',
  );
}
