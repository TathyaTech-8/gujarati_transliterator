import 'dart:io';
import 'dart:math' as math;

import 'package:gujarati_transliterator/gujarati_transliterator.dart';

/// Editor packet. Tools may read it. They must not write it.
const editorReviewPath = 'test/corpus/validation_review.tsv';

/// Working copies live here. They start unreviewed.
const reviewRoot = 'review';

const reviewBatchSize = 80;

const reviewColumns = <String>[
  'id',
  'category',
  'roman',
  'editor_gujarati',
  'editor_certainty',
  'native_status',
  'reviewer_spelling',
  'dispute',
  'note',
  'accepted_alternatives',
  'dialect',
  'reviewer_id',
  'reviewer_note',
];

const statusUnreviewed = 'unreviewed';
const statusAccepted = 'accepted';
const statusIncorrect = 'incorrect';
const statusAmbiguous = 'ambiguous';
const statusDialect = 'dialect';

const reviewStatuses = <String>{
  statusUnreviewed,
  statusAccepted,
  statusIncorrect,
  statusAmbiguous,
  statusDialect,
};

const decisionStatuses = <String>{
  statusAccepted,
  statusIncorrect,
  statusAmbiguous,
  statusDialect,
};

const reviewCategories = <String>[
  'common',
  'informal',
  'family',
  'office',
  'formal',
  'proper',
  'religious',
  'loan',
  'sentence',
];

final _reviewerIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,32}$');
final _phonePattern = RegExp(r'\d{8,}');

class ReviewRow {
  const ReviewRow({
    required this.id,
    required this.category,
    required this.roman,
    required this.editorGujarati,
    required this.editorCertainty,
    required this.nativeStatus,
    required this.reviewerSpelling,
    required this.dispute,
    required this.note,
    required this.acceptedAlternatives,
    required this.dialect,
    required this.reviewerId,
    required this.reviewerNote,
    required this.line,
  });

  final String id;
  final String category;
  final String roman;
  final String editorGujarati;
  final String editorCertainty;
  final String nativeStatus;
  final String reviewerSpelling;
  final String dispute;
  final String note;
  final String acceptedAlternatives;
  final String dialect;
  final String reviewerId;
  final String reviewerNote;
  final int line;

  bool get isDecision => decisionStatuses.contains(nativeStatus);

  /// A person chose a status and wrote a primary spelling.
  /// An unreviewed row is never approved, even if a spelling cell is filled.
  bool get isApproved => isDecision && reviewerSpelling.isNotEmpty;

  List<String> get alternatives {
    if (acceptedAlternatives.isEmpty) return const [];
    return [
      for (final part in acceptedAlternatives.split('|'))
        if (part.trim().isNotEmpty && part.trim() != reviewerSpelling)
          part.trim(),
    ];
  }

  List<String> get approvedSpellings {
    if (!isApproved) return const [];
    return [reviewerSpelling, ...alternatives];
  }

  List<String> get cells => [
        id,
        category,
        roman,
        editorGujarati,
        editorCertainty,
        nativeStatus,
        reviewerSpelling,
        dispute,
        note,
        acceptedAlternatives,
        dialect,
        reviewerId,
        reviewerNote,
      ];
}

class ReviewIssue {
  const ReviewIssue(this.severity, this.code, this.message);

  final String severity;
  final String code;
  final String message;

  bool get isError => severity == 'error';
}

class ReviewCheck {
  const ReviewCheck(this.rows, this.issues);

  final List<ReviewRow> rows;
  final List<ReviewIssue> issues;

  bool get ok => issues.every((issue) => !issue.isError);
}

class PrepareReport {
  const PrepareReport(this.written, this.skipped);

  final List<String> written;
  final List<String> skipped;
}

class ImportReport {
  const ImportReport({
    required this.added,
    required this.replaced,
    required this.skippedUnreviewed,
    required this.outputPath,
  });

  final int added;
  final int replaced;
  final int skippedUnreviewed;
  final String outputPath;
}

class ReviewStats {
  const ReviewStats({
    required this.editorRows,
    required this.reviewed,
    required this.approved,
    required this.alternatives,
    required this.disputed,
    required this.reviewerIds,
    required this.missingReviewerId,
    required this.editorDisputeNotes,
    required this.byCategory,
    required this.score,
  });

