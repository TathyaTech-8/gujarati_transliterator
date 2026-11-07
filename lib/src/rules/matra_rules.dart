/// A mark that attaches to the syllable just written.
class SignRule {
  /// Creates a sign mapping.
  const SignRule(this.roman, this.sign);

  /// Roman token.
  final String roman;

  /// Unicode sign.
  final String sign;
}

/// Diacritics that are not vowels: anusvara, visarga, and chandrabindu.
abstract final class MatraRules {
  /// Explicit marker tokens.
  ///
  /// `.m` writes anusvara, `.h` writes visarga, and `~` writes chandrabindu.
  /// Vowel signs live with the vowel rules because each vowel has both an
  /// independent letter and a dependent sign.
  static const modifiers = <SignRule>[
    SignRule('.m', '\u0A82'),
    SignRule('.h', '\u0A83'),
    SignRule('~', '\u0A81'),
  ];
}
