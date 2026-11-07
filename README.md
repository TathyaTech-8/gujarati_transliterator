# gujarati_transliterator

Offline English-to-Gujarati transliteration for Dart.

Type the way a word sounds. The package writes standard Gujarati Unicode. It does not translate meaning: `Kem cho?` stays a greeting and becomes `કેમ છો?`.

The core is pure Dart. It does not depend on Flutter, a font, or a network connection. Gujarati shaping is done by the application that draws the text.

## Install

```yaml
dependencies:
  gujarati_transliterator: ^1.2.0
```

```dart
import 'package:gujarati_transliterator/gujarati_transliterator.dart';

final engine = GujaratiTransliterator();
final result = engine.transliterate('Shukravar');

print(result.text); // શુક્રવાર
```

Run the sample from the package root:

```bash
dart run example/main.dart
```

## Modes

Intelligent mode is the default. It scores pronunciation, the built-in lexicon, and the previous word.

```dart
engine.transliterate('Narvirsinh'); // નરવીરસિંહ
engine.transliterate(
  'Pani',
  mode: TransliterationMode.phonetic,
); // પનિ
engine.transliterate('Pani'); // પાણી
```

| Mode | What it prefers |
| --- | --- |
| `intelligent` | The most likely spelling from pronunciation, vocabulary, and context |
| `standard` | A dictionary spelling, then a conventional conjunct or anusvara |
| `phonetic` | The pronunciation of the typed letters |

`Patel` is `પતેલ` in phonetic mode and `પટેલ` in intelligent mode. A sentence-initial capital is just capitalization. An internal capital, or a dot, marks a retroflex letter: `paTel` and `pa.tel` are `પટેલ` even in phonetic mode.

## Suggestions

Ambiguous input returns ranked candidates. The first suggestion is the transliteration.

```dart
for (final suggestion in engine.suggest('Kal')) {
  print('${suggestion.text} ${suggestion.confidence}');
}
```

`Kal` offers `કાલ` first, from the lexicon, then the typed reading `કલ`, then lower-ranked vowel and retroflex edits such as `કલા` and `કળ`. Each suggestion has a confidence from 0 to 1, a source, and a 1-based rank.

For more than one word, `suggest` returns full-string alternatives. While someone is typing, `result.activeSuggestions` is the candidate list for the last word.

## Custom words and corrections

Custom mappings live in a store you provide. They do not change the built-in lexicon for anyone else. A preferred mapping outranks the generic rules, including in phonetic mode.

```dart
await engine.addCustomMapping('Narvirsinh', 'નરવીરસિંહ');
await engine.addCorrection('kal', 'કલ્પ');
await engine.learnSelection('kal', 'કલ્પ');
```

`prefer: false` keeps the mapping as a suggestion without forcing it.

```dart
final engine = await GujaratiTransliterator.open(
  store: MemoryVocabularyStore(),
);
final json = await engine.exportVocabulary();
await engine.importVocabulary(json);
```

| Store | Use it for |
| --- | --- |
| `MemoryVocabularyStore` | Tests and process-local vocabulary. This is the default. |
| `DelegatingVocabularyStore` | Any host that can read and write a JSON string, including web and shared preferences. |
| `FileVocabularyStore` | A JSON file on the Dart VM or Flutter mobile and desktop. |

File storage is a separate import so the core library stays free of `dart:io`:

```dart
import 'package:gujarati_transliterator/file.dart';

final engine = await GujaratiTransliterator.open(
  store: FileVocabularyStore('/path/to/vocabulary.json'),
);
```

Call `open`, or `await engine.load()`, before expecting saved entries to apply. `addCustomMapping` loads the store on first use.

## Incremental typing

`transliterate` is stateless: the same input always resolves the same way. A session freezes a word once a space or punctuation mark follows it, so later typing does not rewrite it.

```dart
final session = engine.startSession();
session.update('Kem ');
session.update('Kem cho'); // કેમ છો
```

The last word is live until a boundary follows it. Backspacing into a finished word makes it live again. Changing `session.mode` clears frozen words.

## Phonetic letters

Unmarked consonants are dental. Vowel length is written by repeating the vowel.