  final int editorRows;
  final int reviewed;
  final int approved;
  final int alternatives;
  final int disputed;
  final Set<String> reviewerIds;
  final int missingReviewerId;
  final int editorDisputeNotes;
  final Map<String, CategoryCoverage> byCategory;
  final VariantScore score;
}

class CategoryCoverage {
  const CategoryCoverage(this.total, this.reviewed);

  final int total;
  final int reviewed;
}

class VariantScore {
  const VariantScore({
    required this.scored,
    required this.strictTop1,
    required this.variantTop1,
    required this.strictTop3,
    required this.variantTop3,
    required this.cerEdits,
    required this.cerChars,
    required this.variantCerEdits,
    required this.sentenceRows,
    required this.strictSentenceExact,
    required this.variantSentenceExact,
  });

  final int scored;
  final int strictTop1;
  final int variantTop1;
  final int strictTop3;
  final int variantTop3;
  final int cerEdits;
  final int cerChars;
  final int variantCerEdits;
  final int sentenceRows;
  final int strictSentenceExact;
  final int variantSentenceExact;

  static const unmeasured = VariantScore(
    scored: 0,
    strictTop1: 0,
    variantTop1: 0,
    strictTop3: 0,
    variantTop3: 0,
    cerEdits: 0,
    cerChars: 0,
    variantCerEdits: 0,
    sentenceRows: 0,
    strictSentenceExact: 0,
    variantSentenceExact: 0,
  );
}

ReviewCheck readReviewFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return ReviewCheck(const [], [
      ReviewIssue('error', 'missing-file', '$path does not exist'),
    ]);
  }
  final issues = <ReviewIssue>[];
  final rows = <ReviewRow>[];
  final lines = file.readAsLinesSync();
  for (var index = 0; index < lines.length; index++) {
    final raw = lines[index];
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = raw.split('\t');
    if (parts.isNotEmpty) parts[0] = parts[0].trim();
    if (parts.length >= 2 &&
        parts[0] == 'id' &&
        parts[1].trim() == 'category') {
      continue;
    }
    if (parts.length < 9 || parts.length > reviewColumns.length) {
      issues.add(
        ReviewIssue(
          'error',
          'bad-width',
          '$path:${index + 1} has ${parts.length} columns; expected 9 to ${reviewColumns.length}',
        ),
      );
      continue;
    }
    while (parts.length < reviewColumns.length) {
      parts.add('');
    }
    if (parts.any((part) => part.contains('\n') || part.contains('\r'))) {
      issues.add(
        ReviewIssue(
            'error', 'bad-cell', '$path:${index + 1} has a broken cell'),
      );
      continue;
    }
    rows.add(
      ReviewRow(
        id: parts[0].trim(),
        category: parts[1].trim(),
        roman: parts[2].trim(),
        editorGujarati: parts[3].trim(),
        editorCertainty: parts[4].trim(),
        nativeStatus: parts[5].trim(),
        reviewerSpelling: parts[6].trim(),
        dispute: parts[7].trim(),
        note: parts[8].trim(),
        acceptedAlternatives: parts[9].trim(),
        dialect: parts[10].trim(),
        reviewerId: parts[11].trim(),
        reviewerNote: parts[12].trim(),
        line: index + 1,
      ),
    );
  }
  issues.addAll(checkRows(rows, path));
  return ReviewCheck(rows, issues);
}

