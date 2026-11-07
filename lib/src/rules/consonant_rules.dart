/// A roman consonant token and the Gujarati letters it writes.
class ConsonantRule {
  /// Creates a consonant mapping.
  const ConsonantRule(this.roman, this.gujarati);

  /// Roman token, matched by longest prefix.
  final String roman;

  /// Gujarati consonant, including a nukta when the sound needs one.
  final String gujarati;
}

/// Default and explicit consonant spellings.
///
/// Unmarked `t`, `d`, and `n` are dental. Retroflex letters use a dot or an
/// internal capital: `.t` / `T` is ટ, `.n` / `N` is ણ, `.sh` / `Sh` is ષ.
abstract final class ConsonantRules {
  /// Single consonants and digraphs.
  static const all = <ConsonantRule>[
    ConsonantRule('chh', 'છ'),
    ConsonantRule('kh', 'ખ'),
    ConsonantRule('gh', 'ઘ'),
    ConsonantRule('th', 'થ'),
    ConsonantRule('dh', 'ધ'),
    ConsonantRule('ph', 'ફ'),
    ConsonantRule('bh', 'ભ'),
    ConsonantRule('sh', 'શ'),
    ConsonantRule('.th', 'ઠ'),
    ConsonantRule('.dh', 'ઢ'),
    ConsonantRule('.sh', 'ષ'),
    ConsonantRule('.ng', 'ઙ'),
    ConsonantRule('.ny', 'ઞ'),
    ConsonantRule('.kh', 'ખ઼'),
    ConsonantRule('.t', 'ટ'),
    ConsonantRule('.d', 'ડ'),
    ConsonantRule('.n', 'ણ'),
    ConsonantRule('.l', 'ળ'),
    ConsonantRule('.g', 'ગ઼'),
    ConsonantRule('.f', 'ફ઼'),
    ConsonantRule('k', 'ક'),
    ConsonantRule('g', 'ગ'),
    ConsonantRule('c', 'ક'),
    ConsonantRule('ch', 'ચ'),
    ConsonantRule('j', 'જ'),
    ConsonantRule('jh', 'ઝ'),
    ConsonantRule('t', 'ત'),
    ConsonantRule('d', 'દ'),
    ConsonantRule('n', 'ન'),
    ConsonantRule('p', 'પ'),
    ConsonantRule('f', 'ફ'),
    ConsonantRule('b', 'બ'),
    ConsonantRule('m', 'મ'),
    ConsonantRule('y', 'ય'),
    ConsonantRule('r', 'ર'),
    ConsonantRule('l', 'લ'),
    ConsonantRule('v', 'વ'),
    ConsonantRule('w', 'વ'),
    ConsonantRule('s', 'સ'),
    ConsonantRule('h', 'હ'),
    ConsonantRule('q', 'ક઼'),
    ConsonantRule('z', 'જ઼'),
    ConsonantRule('x', 'ક્ષ'),
  ];
}
