import '../dictionary/word_dictionary.dart';
import '../utils/input_normalizer.dart';

/// Decides when a whole input is English prose rather than Roman Gujarati.
///
/// A curated loan inside a Gujarati sentence is still transliterated. A
/// sentence is left in Latin only when every word is an English function
/// word, a known loan, or a plain English word, and at least one function
/// word is present. One Gujarati lexicon word keeps the sentence in
/// transliteration.
abstract final class EnglishGuard {
  /// A single English function word or plain word, such as `the` or `send`.
  static bool isPlainOrFunction(String key) =>
      _function.contains(key) || _plain.contains(key);

  /// Whether [words] should stay in the Latin script.
  static bool isEnglishSentence(
    WordDictionary dictionary,
    List<String> words,
  ) {
    if (words.length < 4) return false;
    var functions = 0;
    for (final word in words) {
      final key = dictionaryKey(word);
      if (key.isEmpty) continue;
      final entries = dictionary.lookupWord(key);
      final loan = entries.isNotEmpty &&
          entries.every((entry) => entry.kind == EntryKind.loan);
      final gujarati = entries.any((entry) => entry.kind != EntryKind.loan);
      if (gujarati && !_ambiguous.contains(key)) return false;
      if (_function.contains(key)) {
        functions++;
        continue;
      }
      if (loan || _plain.contains(key)) continue;
      return false;
    }
    return functions > 0;
  }
}

const Set<String> _ambiguous = {
  'a',
  'am',
  'an',
  'as',
  'at',
  'by',
  'do',
  'go',
  'he',
  'hi',
  'in',
  'ma',
  'me',
  'no',
  'on',
  'or',
  'so',
  'to',
  'up',
  'we',
};

const Set<String> _function = {
  'a',
  'about',
  'also',
  'am',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'because',
  'been',
  'but',
  'by',
  'can',
  'could',
  'did',
  'do',
  'does',
  'for',
  'from',
  'had',
  'has',
  'have',
  'he',
  'her',
  'here',
  'his',
  'how',
  'i',
  'if',
  'in',
  'into',
  'is',
  'it',
  'just',
  'may',
  'me',
  'must',
  'my',
  'not',
  'of',
  'on',
  'or',
  'our',
  'shall',
  'she',
  'should',
  'so',
  'than',
  'that',
  'the',
  'their',
  'them',
  'then',
  'there',
  'these',
  'they',
  'this',
  'those',
  'to',
  'very',
  'was',
  'we',
  'were',
  'what',
  'when',
  'where',
  'which',
  'who',
  'why',
  'will',
  'with',
  'would',
  'you',
  'your',
};

const Set<String> _plain = {
  'after',
  'again',
  'already',
  'anything',
  'back',
  'before',
  'big',
  'came',
  'come',
  'day',
  'everyone',
  'everything',
  'first',
  'gave',
  'get',
  'give',
  'going',
  'got',
  'know',
  'last',
  'later',
  'like',
  'long',
  'look',
  'make',
  'much',
  'need',
  'new',
  'next',
  'nothing',
  'now',
  'old',
  'only',
  'over',
  'people',
  'read',
  'really',
  'said',
  'saw',
  'say',
  'see',
  'send',
  'sent',
  'small',
  'someone',
  'something',
  'still',
  'take',
  'tell',
  'think',
  'tomorrow',
  'took',
  'under',
  'want',
  'week',
  'write',
  'year',
  'yesterday',
};
