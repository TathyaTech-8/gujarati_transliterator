import 'dart:io';

import 'review_lib.dart';

/// Copy the editor packet into category worksheets and batches of 80.
///
/// Every copied row stays `unreviewed`. A file that already contains a
/// decision, a reviewer spelling, a reviewer id, a dialect, or a note is
/// left as it is.
void main() {
  final report = prepareReviewCopies();
  stdout.writeln(
    'REVIEW_PREPARE written=${report.written.length} skipped=${report.skipped.length}',
  );
  for (final path in report.skipped) {
    stdout.writeln('REVIEW_PREPARE_SKIP $path');
  }
}
