import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

import '../tool/review_lib.dart';

void main() {
  test('the editor packet stays unreviewed and the worksheets copy it', () {
    final sourceFile = File(editorReviewPath);
    final before = sourceFile.readAsBytesSync();
    final source = readReviewFile(editorReviewPath);
    expect(source.ok, isTrue,
        reason: source.issues.map((issue) => issue.message).join('\n'));
    expect(source.rows.length, 2371);
    expect(source.rows.where((row) => row.isDecision).length, 0);
    expect(source.rows.where((row) => row.isApproved).length, 0);
    expect(source.issues.where((issue) => issue.code.startsWith('duplicate')),
        isEmpty);

    final root = Directory.systemTemp.createTempSync('gujarati-review');
    addTearDown(() => root.deleteSync(recursive: true));
    final prepared = prepareReviewCopies(destination: root.path);
    expect(prepared.skipped, isEmpty);
    final copied = <ReviewRow>[];
    for (final category in reviewCategories) {
      final check = readReviewFile('${root.path}/categories/$category.tsv');
      expect(check.ok, isTrue, reason: category);
      expect(check.rows, isNotEmpty, reason: category);
      expect(check.rows.every((row) => row.nativeStatus == statusUnreviewed),
          isTrue);
      expect(check.rows.every((row) => row.reviewerSpelling.isEmpty), isTrue);
      copied.addAll(check.rows);
      final batches = Directory('${root.path}/batches')
          .listSync()
          .whereType<File>()
          .where(
              (file) => file.path.replaceAll('\\', '/').contains('/$category-'))
          .toList();
      expect(batches, isNotEmpty, reason: category);
      var batched = 0;
      for (final batch in batches) {
        final rows = readReviewFile(batch.path).rows;
        expect(rows.length, lessThanOrEqualTo(reviewBatchSize));
        expect(
            rows.every((row) => row.nativeStatus == statusUnreviewed), isTrue);
        batched += rows.length;
      }
      expect(batched, check.rows.length, reason: category);
    }
    expect(copied.length, source.rows.length);
    final sourceById = {for (final row in source.rows) row.id: row};
    for (final row in copied) {
      final original = sourceById[row.id]!;
      expect(row.roman, original.roman);
      expect(row.editorGujarati, original.editorGujarati);
      expect(row.category, original.category);
    }

    final marked = File('${root.path}/batches/loan-01.tsv');
    final text = marked.readAsStringSync().replaceFirst(
          '\tunreviewed\t\t',
          '\taccepted\tબેન\t',
        );
    marked.writeAsStringSync(text);
    final again = prepareReviewCopies(destination: root.path);
    expect(again.skipped, hasLength(1));
    expect(again.skipped.single.replaceAll('\\', '/'),
        endsWith('/batches/loan-01.tsv'));
    expect(marked.readAsStringSync().contains('\taccepted\t'), isTrue);
    expect(sourceFile.readAsBytesSync(), before);
  });

  test(
      'unreviewed spellings are not validated and approved variants are scored',
      () {
    final engine = GujaratiTransliterator();
    final untouched = scoreApproved([
      _row(status: statusUnreviewed, spelling: 'પાણી'),
    ]);
    expect(untouched.scored, 0);
    expect(ratioText(untouched.strictTop1, untouched.scored), 'not_measured');

    final benText = engine.transliterate('ben').text;
    expect(benText, 'બેન');
    final score = scoreApproved(
      [
        _row(id: '1', roman: 'paani', spelling: 'પાણી', reviewerId: 'r1'),
        _row(
          id: '2',
          roman: 'ben',
          spelling: 'બહેન',
          alternatives: 'બેન',
          reviewerId: 'r1',
        ),
        _row(
          id: '3',
          roman: 'zzzz',
          spelling: 'પાણી',
          reviewerId: 'r1',
        ),
        _row(
          id: '4',
          category: 'sentence',
          roman: 'paani',
          spelling: 'પાણી',
          reviewerId: 'r1',
        ),
        _row(
          id: '5',
          status: statusUnreviewed,
          roman: 'paani',
          spelling: 'પાણી',
        ),
        _row(id: '6', status: statusIncorrect, spelling: ''),
      ],
      engine: engine,
    );
    expect(score.scored, 4);
    expect(score.strictTop1, 2);
    expect(score.variantTop1, 3);
    expect(score.strictTop1, lessThan(score.variantTop1));
    expect(score.sentenceRows, 1);
    expect(score.strictSentenceExact, 1);
    expect(score.variantSentenceExact, 1);
    expect(score.cerEdits, greaterThan(0));
    expect(score.variantCerEdits, lessThan(score.cerEdits));
  });

  test('import keeps unreviewed rows out of the validated corpus', () {
    final root = Directory.systemTemp.createTempSync('gujarati-review-import');
    addTearDown(() => root.deleteSync(recursive: true));
    final batch = '${root.path}/batch.tsv';
    writeReviewFile(
      batch,
      [
        _row(
            id: '8',
            roman: 'dudh',
            editor: 'દૂધ',
            status: statusUnreviewed,
            spelling: 'દૂધ'),
        _row(id: '9', spelling: 'પાણી', reviewerId: 'r1'),
      ],
      banner: 'fixture',
    );
    final output = '${root.path}/reviews.tsv';
    final report = importApprovedReviews([batch], outputPath: output);
    expect(report.added, 1);
    expect(report.skippedUnreviewed, 1);
    final imported = readReviewFile(output);
    expect(imported.rows.map((row) => row.id), ['9']);
    expect(() => importApprovedReviews([editorReviewPath], outputPath: output),
        throwsArgumentError);
    expect(
      () => writeReviewFile(editorReviewPath, const [], banner: 'no'),
      throwsArgumentError,
    );

    final broken = '${root.path}/broken.tsv';
    File(broken).writeAsStringSync(
      'id\tcategory\troman\teditor_gujarati\teditor_certainty\tnative_status\treviewer_spelling\tdispute\tnote\n'
      '1\tcommon\tpaani\tપાણી\teditor\tunreviewed\t\t\t\n'
      '1\tcommon\tpaani\tપાણી\teditor\tunreviewed\t\t\t\n',
    );
    final duplicates = readReviewFile(broken);
    expect(duplicates.ok, isFalse);
    expect(
      duplicates.issues.map((issue) => issue.code),
      containsAll(['duplicate-id', 'duplicate-record']),
    );
    final missing = readReviewFile(_writeStatus(root.path, statusAccepted, ''));
    expect(missing.issues.map((issue) => issue.code),
        contains('missing-spelling'));
    final email = readReviewFile(
        _writeStatus(root.path, statusAccepted, 'પાણી', reviewerId: 'a@b.c'));
    expect(email.issues.map((issue) => issue.code), contains('reviewer-id'));

    exportValidatedCorpus(
        reviewsPath: output, outputPath: '${root.path}/validated.tsv');
    final exported =
        File('${root.path}/validated.tsv').readAsLinesSync().where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty &&
          !trimmed.startsWith('#') &&
          !trimmed.startsWith('id\t');
    });
    expect(exported, ['9\tcommon\tpaani\tપાણી\t\taccepted\t\tr1']);
  });

  test('shipped worksheets and accuracy stay unreviewed', () {
    final stats =
        collectStats(reviewsPath: 'review/validated/does-not-exist.tsv');
    expect(stats.editorRows, 2371);
    expect(stats.reviewed, 0);
    expect(stats.approved, 0);
    expect(stats.alternatives, 0);
    expect(stats.disputed, 0);
    expect(stats.reviewerIds, isEmpty);
    expect(stats.score.scored, 0);
    for (final category in reviewCategories) {
      final coverage = stats.byCategory[category]!;
      expect(coverage.total, greaterThan(0), reason: category);
      expect(coverage.reviewed, 0, reason: category);
      final worksheet = readReviewFile('review/categories/$category.tsv');
      expect(worksheet.ok, isTrue, reason: category);
      expect(worksheet.rows.length, coverage.total, reason: category);
      expect(worksheet.rows.every((row) => !row.isDecision), isTrue,
          reason: category);
    }
    final batches = Directory('review/batches').listSync().whereType<File>();
    expect(batches, isNotEmpty);
    for (final batch in batches) {
      final rows = readReviewFile(batch.path).rows;
      expect(rows, isNotEmpty, reason: batch.path);
      expect(rows.length, lessThanOrEqualTo(reviewBatchSize),
          reason: batch.path);
      expect(
          rows.every((row) => !row.isDecision && row.reviewerSpelling.isEmpty),
          isTrue);
    }
  });
}

ReviewRow _row({
  String id = '1',
  String category = 'common',
  String roman = 'paani',
  String editor = 'પાણી',
  String status = statusAccepted,
  String spelling = '',
  String alternatives = '',
  String reviewerId = '',
  int line = 1,
}) {
  return ReviewRow(
    id: id,
    category: category,
    roman: roman,
    editorGujarati: editor,
    editorCertainty: 'editor',
    nativeStatus: status,
    reviewerSpelling: spelling,
    dispute: '',
    note: '',
    acceptedAlternatives: alternatives,
    dialect: '',
    reviewerId: reviewerId,
    reviewerNote: '',
    line: line,
  );
}

String _writeStatus(
  String directory,
  String status,
  String spelling, {
  String reviewerId = 'r1',
}) {
  final path = '$directory/$status-$spelling.tsv';
  writeReviewFile(
    path,
    [_row(status: status, spelling: spelling, reviewerId: reviewerId)],
    banner: 'fixture',
  );
  return path;
}