List<ReviewIssue> checkRows(List<ReviewRow> rows, String path) {
  final issues = <ReviewIssue>[];
  final seenIds = <String, int>{};
  final seenRecords = <String, int>{};
  for (final row in rows) {
    final where = '$path:${row.line}';
    if (row.id.isEmpty || row.roman.isEmpty || row.editorGujarati.isEmpty) {
      issues.add(ReviewIssue('error', 'empty-source',
          '$where is missing id, roman, or editor spelling'));
    }
    if (!reviewStatuses.contains(row.nativeStatus)) {
      issues.add(
        ReviewIssue(
          'error',
          'bad-status',
          '$where native_status "${row.nativeStatus}" is not one of ${reviewStatuses.join(", ")}',
        ),
      );
    }
    final previousId = seenIds[row.id];
    if (previousId != null) {
      issues.add(
        ReviewIssue('error', 'duplicate-id',
            '$where repeats id ${row.id} from line $previousId'),
      );
    } else if (row.id.isNotEmpty) {
      seenIds[row.id] = row.line;
    }
    final recordKey = '${row.category}\t${row.roman}\t${row.editorGujarati}';
    final previousRecord = seenRecords[recordKey];
    if (previousRecord != null) {
      issues.add(
        ReviewIssue(
          'error',
          'duplicate-record',
          '$where repeats category, roman, and editor spelling from line $previousRecord',
        ),
      );
    } else {
      seenRecords[recordKey] = row.line;
    }
    if (row.isDecision &&
        row.reviewerSpelling.isEmpty &&
        row.nativeStatus != statusIncorrect) {
      issues.add(
        ReviewIssue(
          'error',
          'missing-spelling',
          '$where status ${row.nativeStatus} has no reviewer_spelling',
        ),
      );
    }
    if (row.nativeStatus == statusIncorrect && row.reviewerSpelling.isEmpty) {
      issues.add(
        ReviewIssue(
          'warning',
          'missing-spelling',
          '$where is incorrect and has no replacement spelling',
        ),
      );
    }
    if (!row.isDecision &&
        (row.reviewerSpelling.isNotEmpty ||
            row.acceptedAlternatives.isNotEmpty)) {
      issues.add(
        ReviewIssue(
          'warning',
          'unreviewed-spelling',
          '$where has a spelling but native_status is still unreviewed, so it is not validated',
        ),
      );
    }
    if (row.nativeStatus == statusDialect && row.dialect.isEmpty) {
      issues.add(ReviewIssue('error', 'missing-dialect',
          '$where status dialect has no dialect label'));
    }
    if (row.reviewerId.isNotEmpty && !_safeReviewerId(row.reviewerId)) {
      issues.add(
        ReviewIssue(
          'error',
          'reviewer-id',
          '$where reviewer_id must be a short code such as r1, with no name, email, or phone number',
        ),
      );
    }
    if (row.isDecision && row.reviewerId.isEmpty) {
      issues.add(
        ReviewIssue('warning', 'missing-reviewer',
            '$where has a decision and no reviewer_id'),
      );
    }
    if (row.acceptedAlternatives.contains(',') &&
        !row.acceptedAlternatives.contains('|')) {
      issues.add(
        ReviewIssue(
          'warning',
          'alternatives-separator',
          '$where accepted_alternatives must use | between spellings',
        ),
      );
    }
  }
  return issues;
}

bool _safeReviewerId(String value) {
  return _reviewerIdPattern.hasMatch(value) &&
      !_phonePattern.hasMatch(value) &&
      !value.contains('@');
}

bool isEditorReviewPath(String path) {
  final normalized =
      File(path).absolute.path.replaceAll('\\', '/').toLowerCase();
  return normalized.endsWith('/test/corpus/validation_review.tsv');
}

PrepareReport prepareReviewCopies({
  String sourcePath = editorReviewPath,
  String destination = reviewRoot,
  int batchSize = reviewBatchSize,
}) {
  if (batchSize < 1) {
    throw ArgumentError.value(batchSize, 'batchSize', 'must be at least 1');
  }
  final check = readReviewFile(sourcePath);
  if (!check.ok) {
    throw FormatException(
        check.issues.map((issue) => issue.message).join('\n'));
  }
  final written = <String>[];
  final skipped = <String>[];
  final byCategory = <String, List<ReviewRow>>{};
  for (final row in check.rows) {
    byCategory.putIfAbsent(row.category, () => []).add(row);
  }
  final categories = [
    ...reviewCategories,
    for (final category in byCategory.keys)
      if (!reviewCategories.contains(category)) category,
  ];
  for (final category in categories) {
    final rows = byCategory[category] ?? const <ReviewRow>[];
    final categoryPath = '$destination/categories/$category.tsv';
    _writeUnlessDecided(
      categoryPath,
      rows,
      'Full $category worksheet. Still unreviewed until a person fills it in.',
      written,
      skipped,
    );
    final batchCount =
        rows.isEmpty ? 0 : ((rows.length + batchSize - 1) ~/ batchSize);
    for (var batch = 0; batch < batchCount; batch++) {
      final start = batch * batchSize;
      final end = math.min(start + batchSize, rows.length);
      final label = (batch + 1).toString().padLeft(2, '0');
      final batchPath = '$destination/batches/$category-$label.tsv';
      _writeUnlessDecided(
        batchPath,
        rows.sublist(start, end),
        'Batch $label of $category. Leave native_status as unreviewed until you decide.',
        written,
        skipped,
      );
    }
  }
  return PrepareReport(written, skipped);
}

