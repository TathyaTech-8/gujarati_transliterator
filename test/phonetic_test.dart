import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  String phonetic(String input) {
    return engine.transliterate(input, mode: TransliterationMode.phonetic).text;
  }

  test('independent vowels', () {
    expect(phonetic('a'), 'અ');
    expect(phonetic('aa'), 'આ');
    expect(phonetic('i'), 'ઇ');
    expect(phonetic('ee'), 'ઈ');
    expect(phonetic('ii'), 'ઈ');
    expect(phonetic('u'), 'ઉ');
    expect(phonetic('oo'), 'ઊ');
    expect(phonetic('uu'), 'ઊ');
    expect(phonetic('e'), 'એ');
    expect(phonetic('ai'), 'ઐ');
    expect(phonetic('o'), 'ઓ');
    expect(phonetic('au'), 'ઔ');
    expect(phonetic('ou'), 'ઔ');
    expect(phonetic('.e'), 'ઍ');
    expect(phonetic('.o'), 'ઑ');
    expect(phonetic('.r'), 'ઋ');
    expect(phonetic('.rr'), 'ૠ');
    expect(phonetic('.ll'), 'ઌ');
    expect(phonetic('.lll'), 'ૡ');
  });

  test('matras attach to the consonant', () {
    expect(phonetic('ka'), 'ક');
    expect(phonetic('kaa'), 'કા');
    expect(phonetic('ki'), 'કિ');
    expect(phonetic('kee'), 'કી');
    expect(phonetic('kii'), 'કી');
    expect(phonetic('ku'), 'કુ');
    expect(phonetic('koo'), 'કૂ');
    expect(phonetic('kuu'), 'કૂ');
    expect(phonetic('ke'), 'કે');
    expect(phonetic('kai'), 'કૈ');
    expect(phonetic('ko'), 'કો');
    expect(phonetic('kau'), 'કૌ');
    expect(phonetic('kou'), 'કૌ');
    expect(phonetic('k.e'), 'કૅ');
    expect(phonetic('k.o'), 'કૉ');
    expect(phonetic('k.r'), 'કૃ');
    expect(phonetic('k.rr'), 'કૄ');
    expect(phonetic('k.ll'), 'કૢ');
    expect(phonetic('k.lll'), 'કૣ');
  });

  test('consonant inventory', () {
    final expected = <String, String>{
      'k': 'ક',
      'kh': 'ખ',
      'g': 'ગ',
      'gh': 'ઘ',
      '.ng': 'ઙ',
      'ch': 'ચ',
      'chh': 'છ',
      'j': 'જ',
      'jh': 'ઝ',
      '.ny': 'ઞ',
      '.t': 'ટ',
      '.th': 'ઠ',
      '.d': 'ડ',
      '.dh': 'ઢ',
      '.n': 'ણ',
      't': 'ત',
      'th': 'થ',
      'd': 'દ',
      'dh': 'ધ',
      'n': 'ન',
      'p': 'પ',
      'ph': 'ફ',
      'f': 'ફ',
      'b': 'બ',
      'bh': 'ભ',
      'm': 'મ',
      'y': 'ય',
      'r': 'ર',
      'l': 'લ',
      '.l': 'ળ',
      'v': 'વ',
      'w': 'વ',
      'sh': 'શ',
      '.sh': 'ષ',
      's': 'સ',
      'h': 'હ',
      'q': 'ક઼',
      '.g': 'ગ઼',
      '.f': 'ફ઼',
      '.kh': 'ખ઼',
      'z': 'જ઼',
    };
    for (final entry in expected.entries) {
      expect(phonetic(entry.key), entry.value, reason: entry.key);
    }
  });

  test('conjuncts are virama sequences', () {
    expect(phonetic('kk').runes.toList(), [0x0A95, 0x0ACD, 0x0A95]);
    expect(phonetic('kra').runes.toList(), [0x0A95, 0x0ACD, 0x0AB0]);
    expect(phonetic('tra').runes.toList(), [0x0AA4, 0x0ACD, 0x0AB0]);
    expect(phonetic('dra').runes.toList(), [0x0AA6, 0x0ACD, 0x0AB0]);
    expect(phonetic('dri').runes.toList(), [0x0AA6, 0x0ACD, 0x0AB0, 0x0ABF]);
    expect(phonetic('gna').runes.toList(), [0x0A9C, 0x0ACD, 0x0A9E]);
    expect(phonetic('shra').runes.toList(), [0x0AB6, 0x0ACD, 0x0AB0]);
    expect(phonetic('jna').runes.toList(), [0x0A9C, 0x0ACD, 0x0A9E]);
    expect(phonetic('ksha').runes.toList(), [0x0A95, 0x0ACD, 0x0AB7]);
    expect(phonetic('xa').runes.toList(), [0x0A95, 0x0ACD, 0x0AB7]);
    expect(phonetic('nta').runes.toList(), [0x0AA8, 0x0ACD, 0x0AA4]);
    expect(phonetic('ddha').runes.toList(), [0x0AA6, 0x0ACD, 0x0AA7]);
    expect(
      phonetic('stra').runes.toList(),
      [0x0AB8, 0x0ACD, 0x0AA4, 0x0ACD, 0x0AB0],
    );
    expect(
      phonetic('sandra').runes.toList(),
      [0x0AB8, 0x0AA8, 0x0ACD, 0x0AA6, 0x0ACD, 0x0AB0],
    );
  });

  test('diacritics and nukta use the standard marks', () {
    expect(phonetic('ka.m').runes.toList(), [0x0A95, 0x0A82]);
    expect(phonetic('ka~').runes.toList(), [0x0A95, 0x0A81]);
    expect(phonetic('ka.h').runes.toList(), [0x0A95, 0x0A83]);
    expect(phonetic("k'").runes.toList(), [0x0A95, 0x0ACD]);
    expect(phonetic('q').runes.toList(), [0x0A95, 0x0ABC]);
    expect(phonetic('z').runes.toList(), [0x0A9C, 0x0ABC]);
  });

  test('an internal capital marks a retroflex consonant', () {
    expect(phonetic('paTel'), 'પટેલ');
    expect(phonetic('pa.tel'), 'પટેલ');
  });

  test('a sentence-initial capital is not a retroflex marker', () {
    expect(phonetic('Tel'), 'તેલ');
  });
}
