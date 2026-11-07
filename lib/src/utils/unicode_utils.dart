/// Gujarati Unicode helpers.
///
/// Conjuncts are normal consonant + virama + consonant sequences. The engine
/// does not emit font-specific legacy encodings.
abstract final class GujaratiUnicode {
  /// First code point of the Gujarati block.
  static const int blockStart = 0x0A80;

  /// Last code point of the Gujarati block.
  static const int blockEnd = 0x0AFF;

  /// Halant, U+0ACD.
  static const String virama = '\u0ACD';

  /// Anusvara, U+0A82.
  static const String anusvara = '\u0A82';

  /// Chandrabindu, U+0A81.
  static const String chandrabindu = '\u0A81';

  /// Visarga, U+0A83.
  static const String visarga = '\u0A83';

  /// Nukta, U+0ABC.
  static const String nukta = '\u0ABC';

  /// Whether [text] contains a character from the Gujarati block.
  static bool containsGujarati(String text) {
    for (final rune in text.runes) {
      if (rune >= blockStart && rune <= blockEnd) return true;
    }
    return false;
  }

  /// Joins [consonants] with virama so the shaping engine can form a conjunct.
  static String conjunct(List<String> consonants) => consonants.join(virama);

  /// Alternate spellings that use anusvara for a two-consonant nasal cluster.
  ///
  /// A cluster such as ન્ત can also be written ંત. Longer clusters such as
  /// ન્દ્ર are left alone, because replacing the nasal would split them.
  static List<String> anusvaraVariants(String text) {
    final runes = text.runes.toList(growable: false);
    final variants = <String>[];
    for (var i = 0; i < runes.length - 2 && variants.length < 4; i++) {
      final nasal = runes[i] == 0x0AA8 || runes[i] == 0x0AAE;
      if (!nasal || runes[i + 1] != 0x0ACD) continue;
      // A word-initial nasal cluster stays a conjunct. Replacing it would
      // leave a bare anusvara with nothing to attach to.
      if (i == 0) continue;
      if (i > 0 && runes[i - 1] == 0x0ACD) continue;
      final consonant = runes[i + 2];
      if (consonant < 0x0A95 || consonant > 0x0AB9) continue;
      if (i + 3 < runes.length && runes[i + 3] == 0x0ACD) continue;
      variants.add(
        String.fromCharCodes(<int>[
          ...runes.take(i),
          0x0A82,
          ...runes.skip(i + 2),
        ]),
      );
    }
    return variants;
  }

  /// Other readings of a રિ or રુ sequence.
  ///
  /// `ri` and `ru` are ambiguous. The phonetic parse keeps ર plus a vowel
  /// sign, which is right for ત્રિ and રુચિ. કૃષ્ણ and ઋષિ use vocalic ર
  /// instead, so each such sequence also offers that reading. Only the first
  /// few sites are rewritten, and the original string is not one of them.
  static List<String> vocalicRVariants(String text) {
    final runes = text.runes.toList(growable: false);
    final variants = <String>[];

    void add(List<int> next) {
      if (variants.length >= 4) return;
      final value = String.fromCharCodes(next);
      if (value != text && !variants.contains(value)) variants.add(value);
    }

    if (runes.length >= 2 &&
        runes[0] == 0x0AB0 &&
        (runes[1] == 0x0ABF || runes[1] == 0x0AC1)) {
      add(<int>[0x0A8B, ...runes.skip(2)]);
    }

    for (var i = 0; i < runes.length - 2 && variants.length < 4; i++) {
      if (runes[i] != 0x0ACD || runes[i + 1] != 0x0AB0) continue;
      final sign = runes[i + 2];
      if (sign != 0x0ABF && sign != 0x0AC1) continue;
      if (i == 0) continue;
      var consonantAt = i - 1;
      if (runes[consonantAt] == 0x0ABC) consonantAt--;
      if (consonantAt < 0) continue;
      final consonant = runes[consonantAt];
      if (consonant < 0x0A95 || consonant > 0x0AB9) continue;
      add(<int>[
        ...runes.take(i),
        0x0AC3,
        ...runes.skip(i + 3),
      ]);
    }
    return variants;
  }