| Roman | Gujarati |
| --- | --- |
| `a aa i ee/ii u oo/uu` | અ આ ઇ ઈ ઉ ઊ |
| `e ai o au/ou` | એ ઐ ઓ ઔ |
| `.e .o .r .rr .ll .lll` | ઍ ઑ ઋ ૠ ઌ ૡ |
| `k kh g gh .ng` | ક ખ ગ ઘ ઙ |
| `ch chh j jh .ny` | ચ છ જ ઝ ઞ |
| `t th d dh n` | ત થ દ ધ ન |
| `.t .th .d .dh .n` | ટ ઠ ડ ઢ ણ |
| `p ph/f b bh m` | પ ફ બ ભ મ |
| `y r l v/w sh s h .l .sh` | ય ર લ વ શ સ હ ળ ષ |
| `ksh` / `x`, `jn` / `gy` / `dny` | ક્ષ, જ્ઞ |
| `q z .g .f .kh` | ક઼ જ઼ ગ઼ ફ઼ ખ઼ |
| `.m` `~` `.h` `'` | ં ઁ ઃ ્ |

A consonant followed by another consonant joins with virama: `mitra` is મિત્ર, `stri` is સ્ત્રી. A final consonant keeps the inherent vowel, so `kem` is કેમ rather than કેમ્. The apostrophe asks for a halant: `k'` is ક્.

Two-consonant nasal clusters such as `ન્ત` also produce an anusvara candidate, `ંત`. Longer clusters such as `ન્દ્ર` stay conjuncts.

Some letter groups have more than one reading. For a word that is not in the lexicon, the typed reading stays first. Other readings are suggestions and do not replace it. Anusvara is the exception: a short nasal cluster such as `sanpa` is written `સંપ` in intelligent mode, with `સન્પ` and the chandrabindu form `સઁપ` kept as suggestions.

| Typed | First reading | Also suggested |
| --- | --- | --- |
| `tri`, `kru` | ત્રિ, ક્રુ | તૃ, કૃ |
| `ri` at the start of a word | રિ | ઋ |
| `shh` | શ્હ | ષ |
| `prakriya` | પ્રક્રિય | પ્રક્રિયા |
| `shikshan`, `math` | શિક્ષન, મથ | શિક્ષણ, મઠ |

The extra readings cover one ambiguous choice at a time: a long vowel, vocalic ર, a retroflex consonant, chandrabindu, or a diphthong. They are not applied on top of each other, and they are ranked under the typed reading. A personal name is not replaced by a nearby dictionary word.

A known word still wins. `trivedi` is ત્રિવેદી, while `krishna` is કૃષ્ણ. `Trilok` is not in the lexicon, so it stays ત્રિલોક. Where two roman spellings are both in use, they can share the standard spelling: `khedut` and `khedoot` are both ખેડૂત. A dialect pronunciation is not treated as a misspelling of a different word. The default remains the standard spelling.

A preceding word can select a phrase that is already stored. `khub saru` is ખૂબ સારું and `bahu saru` is બહુ સારું. Punctuation, spaces, and Gujarati characters already in the input stay as typed. In a typing session, a word that has been committed does not change when the next word is edited.

## Dictionary

The built-in lexicon is an original editorial word list: everyday and formal Gujarati, verbs, family words, religious vocabulary, personal names, surnames, Gujarat towns and districts, and administrative words. It is not copied from a published dictionary, and the package license covers the compilation. Frequencies are editorial ranks from 1 to 100, not counts from an outside corpus. The list is not a complete dictionary of the language. Unknown words fall back to the phonetic parse.

The current list has 1,153 spellings and 1,147 roman keys: 697 everyday words, 106 cultural entries, 167 names, 136 places, 24 loans, and 23 phrases. Six keys keep a second, lower-ranked spelling, such as `ma` → માં and મા. The list grew from 953 spellings in 1.1.0. It is still well short of a 5,000-word lexicon. Entries were not invented to close that gap.

Add entries for one engine:

```dart
engine.dictionary.add('morbi', 'મોરબી', frequency: 80, kind: EntryKind.place);
```

Or load a JSON list. See `assets/dictionaries/extra_vocabulary.json`.

```json
[{ "roman": "saputara", "gujarati": "સાપુતારા", "frequency": 70, "kind": "place" }]
```

```dart
DictionaryLoader.addJson(engine.dictionary, jsonText);
```

Frequency is an integer from 1 to 100. The same roman key may have more than one spelling.

## Unicode

Output is a normal Unicode sequence: consonant, optional nukta, virama or matra, then anusvara, chandrabindu, or visarga. The package does not emit legacy font encodings. A font still has to contain the glyphs, and the host has to shape Gujarati. Noto Sans Gujarati and Shruti are suitable fonts. The same string can look different in a font that lacks a conjunct.

