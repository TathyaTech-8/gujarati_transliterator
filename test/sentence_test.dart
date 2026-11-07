import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  late GujaratiTransliterator engine;

  setUp(() {
    engine = GujaratiTransliterator();
  });

  test('ordinary sentences use grammar and loan spellings', () {
    final expected = <String, String>{
      'hu office ma chu': 'હું ઓફિસ માં છું',
      'mare meeting ma javanu che': 'મારે મીટિંગ માં જવાનું છે',
      'tame mane call karjo': 'તમે મને કોલ કરજો',
      'aaje payment karvanu che': 'આજે પેમેન્ટ કરવાનું છે',
      'aapde kale vaat karishu': 'આપણે કાલે વાત કરીશું',
      'hu ghar thi kaam karu chu': 'હું ઘર થી કામ કરું છું',
      'tamaro message mali gayo': 'તમારો મેસેજ મળી ગયો',
      'aa document mokli aapjo': 'આ ડોક્યુમેન્ટ મોકલી આપજો',
    };
    for (final entry in expected.entries) {
      expect(engine.transliterate(entry.key).text, entry.value,
          reason: entry.key);
      final again = engine.transliterate(entry.key).text;
      expect(again, entry.value, reason: '${entry.key} stable');
    }
  });

  test('phonetic mode keeps the typed reading of a loan and a verb', () {
    expect(
      engine.transliterate('meeting').text,
      'મીટિંગ',
    );
    expect(
      engine.transliterate('meeting', mode: TransliterationMode.phonetic).text,
      isNot('મીટિંગ'),
    );
    expect(
      engine.transliterate('karjo', mode: TransliterationMode.phonetic).text,
      'કર્જો',
    );
    expect(engine.transliterate('karjo').text, 'કરજો');
    expect(engine.transliterate('papa').text, 'પપ્પા');
    expect(engine.transliterate('savare').text, 'સવારે');
    expect(engine.transliterate('kapda').text, 'કપડાં');
    expect(engine.transliterate('coffee').text, 'કોફી');
    expect(engine.transliterate('banave').text, 'બનાવે');
    expect(engine.transliterate('mare').text, 'મારે');
  });

  test('an English sentence stays in Latin', () {
    const english = 'Please send the document tomorrow';
    expect(engine.transliterate(english).text, english);
    expect(
      engine.transliterate(english, mode: TransliterationMode.phonetic).text,
      isNot(english),
    );
  });

  test('a committed word is still not rewritten', () {
    final session = engine.startSession();
    expect(session.update('bolu ').text, 'બોલુ ');
    expect(session.update('bolu chu').text, 'બોલુ છું');
    expect(engine.startSession().update('bolu chu').text, 'બોલું છું');
  });

  test('the live word still uses the previous committed word', () {
    final session = engine.startSession();
    expect(session.update('bahu ').text, 'બહુ ');
    expect(session.update('bahu saru').text, 'બહુ સારું');
  });

  test('family words keep both spellings and the phrase', () {
    expect(engine.transliterate('ben').text, 'બેન');
    expect(
      engine.suggest('ben').map((item) => item.text),
      contains('બહેન'),
    );
    expect(engine.transliterate('bahen').text, 'બહેન');
    expect(engine.transliterate('bhai ben').text, 'ભાઈ બહેન');
    expect(engine.transliterate('bhai').text, 'ભાઈ');
    expect(engine.transliterate('Rajubhai').text, 'રજુભાઈ');
    expect(engine.transliterate('Virsangbhai').text, 'વીરસંગભાઈ');
    expect(engine.transliterate('Ghanshyam').text, 'ઘનશ્યામ');
    expect(engine.transliterate('Dilipsinh').text, 'દિલીપસિંહ');
    expect(engine.transliterate('Harubha').text, 'હરુભા');
    expect(engine.transliterate('narvirsinh').text, 'નરવીરસિંહ');
    expect(engine.transliterate('shyam').text, 'શ્યામ');
    expect(engine.transliterate('bhabhi').text, 'ભાભી');
    expect(engine.transliterate('kaka').text, 'કાકા');
    expect(engine.transliterate('kaki').text, 'કાકી');
    expect(engine.transliterate('masi').text, 'માસી');
    expect(engine.transliterate('mama').text, 'મામા');
  });

  test('formal words and acronyms use the standard spelling', () {
    expect(engine.transliterate('ahval').text, 'અહેવાલ');
    expect(engine.transliterate('palvanu').text, 'પાળવાનું');
    expect(engine.transliterate('vyavastha').text, 'વ્યવસ્થા');
    expect(engine.transliterate('javabdari').text, 'જવાબદારી');
    expect(engine.transliterate('karyakram').text, 'કાર્યક્રમ');
    expect(engine.transliterate('suchna').text, 'સૂચના');
    expect(engine.transliterate('arji').text, 'અરજી');
    expect(engine.transliterate('mahiti').text, 'માહિતી');
    expect(engine.dictionary.lookupWord('mahiti'), isEmpty);
    expect(engine.transliterate('sbi').text, 'એસબીઆઇ');
    expect(engine.transliterate('SBI').text, 'એસબીઆઇ');
  });

  test('a local acronym mapping outranks the phonetic reading', () async {
    await engine.addCustomMapping('lic', 'એલઆઇસી');
    expect(engine.transliterate('lic').text, 'એલઆઇસી');
  });

  test('a title-case name is not given a verb ending', () {
    expect(engine.transliterate('Male').text, isNot('મળે'));
    expect(engine.transliterate('Banave').text, isNot('બનાવે'));
    expect(engine.transliterate('Trilok').text, 'ત્રિલોક');
    expect(engine.transliterate('Patel').text, 'પટેલ');
    expect(engine.transliterate('Rajkot').text, 'રાજકોટ');
  });
}
