import 'dart:io';

import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:gujarati_transliterator/src/rules/conjunct_rules.dart';
import 'package:gujarati_transliterator/src/rules/consonant_rules.dart';
import 'package:gujarati_transliterator/src/rules/vowel_rules.dart';

/// Writes the checked corpus files under test/corpus.
///
/// Verified rows are the winning spelling of each hand-written lexicon entry.
/// Rule rows are consonant-plus-vowel forms taken from the mapping tables.
/// The phonetic engine is checked against those tables before a rule row is
/// written, so the file is not a copy of the parser's own output.
void main() {
  final engine = GujaratiTransliterator();
  final verified = StringBuffer()
    ..writeln(
      '# Hand-written lexicon spellings. origin, roman, Gujarati, category.',
    )
    ..writeln(
      '# These are not a held-out exam. Intelligent mode is expected to select them.',
    );
  final alternates = StringBuffer()
    ..writeln(
      '# Lower-frequency spellings. origin, roman, Gujarati, category.',
    );

  final best = <String, DictionaryEntry>{};
  final grouped = <String, List<DictionaryEntry>>{};
  for (final entry in engine.dictionary.entries) {
    grouped.putIfAbsent(entry.roman, () => []).add(entry);
    final current = best[entry.roman];
    if (current == null || entry.frequency > current.frequency) {
      best[entry.roman] = entry;
    }
  }
  final verifiedKeys = best.keys.toList()..sort();
  for (final key in verifiedKeys) {
    final entry = best[key]!;
    verified.writeln(
      'verified\t${entry.roman}\t${entry.gujarati}\t${entry.kind.name}',
    );
    final others = grouped[key]!
        .where((item) => item.gujarati != entry.gujarati)
        .toList()
      ..sort((a, b) => a.gujarati.compareTo(b.gujarati));
    for (final other in others) {
      alternates.writeln(
        'alternate\t${other.roman}\t${other.gujarati}\t${other.kind.name}',
      );
    }
  }

  final rules = StringBuffer()
    ..writeln(
      '# Rule-validated consonant plus vowel. origin, roman, Gujarati, category.',
    )
    ..writeln(
      '# Expected text is the consonant plus the vowel sign from the mapping tables.',
    );
  final phonetic = GujaratiTransliterator(dictionary: WordDictionary());
  final consonants = <ConsonantRule>[
    ...ConjunctRules.clusters,
    ...ConsonantRules.all,
  ];
  var ruleCount = 0;
  for (final consonant in consonants) {
    for (final vowel in VowelRules.all) {
      final roman = '${consonant.roman}${vowel.roman}';
      final expected = '${consonant.gujarati}${vowel.matra ?? ''}';
      final actual = phonetic
          .transliterate(roman, mode: TransliterationMode.phonetic)
          .text;
      if (actual != expected) {
        stderr
            .writeln('Rule mismatch $roman expected $expected actual $actual');
        exitCode = 1;
        continue;
      }
      rules.writeln('rule\t$roman\t$expected\trule');
      ruleCount++;
    }
  }

  Directory('test/corpus').createSync(recursive: true);
  File('test/corpus/verified_pairs.tsv').writeAsStringSync(verified.toString());
  File('test/corpus/alternate_spellings.tsv')
      .writeAsStringSync(alternates.toString());
  File('test/corpus/rule_pairs.tsv').writeAsStringSync(rules.toString());
  stdout.writeln(
    'Wrote ${verifiedKeys.length} verified, '
    '${alternates.toString().split('\n').where((line) => line.startsWith('alternate')).length} alternates, '
    '$ruleCount rule pairs.',
  );
  if (exitCode != 0) {
    stderr.writeln('Rule export failed.');
  }
}