void _writeUnlessDecided(
  String path,
  List<ReviewRow> rows,
  String banner,
  List<String> written,
  List<String> skipped,
) {
  final existing = File(path);
  if (existing.existsSync()) {
    final current = readReviewFile(path);
    final decided = current.rows.any(
      (row) =>
          row.isDecision ||
          row.reviewerSpelling.isNotEmpty ||
          row.acceptedAlternatives.isNotEmpty ||
          row.reviewerId.isNotEmpty ||
          row.dialect.isNotEmpty ||
          row.reviewerNote.isNotEmpty,
    );
    if (decided) {
      skipped.add(path);
      return;
    }
  }
  writeReviewFile(path, rows, banner: banner);
  written.add(path);
}

void writeReviewFile(String path, List<ReviewRow> rows,
    {required String banner}) {
  if (isEditorReviewPath(path)) {
    throw ArgumentError.value(
        path, 'path', 'refusing to write the editor packet');
  }
  final file = File(path);
  file.parent.createSync(recursive: true);
  final buffer = StringBuffer()
    ..writeln('# $banner')
    ..writeln(
        '# roman and editor_gujarati are copied from the editor packet. Do not delete them.')
    ..writeln(
        '# native_status: unreviewed | accepted | incorrect | ambiguous | dialect')
    ..writeln(
        '# reviewer_spelling is the primary spelling you approve. Required for accepted, ambiguous, and dialect.')
    ..writeln(
        '# accepted_alternatives: other approved spellings, separated by |.')
    ..writeln(
        '# dialect: a short variety label such as standard or kathiyawadi. Required when status is dialect.')
    ..writeln(
        '# reviewer_id: a code such as r1. Do not write a name, email, or phone number.')
    ..writeln('# reviewer_note: spelling notes only.')
    ..writeln('# This file is not validated while native_status is unreviewed.')
    ..writeln(reviewColumns.join('\t'));
  for (final row in rows) {
    buffer.writeln(row.cells.join('\t'));
  }
  file.writeAsStringSync(buffer.toString());
}

ImportReport importApprovedReviews(
  List<String> paths, {
  String outputPath = '$reviewRoot/validated/reviews.tsv',
}) {
  if (isEditorReviewPath(outputPath)) {
    throw ArgumentError.value(
        outputPath, 'outputPath', 'refusing to write the editor packet');
  }
  for (final path in paths) {
    if (isEditorReviewPath(path)) {
      throw ArgumentError.value(
          path, 'paths', 'refusing to import by rewriting the editor packet');
    }
  }
  final existing = File(outputPath).existsSync()
      ? readReviewFile(outputPath)
      : const ReviewCheck([], []);
  if (!existing.ok) {
    throw FormatException(existing.issues
        .where((issue) => issue.isError)
        .map((issue) => issue.message)
        .join('\n'));
  }
  final merged = <String, ReviewRow>{
    for (final row in existing.rows) row.id: row,
  };
  var added = 0;
  var replaced = 0;
  var skipped = 0;
  for (final path in paths) {
    final check = readReviewFile(path);
    if (!check.ok) {
      throw FormatException(check.issues
          .where((issue) => issue.isError)
          .map((issue) => issue.message)
          .join('\n'));
    }
    for (final row in check.rows) {
      if (!row.isDecision) {
        skipped++;
        continue;
      }
      if (merged.containsKey(row.id)) {
        replaced++;
      } else {
        added++;
      }
      merged[row.id] = row;
    }
  }
  final ordered = merged.values.toList()
    ..sort((a, b) => _idRank(a.id).compareTo(_idRank(b.id)));
  writeReviewFile(
    outputPath,
    ordered,
    banner:
        'Imported human decisions only. Unreviewed rows are omitted. This is not the editor packet.',
  );
  return ImportReport(
    added: added,
    replaced: replaced,
    skippedUnreviewed: skipped,
    outputPath: outputPath,
  );
}

