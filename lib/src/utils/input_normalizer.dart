import '../models/transliteration_result.dart';

/// A raw slice of user input before transliteration.
class InputToken {
  /// Creates a token.
  const InputToken(this.text, this.type);

  /// Exact substring from the input.
  final String text;

  /// Classification used to decide what is transliterated.
  final SpanType type;
}

/// Case folding and tokenization for phonetic input.
abstract final class InputNormalizer {
  /// Strips a leading byte-order mark. Spacing is preserved.
  static String normalize(String input) {
    if (input.startsWith('\uFEFF')) return input.substring(1);
    return input;
  }

  /// Splits [input] into words, numbers, whitespace, and punctuation.
  ///
  /// Dots that introduce a phonetic marker, such as `.t`, stay inside the
  /// word. A dot at the end of a sentence stays punctuation.
  static List<InputToken> tokenize(String input) {
    final source = normalize(input);
    final tokens = <InputToken>[];
    var index = 0;
    while (index < source.length) {
      final unit = source.codeUnitAt(index);
      if (unit == 0x20 || unit == 0x09) {
        final end = _scan(source, index, _isSpaceOrTab);
        tokens
            .add(InputToken(source.substring(index, end), SpanType.whitespace));
        index = end;
      } else if (unit == 0x0A || unit == 0x0D) {
        if (unit == 0x0D &&
            index + 1 < source.length &&
            source.codeUnitAt(index + 1) == 0x0A) {
          tokens.add(const InputToken('\r\n', SpanType.whitespace));
          index += 2;
        } else {
          tokens.add(InputToken(source[index], SpanType.whitespace));
          index++;
        }
      } else if (_isDigit(unit)) {
        final end = _scan(source, index, _isDigit);
        tokens.add(InputToken(source.substring(index, end), SpanType.number));
        index = end;
      } else if (_startsWord(source, index)) {
        var end = index + 1;
        while (end < source.length && _continuesWord(source, end)) {
          end++;
        }
        tokens.add(InputToken(source.substring(index, end), SpanType.word));
        index = end;
      } else if (unit > 0x7F) {
        final end = _scan(source, index, (value) => value > 0x7F);
        tokens.add(
          InputToken(source.substring(index, end), SpanType.passthrough),
        );
        index = end;
      } else {
        final end = _scan(source, index, _isAsciiPunctuation);
        tokens.add(
          InputToken(source.substring(index, end), SpanType.punctuation),
        );
        index = end;
      }
    }
    return tokens;
  }
}

/// Dictionary and custom-mapping key. Case is ignored. Marker dots are kept.
String dictionaryKey(String word) => word.trim().toLowerCase();

/// Key for a word or a phrase. Punctuation is dropped and spacing is collapsed.
String normalizeMappingKey(String input) {
  final words = InputNormalizer.tokenize(input)
      .where((token) => token.type == SpanType.word)
      .map((token) => dictionaryKey(token.text));
  return words.join(' ');
}

/// Rewrites internal capitals into explicit phonetic markers.
///
/// Sentence case and all-caps words are only lowercased, so a leading `S`
/// stays `sh` rather than retroflex `ષ`. An internal `T` becomes `.t`.
String preparePhoneticInput(String word) {
  if (_casefoldEntirely(word)) return word.toLowerCase();
  final buffer = StringBuffer();
  var lastWasDot = false;
  void writeMarker(String marker) {
    buffer.write(lastWasDot ? marker.substring(1) : marker);
    lastWasDot = false;
  }

  for (var i = 0; i < word.length; i++) {
    final current = word[i];
    final next = i + 1 < word.length ? word[i + 1] : '';
    if (current == 'T' && next == 'h') {
      writeMarker('.th');
      i++;
      continue;
    }
    if (current == 'T') {
      writeMarker('.t');
      continue;
    }
    if (current == 'D' && next == 'h') {
      writeMarker('.dh');
      i++;
      continue;
    }
    if (current == 'D') {
      writeMarker('.d');
      continue;
    }
    if (current == 'N') {
      writeMarker('.n');
      continue;
    }
    if (current == 'L') {
      writeMarker('.l');
      continue;
    }
    if (current == 'S' && next == 'h') {
      writeMarker('.sh');
      i++;
      continue;
    }
    if (current == 'M') {
      writeMarker('.m');
      continue;
    }
    if (current == 'H') {
      writeMarker('.h');
      continue;
    }
    buffer.write(current.toLowerCase());
    lastWasDot = current == '.';
  }
  return buffer.toString();
}

bool _casefoldEntirely(String word) {
  final letters = StringBuffer();
  for (final unit in word.codeUnits) {
    if (_isLatin(unit)) letters.writeCharCode(unit);
  }
  final text = letters.toString();
  if (text.isEmpty) return true;
  if (text == text.toLowerCase() || text == text.toUpperCase()) return true;
  return text[0] == text[0].toUpperCase() &&
      text.substring(1) == text.substring(1).toLowerCase();
}

int _scan(String source, int start, bool Function(int unit) accept) {
  var index = start + 1;
  while (index < source.length && accept(source.codeUnitAt(index))) {
    index++;
  }
  return index;
}

bool _isSpaceOrTab(int unit) => unit == 0x20 || unit == 0x09;

bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

bool _isLatin(int unit) =>
    (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);

bool _isAsciiPunctuation(int unit) =>
    unit < 0x80 &&
    !_isLatin(unit) &&
    !_isDigit(unit) &&
    !_isSpaceOrTab(unit) &&
    unit != 0x0A &&
    unit != 0x0D;

bool _startsWord(String source, int index) {
  final unit = source.codeUnitAt(index);
  if (_isLatin(unit)) return true;
  return unit == 0x2E &&
      index + 1 < source.length &&
      _isLatin(source.codeUnitAt(index + 1));
}

bool _continuesWord(String source, int index) {
  final unit = source.codeUnitAt(index);
  if (_isLatin(unit) || unit == 0x27 || unit == 0x7E) return true;
  return unit == 0x2E &&
      index + 1 < source.length &&
      _isLatin(source.codeUnitAt(index + 1));
}
