import 'package:gujarati_transliterator/gujarati_transliterator.dart';
import 'package:test/test.dart';

void main() {
  test('a committed word stays put when a later word is typed', () async {
    final engine = GujaratiTransliterator();
    final session = engine.startSession();
    expect(session.update('zzzz ').text, isNotEmpty);
    final frozen = session.update('zzzz ').text;
    await engine.addCustomMapping('zzzz', 'નરવીર');
    expect(session.update('zzzz yyyy').text.startsWith(frozen.trim()), isTrue);
    expect(session.update('zzzz yyyy').text.contains('નરવીર'), isFalse);
  });

  test('a live word picks up a new correction', () async {
    final engine = GujaratiTransliterator();
    final session = engine.startSession();
    final before = session.update('zzzz').text;
    await engine.addCustomMapping('zzzz', 'નરવીર');
    expect(session.update('zzzz').text, 'નરવીર');
    expect(before, isNot('નરવીર'));
  });

  test('backspacing into a word makes it live again', () async {
    final engine = GujaratiTransliterator();
    final session = engine.startSession();
    session.update('kal ');
    await engine.addCustomMapping('kal', 'કલ્પ');
    expect(session.update('kal x').text.startsWith('કાલ'), isTrue);
    expect(session.update('kal').text, 'કલ્પ');
  });

  test('editing one word does not retouch the others', () {
    final session = GujaratiTransliterator().startSession();
    session.update('Kem cho tame ');
    final edited = session.update('Kal cho tame ');
    expect(edited.text, 'કાલ છો તમે ');
  });

  test('typing a greeting keeps the completed word', () {
    final session = GujaratiTransliterator().startSession();
    expect(session.update('Kem ').text, 'કેમ ');
    expect(session.update('Kem cho').text, 'કેમ છો');
    expect(session.last!.spans.first.committed, isTrue);
    expect(session.last!.spans.last.committed, isFalse);
  });

  test('changing mode clears frozen words', () async {
    final engine = GujaratiTransliterator();
    final session = engine.startSession();
    session.update('pani ');
    session.mode = TransliterationMode.phonetic;
    expect(session.update('pani ').text, 'પનિ ');
  });

  test('character by character typing commits on a space', () {
    final session = GujaratiTransliterator().startSession();
    expect(session.update('k').text, 'ક');
    expect(session.last!.spans.single.committed, isFalse);
    expect(session.update('ke').text, 'કે');
    expect(session.update('kem').text, 'કેમ');
    expect(session.update('kem ').text, 'કેમ ');
    expect(session.last!.spans.first.committed, isTrue);
    expect(session.update('kem c').text, 'કેમ ક');
    expect(session.update('kem cho').text, 'કેમ છો');
  });

  test('backspace reopens only the word being edited', () {
    final session = GujaratiTransliterator().startSession();
    session.update('kem cho ');
    expect(session.update('kem ch').text, 'કેમ ચ');
    expect(session.update('kem').text, 'કેમ');
    expect(session.last!.spans.single.committed, isFalse);
  });

  test('replacing a middle word leaves the others frozen', () {
    final session = GujaratiTransliterator().startSession();
    final original = session.update('zzzz yyyy qqqq ').text.trim().split(' ');
    final edited = session.update('zzzz nnnn qqqq ').text.trim().split(' ');
    expect(edited, hasLength(3));
    expect(edited.first, original.first);
    expect(edited.last, original.last);
    expect(edited[1], isNot(original[1]));
  });

  test('punctuation, extra spaces, and an unfinished word', () {
    final session = GujaratiTransliterator().startSession();
    final punctuated = session.update('kem,');
    expect(punctuated.text, 'કેમ,');
    expect(punctuated.spans.first.committed, isTrue);

    final spaced = GujaratiTransliterator().startSession().update('kem  cho');
    expect(spaced.text, 'કેમ  છો');
    expect(spaced.spans.first.committed, isTrue);
    expect(spaced.spans.last.committed, isFalse);

    final partial = GujaratiTransliterator().startSession().update('ke');
    expect(partial.text, 'કે');
    expect(partial.spans.single.committed, isFalse);
  });

  test('reset forgets a committed word', () async {
    final engine = GujaratiTransliterator();
    final session = engine.startSession();
    final frozen = session.update('zzzz ').text;
    session.reset();
    expect(session.last, isNull);
    await engine.addCustomMapping('zzzz', 'નરવીર');
    expect(session.update('zzzz ').text, 'નરવીર ');
    expect(frozen, isNot('નરવીર '));
  });
}
