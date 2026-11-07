import '../rules/consonant_rules.dart';
import '../rules/conjunct_rules.dart';
import '../rules/matra_rules.dart';
import '../rules/vowel_rules.dart';
import '../utils/input_normalizer.dart';
import '../utils/unicode_utils.dart';

enum _PhonemeKind { vowel, consonant, modifier }

class _Phoneme {
  const _Phoneme.vowel(this.text, this.matra) : kind = _PhonemeKind.vowel;
  const _Phoneme.consonant(this.text)
      : kind = _PhonemeKind.consonant,
        matra = null;
  const _Phoneme.modifier(this.text)
      : kind = _PhonemeKind.modifier,
        matra = null;

  final _PhonemeKind kind;
  final String text;
  final String? matra;
}

class _TrieNode {
  final Map<String, _TrieNode> children = {};
  _Phoneme? phoneme;
}

class _Match {
  const _Match(this.phoneme, this.end);
  final _Phoneme phoneme;
  final int end;
}

/// Longest-match phonetic parser.
///
/// A consonant keeps the inherent vowel until another vowel is typed. Two
/// consonants in a row join with virama. A final consonant is not given a
/// halant, so `kem` is કેમ. An apostrophe asks for the halant explicitly.
class PhoneticParser {
  PhoneticParser._() : _root = _buildRoot();

  /// Shared parser. The trie does not change after construction.
  factory PhoneticParser() => instance;

  /// The process-wide parser.
  static final PhoneticParser instance = PhoneticParser._();

  final _TrieNode _root;

  /// Transliterates one already prepared token.
  String parse(String prepared) {
    if (prepared.isEmpty) return '';
    final output = StringBuffer();
    var pendingConsonant = false;
    var index = 0;
    while (index < prepared.length) {
      final match = _longest(prepared, index);
      if (match == null) {
        final character = prepared[index];
        if (character == "'") {
          if (pendingConsonant) {
            output.write(GujaratiUnicode.virama);
            pendingConsonant = false;
          }
        } else {
          pendingConsonant = false;
          output.write(character);
        }
        index++;
        continue;
      }
      switch (match.phoneme.kind) {
        case _PhonemeKind.vowel:
          if (pendingConsonant) {
            final matra = match.phoneme.matra;
            if (matra != null) output.write(matra);
            pendingConsonant = false;
          } else {
            output.write(match.phoneme.text);
          }
        case _PhonemeKind.consonant:
          if (pendingConsonant) output.write(GujaratiUnicode.virama);
          output.write(match.phoneme.text);
          pendingConsonant = true;
        case _PhonemeKind.modifier:
          output.write(match.phoneme.text);
          pendingConsonant = false;
      }
      index = match.end;
    }
    return output.toString();
  }

  /// Prepares [word] and parses it.
  String transliterateWord(String word) => parse(preparePhoneticInput(word));

  _Match? _longest(String source, int start) {
    var node = _root;
    _Phoneme? phoneme;
    var end = start;
    var index = start;
    while (index < source.length) {
      final next = node.children[source[index]];
      if (next == null) break;
      node = next;
      index++;
      if (node.phoneme != null) {
        phoneme = node.phoneme;
        end = index;
      }
    }
    if (phoneme == null) return null;
    return _Match(phoneme, end);
  }

  static _TrieNode _buildRoot() {
    final root = _TrieNode();
    void insert(String roman, _Phoneme phoneme) {
      var node = root;
      for (final character in roman.split('')) {
        node = node.children.putIfAbsent(character, _TrieNode.new);
      }
      node.phoneme = phoneme;
    }

    for (final rule in VowelRules.all) {
      insert(rule.roman, _Phoneme.vowel(rule.independent, rule.matra));
    }
    for (final rule in <ConsonantRule>[
      ...ConjunctRules.clusters,
      ...ConsonantRules.all,
    ]) {
      insert(rule.roman, _Phoneme.consonant(rule.gujarati));
    }
    for (final rule in MatraRules.modifiers) {
      insert(rule.roman, _Phoneme.modifier(rule.sign));
    }
    return root;
  }
}