int _idRank(String id) => int.tryParse(id) ?? 1 << 30;

void exportValidatedCorpus({
  String reviewsPath = '$reviewRoot/validated/reviews.tsv',
  String outputPath = '$reviewRoot/validated/validated_corpus.tsv',
}) {
  if (isEditorReviewPath(outputPath) || isEditorReviewPath(reviewsPath)) {
    throw ArgumentError(
        'refusing to read or write the editor packet as the validated corpus');
  }
  final rows = File(reviewsPath).existsSync()
      ? readReviewFile(reviewsPath).rows.where((row) => row.isApproved).toList()
      : <ReviewRow>[];
  if (isEditorReviewPath(outputPath)) {
    throw ArgumentError.value(
        outputPath, 'outputPath', 'refusing to overwrite the editor packet');
  }
  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  final buffer = StringBuffer()
    ..writeln(
        '# Approved spellings only. A row is here because a person set native_status and reviewer_spelling.')
    ..writeln('# Unreviewed editor spellings are not included.')
    ..writeln('# An empty body means no human review has been imported.')
    ..writeln(
        'id\tcategory\troman\treviewer_spelling\taccepted_alternatives\tnative_status\tdialect\treviewer_id');
  for (final row in rows) {
    buffer.writeln(
      [
        row.id,
        row.category,
        row.roman,
        row.reviewerSpelling,
        row.alternatives.join('|'),
        row.nativeStatus,
        row.dialect,
        row.reviewerId,
      ].join('\t'),
    );
  }
  file.writeAsStringSync(buffer.toString());
}

ReviewStats collectStats({
  String sourcePath = editorReviewPath,
  String reviewsPath = '$reviewRoot/validated/reviews.tsv',
  GujaratiTransliterator? engine,
}) {
  final source = readReviewFile(sourcePath);
  final reviewedRows = File(reviewsPath).existsSync()
      ? readReviewFile(reviewsPath).rows
      : <ReviewRow>[];
  final decisions = reviewedRows.where((row) => row.isDecision).toList();
  final approved = decisions.where((row) => row.isApproved).toList();
  final coverage = <String, CategoryCoverage>{};
  for (final category in reviewCategories) {
    final total = source.rows.where((row) => row.category == category).length;
    final done = decisions.where((row) => row.category == category).length;
    coverage[category] = CategoryCoverage(total, done);
  }
  return ReviewStats(
    editorRows: source.rows.length,
    reviewed: decisions.length,
    approved: approved.length,
    alternatives:
        approved.fold<int>(0, (sum, row) => sum + row.alternatives.length),
    disputed:
        decisions.where((row) => row.nativeStatus != statusAccepted).length,
    reviewerIds: {
      for (final row in decisions)
        if (row.reviewerId.isNotEmpty) row.reviewerId,
    },
    missingReviewerId: decisions.where((row) => row.reviewerId.isEmpty).length,
    editorDisputeNotes: source.rows
        .where((row) => row.dispute.isNotEmpty || row.note.isNotEmpty)
        .length,
    byCategory: coverage,
    score: scoreApproved(approved, engine: engine),
  );
}

