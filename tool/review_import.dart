import 'dart:io';

import 'review_lib.dart';

/// Copy completed review rows into review/validated/reviews.tsv.
///
/// Rows that are still `unreviewed` are skipped. This does not change
/// test/corpus/validation_review.tsv and does not invent a status.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/review_import.dart <batch.tsv> [more.tsv]');
    exitCode = 64;
    return;
  }
  final report = importApprovedReviews(args);
  stdout.writeln(
    'REVIEW_IMPORT added=${report.added} replaced=${report.replaced} '
    'skipped_unreviewed=${report.skippedUnreviewed} output=${report.outputPath}',
  );
}