  /// One-edit readings of an unknown word.
  ///
  /// Each edit changes a single ambiguous choice: the first inherent vowel,
  /// the last vowel, one dental or liquid consonant, a final diphthong, or
  /// anusvara versus chandrabindu. A lower rank is the edit a Gujarati
  /// type-in more often omits. The plain phonetic reading is not included.
  static List<OrthographicEdit> orthographicEdits(String text) {
    final runes = text.runes.toList(growable: false);
    if (runes.isEmpty) return const [];
    final edits = <OrthographicEdit>[];

    void add(List<int> next, int rank) {
      final value = String.fromCharCodes(next);
      if (value == text || edits.any((edit) => edit.text == value)) return;
      edits.add(OrthographicEdit(value, rank));
    }

    final end = _spokenEnd(runes);
    if (end > 0) {
      final last = runes[end - 1];
      if (last == 0x0ABF) {
        add(_replaceAt(runes, end - 1, 0x0AC0), 2);
      } else if (last == 0x0AC1) {
        add(_replaceAt(runes, end - 1, 0x0AC2), 2);
      } else if (last == 0x0AC7) {
        add(_replaceAt(runes, end - 1, 0x0AC8), 5);
      } else if (last == 0x0ACB) {
        add(_replaceAt(runes, end - 1, 0x0ACC), 5);
      } else if (last == 0x0ABC || _isConsonant(last)) {
        add(_insertAt(runes, end, 0x0ABE), 2);
      }
    }

    final first = _firstInherent(runes);
    if (first != null) add(_insertAt(runes, first, 0x0ABE), 1);

    for (var i = runes.length - 1; i >= 0; i--) {
      final mapped = _retroflex[runes[i]];
      if (mapped == null) continue;
      add(_replaceAt(runes, i, mapped), 3);
      break;
    }

    for (var i = 0; i < runes.length; i++) {
      if (runes[i] != 0x0A82) continue;
      add(_replaceAt(runes, i, 0x0A81), 4);
      break;
    }
    return edits;
  }

  static const Map<int, int> _retroflex = {
    0x0AA8: 0x0AA3,
    0x0AA4: 0x0A9F,
    0x0AA6: 0x0AA1,
    0x0AB2: 0x0AB3,
    0x0AA5: 0x0AA0,
    0x0AA7: 0x0AA2,
  };

  static int _spokenEnd(List<int> runes) {
    var end = runes.length;
    while (end > 0 && _isModifier(runes[end - 1])) {
      end--;
    }
    return end;
  }

  static int? _firstInherent(List<int> runes) {
    final end = _spokenEnd(runes);
    int? lastConsonant;
    if (end > 0 && (_isConsonant(runes[end - 1]) || runes[end - 1] == 0x0ABC)) {
      lastConsonant = end - 1;
      if (runes[lastConsonant] == 0x0ABC && lastConsonant > 0) {
        lastConsonant--;
      }
    }
    for (var i = 0; i < runes.length; i++) {
      if (!_isConsonant(runes[i])) continue;
      if (i > 0 && runes[i - 1] == 0x0ACD) continue;
      var after = i + 1;
      if (after < runes.length && runes[after] == 0x0ABC) after++;
      if (after < runes.length && runes[after] == 0x0ACD) continue;
      if (after < runes.length && _isMatra(runes[after])) continue;
      if (i == lastConsonant) continue;
      return after;
    }
    return null;
  }

  static List<int> _replaceAt(List<int> runes, int index, int value) {
    return <int>[...runes.take(index), value, ...runes.skip(index + 1)];
  }

  static List<int> _insertAt(List<int> runes, int index, int value) {
    return <int>[...runes.take(index), value, ...runes.skip(index)];
  }

  static bool _isConsonant(int rune) => rune >= 0x0A95 && rune <= 0x0AB9;

  static bool _isModifier(int rune) =>
      rune == 0x0A81 || rune == 0x0A82 || rune == 0x0A83;

  static bool _isMatra(int rune) =>
      (rune >= 0x0ABE && rune <= 0x0AC5) ||
      (rune >= 0x0AC7 && rune <= 0x0AC9) ||
      (rune >= 0x0ACB && rune <= 0x0ACC) ||
      rune == 0x0AE2 ||
      rune == 0x0AE3;
}

/// A single alternate spelling and its preference rank.
class OrthographicEdit {
  /// Creates an edit. A smaller [rank] is offered ahead of a larger one.
  const OrthographicEdit(this.text, this.rank);

  /// Alternate Gujarati spelling.
  final String text;

  /// Preference among edits. 1 is the strongest.
  final int rank;
}