VariantScore scoreApproved(
  List<ReviewRow> rows, {
  GujaratiTransliterator? engine,
}) {
  final approved = rows.where((row) => row.isApproved).toList();
  if (approved.isEmpty) return VariantScore.unmeasured;
  final transliterator = engine ?? GujaratiTransliterator();
  var strictTop1 = 0;
  var variantTop1 = 0;
  var strictTop3 = 0;
  var variantTop3 = 0;
  var cerEdits = 0;
  var cerChars = 0;
  var variantCerEdits = 0;
  var sentenceRows = 0;
  var strictSentenceExact = 0;
  var variantSentenceExact = 0;
  for (final row in approved) {
    final result = transliterator.transliterate(row.roman);
    final suggestions = transliterator.suggest(row.roman, limit: 3);
    final texts = <String>{
      result.text,
      for (final suggestion in suggestions) suggestion.text,
    };
    final approvedSpellings = row.approvedSpellings.toSet();
    if (result.text == row.reviewerSpelling) strictTop1++;
    if (approvedSpellings.contains(result.text)) variantTop1++;
    if (texts.contains(row.reviewerSpelling)) strictTop3++;
    if (approvedSpellings.any(texts.contains)) variantTop3++;
    final actual = result.text.runes.toList();
    final primary = row.reviewerSpelling.runes.toList();
    cerEdits += levenshtein(primary, actual);
    cerChars += math.max(primary.length, 1);
    var best = levenshtein(primary, actual);
    for (final alternate in row.alternatives) {
      best = math.min(best, levenshtein(alternate.runes.toList(), actual));
    }
    variantCerEdits += best;
    if (row.category == 'sentence') {
      sentenceRows++;
      if (result.text == row.reviewerSpelling) strictSentenceExact++;
      if (approvedSpellings.contains(result.text)) variantSentenceExact++;
    }
  }
  return VariantScore(
    scored: approved.length,
    strictTop1: strictTop1,
    variantTop1: variantTop1,
    strictTop3: strictTop3,
    variantTop3: variantTop3,
    cerEdits: cerEdits,
    cerChars: cerChars,
    variantCerEdits: variantCerEdits,
    sentenceRows: sentenceRows,
    strictSentenceExact: strictSentenceExact,
    variantSentenceExact: variantSentenceExact,
  );
}

int levenshtein(List<int> left, List<int> right) {
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;
  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 0; i < left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < right.length; j++) {
      final cost = left[i] == right[j] ? 0 : 1;
      current[j + 1] = math.min(
        current[j] + 1,
        math.min(previous[j + 1] + 1, previous[j] + cost),
      );
    }
    previous = current;
  }
  return previous.last;
}

String ratioText(int hits, int total) {
  if (total == 0) return 'not_measured';
  return (hits / total).toStringAsFixed(3);
}

String cerText(int edits, int chars, int scored) {
  if (scored == 0 || chars == 0) return 'not_measured';
  return (edits / chars).toStringAsFixed(3);
}

void printStats(ReviewStats stats) {
  stdout.writeln(
    'REVIEW_STATS editor_rows=${stats.editorRows} reviewed=${stats.reviewed} '
    'approved_spellings=${stats.approved} accepted_alternatives=${stats.alternatives} '
    'disputed=${stats.disputed} reviewers=${stats.reviewerIds.length} '
    'missing_reviewer_id=${stats.missingReviewerId} '
    'editor_notes=${stats.editorDisputeNotes}',
  );
  if (stats.reviewerIds.isEmpty) {
    stdout.writeln('REVIEWERS none');
  } else {
    stdout.writeln('REVIEWERS ${stats.reviewerIds.join(",")}');
  }
  for (final category in reviewCategories) {
    final coverage = stats.byCategory[category]!;
    stdout.writeln(
        'REVIEW_COVERAGE $category reviewed=${coverage.reviewed} total=${coverage.total}');
  }
  final score = stats.score;
  stdout.writeln(
    'REVIEW_ACCURACY scored=${score.scored} '
    'strict_top1=${ratioText(score.strictTop1, score.scored)} '
    'variant_top1=${ratioText(score.variantTop1, score.scored)} '
    'strict_top3=${ratioText(score.strictTop3, score.scored)} '
    'top3=${ratioText(score.variantTop3, score.scored)} '
    'cer=${cerText(score.cerEdits, score.cerChars, score.scored)} '
    'variant_cer=${cerText(score.variantCerEdits, score.cerChars, score.scored)} '
    'sentence_exact=${ratioText(score.strictSentenceExact, score.sentenceRows)} '
    'sentence_variant_exact=${ratioText(score.variantSentenceExact, score.sentenceRows)} '
    'sentence_rows=${score.sentenceRows}',
  );
  stdout.writeln(
    'REVIEW_NOTE unreviewed spellings are excluded; '
    'native-speaker accuracy is not measured while reviewed=0',
  );
}
