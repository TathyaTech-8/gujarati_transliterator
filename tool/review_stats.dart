import 'review_lib.dart';

/// Print review coverage and accepted-variant accuracy.
///
/// Accuracy is `not_measured` when no imported row has a reviewer spelling.
/// Unreviewed editor spellings are not counted.
void main() {
  printStats(collectStats());
}
