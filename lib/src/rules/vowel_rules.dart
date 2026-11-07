/// Independent vowels and the matra used after a consonant.
class VowelRule {
  /// Creates a vowel mapping. A null [matra] means the inherent vowel અ.
  const VowelRule(this.roman, this.independent, [this.matra]);

  /// Roman token, matched by longest prefix.
  final String roman;

  /// Vowel written when no consonant is waiting.
  final String independent;

  /// Dependent sign written after a consonant. Null for inherent અ.
  final String? matra;
}

/// Gujarati vowel inventory used by the phonetic parser.
abstract final class VowelRules {
  /// Longer tokens are listed first only for readability. The parser uses a trie.
  static const all = <VowelRule>[
    VowelRule('aa', 'આ', 'ા'),
    VowelRule('ee', 'ઈ', 'ી'),
    VowelRule('ii', 'ઈ', 'ી'),
    VowelRule('oo', 'ઊ', 'ૂ'),
    VowelRule('uu', 'ઊ', 'ૂ'),
    VowelRule('ai', 'ઐ', 'ૈ'),
    VowelRule('au', 'ઔ', 'ૌ'),
    VowelRule('ou', 'ઔ', 'ૌ'),
    VowelRule('.lll', 'ૡ', 'ૣ'),
    VowelRule('.ll', 'ઌ', 'ૢ'),
    VowelRule('.rr', 'ૠ', 'ૄ'),
    VowelRule('.r', 'ઋ', 'ૃ'),
    VowelRule('.e', 'ઍ', 'ૅ'),
    VowelRule('.o', 'ઑ', 'ૉ'),
    VowelRule('a', 'અ'),
    VowelRule('e', 'એ', 'ે'),
    VowelRule('i', 'ઇ', 'િ'),
    VowelRule('o', 'ઓ', 'ો'),
    VowelRule('u', 'ઉ', 'ુ'),
  ];
}
