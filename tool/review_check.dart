import 'dart:io';

import 'review_lib.dart';

/// Check review TSV files for structure, duplicate records, and missing spellings.
///
/// With no arguments, checks the editor packet. Pass worksheet paths to check
/// those files instead. Exits 1 when any error is present. Warnings are printed
/// and do not by themselves fail the check.
void main(List<String> args) {
  final paths = args.isEmpty ? <String>[editorReviewPath] : args;
  var errors = 0;
  for (final path in paths) {
    final check = readReviewFile(path);
    final duplicates = check.issues
        .where((issue) =>
            issue.code == 'duplicate-id' || issue.code == 'duplicate-record')
        .length;
    final missing =
        check.issues.where((issue) => issue.code == 'missing-spelling').length;
    stdout.writeln(
      'REVIEW_CHECK $path rows=${check.rows.length} '
      'issues=${check.issues.length} duplicate_flags=$duplicates missing_spelling_flags=$missing',
    );
    for (final issue in check.issues) {
      stdout.writeln(
          '${issue.severity.toUpperCase()} ${issue.code} ${issue.message}');
      if (issue.isError) errors++;
    }
  }
  if (errors > 0) exitCode = 1;
}