## Performance

Targets for ordinary word-level input on a desktop, not a guarantee for every device:

- Median under 10 ms.
- 95th percentile under 30 ms.

Measure this machine with:

```bash
dart test test/performance_test.dart
```

The test prints `PERF median=... p95=...` and fails if a sample exceeds those budgets. A separate script prints `BENCH` for the same style of sample, including a few conjunct-heavy words:

```bash
dart run benchmark/latency.dart
```

On the development desktop, version 1.1.0 measured a median of 0.011 ms and a 95th percentile of 0.282 ms on the 2,400-sample test, and the benchmark script measured a median of 0.010 ms and a 95th percentile of 0.225 ms over 3,000 samples. Version 1.2.0, with the larger lexicon and the extra unknown-word candidates, measured a median of 0.030 ms and a 95th percentile of 0.528 ms on the same test, and a benchmark median of 0.032 ms and a 95th percentile of 0.519 ms. Those figures are one desktop, not a phone, and not a guarantee. Measure phones separately. A typing session reuses completed words instead of letting them change under the cursor.

## Tests

```bash
dart test
```

The suite covers vowels, consonants, matras, conjunct code points, the three modes, suggestions, context, custom vocabulary, file reload, incremental typing and backspace, a round-trip of the built-in lexicon, unknown-word candidates, the lexicon round-trip corpus, and a held-out set whose keys are absent from that lexicon.

## Accuracy corpus

`test/corpus/` holds the checked pairs:

| File | What it is |
| --- | --- |
| `verified_pairs.tsv` | The winning spelling of each hand-written lexicon entry |
| `phrases.tsv` | Hand-checked sentences, punctuation, and mixed script |
| `rule_pairs.tsv` | Consonant-plus-vowel forms. The expected text is the consonant plus the vowel sign from the mapping tables |
| `alternate_spellings.tsv` | The lower-ranked spelling where a roman key has two |
| `heldout_hand.tsv` | Hand-written words and phrases whose roman keys are not in the lexicon |

`dart test test/corpus_test.dart` prints `ACCURACY` and `LEXICON`. On the curated verified set, intelligent mode selects the stored spelling: top-1, top-3, word accuracy, and character error rate are 1.000, 1.000, 1.000, and 0. The same set with an empty lexicon, phonetic mode only, has top-1 accuracy 0.201 and character error rate 0.320. That gap is the part the word list is doing. Those pairs are the lexicon itself. A perfect score there is the list reproducing its own spellings, not a measurement of all Gujarati.

`dart test test/heldout_test.dart` prints `HELDOUT` for 1,039 items that were checked to be absent from the lexicon. Expected spellings were not read out of the engine dictionary. Verb forms were built by joining a stem spelling to an ending spelling. The set was checked by the editor against standard orthography. No separate native-speaker panel reviewed it.

| Split | Items | Top-1 | Top-3 | Character error rate |
| --- | --- | --- | --- | --- |
| Explicit scheme encodings | 1,024 | 1.000 | 1.000 | 0.000 |
| Ambiguous short roman | 11 | 0.000 | 0.455 | 0.361 |
| Phrases | 4 | 1.000 | 1.000 | 0.000 |
| Combined | 1,039 | 0.989 | 0.994 | 0.004 |

The explicit rows use the documented roman scheme, including long vowels and dotted retroflex letters, so a perfect score there means the encoding matches the rules. The ambiguous rows are the unknown-word exam: short input such as `shikshan`, `mahiti`, and `nrutya`, where the usual spelling needs a choice the typed letters do not mark. Top-1 stays the typed reading, and the usual spelling is only sometimes inside the first three suggestions. The combined row is mostly the explicit verb forms, 1,024 of 1,039 items. Do not quote it as overall Gujarati accuracy.

Rule rows are checked in phonetic mode and are labeled `rule` so they stay separate from the hand-written spellings.

## Limits

English spelling does not identify one Gujarati pronunciation. Some words have more than one accepted spelling. Names that are not in the lexicon stay phonetic; they are not replaced by a nearby dictionary word, and a custom entry is how to teach one. A dictionary cannot by itself choose the right word in every sentence. User corrections stay in that user's store; they do not rewrite the shared lexicon. The lexicon round-trip is not held-out accuracy. The held-out combined score is not overall Gujarati accuracy either, because the explicit encodings dominate it. Unknown short roman input is still often wrong at the first suggestion.
