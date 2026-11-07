import 'consonant_rules.dart';

/// Conjuncts that are not just "consonant plus consonant".
///
/// `k` + `sh` would be ક્શ. The letter ક્ષ is ક + virama + ષ, so `ksh` and `x`
/// are their own tokens. જ્ઞ is the same kind of case.
abstract final class ConjunctRules {
  /// Cluster tokens parsed as one consonant.
  static const clusters = <ConsonantRule>[
    ConsonantRule('ksh', 'ક્ષ'),
    ConsonantRule('dny', 'જ્ઞ'),
    ConsonantRule('gy', 'જ્ઞ'),
    ConsonantRule('jn', 'જ્ઞ'),
    ConsonantRule('gn', 'જ્ઞ'),
  ];
}
