# gujarati_transliterator

Offline English-to-Gujarati transliteration for Dart.

Type the way a word sounds. The package writes standard Gujarati Unicode. It does not translate meaning: `Kem cho?` stays a greeting and becomes `કેમ છો?`.

The core is pure Dart. It does not depend on Flutter, a font, or a network connection. Gujarati shaping is done by the application that draws the text.

## Install

```yaml
dependencies:
  gujarati_transliterator: ^1.5.0
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

Abbreviations are the same mechanism. `sbi` is already એસબીઆઇ. Add another with `addCustomMapping('lic', 'એલઆઇસી')`, or load `assets/dictionaries/acronyms.json` through `DictionaryLoader.addJson`. A saved mapping stays in the vocabulary store and outranks the built-in list when `prefer` is true.

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

A word that already has a space after it stays as it was. `bolu ` then `bolu chu` remains બોલુ છું. The same words in one update, before any word has frozen, are બોલું છું. The live word still sees the previous committed word, so `bahu ` then `bahu saru` is બહુ સારું.

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

## Informal typing

Intelligent mode can rank a standard spelling ahead of the typed reading when the evidence is narrow:

- The typed key is missing, and one vowel-length change or one inserted `a` finds a frequent lexicon entry whose spelling is one character away. `ghaar` is ઘર, `tme` is તમે, and `suurat` is સુરત.
- A closed grammatical pattern matches: `mare` is મારે, `aapnu` is આપણું, and a word ending in short ઉ immediately before `chu` is read with anusvara, so `bolu chu` is બોલું છું. A stored name stem such as `raj` blocks that nasal, so `raju chu` stays રજુ છું.

શ/સ, ચ/છ, aspiration, and retroflex swaps stay lower suggestions. They do not replace the typed pronunciation. Phonetic mode keeps the typed reading: `mare` is મરે there. The typed spelling also stays in the intelligent suggestion list.

These lookups are a few edited keys, not a scan of the lexicon. `hu gujarati bolu chu`, `aaje bahu saru che`, `mare ghar javu che`, `tame kem cho`, and `aapnu gujarat` resolve to હું ગુજરાતી બોલું છું, આજે બહુ સારું છે, મારે ઘર જવું છે, તમે કેમ છો, and આપણું ગુજરાત.

## Sentences, grammar, and loans

Intelligent mode looks at the following word when a verb ending depends on it, and it applies a closed set of Gujarati endings to known stems. `karjo` is કરજો, `javanu` is જવાનું, `karishu` is કરીશું, and `mokli` is મોકલી. The stem table is a hash set. It is not a scan of the lexicon, and an unknown name is not rewritten merely because it ends in the same letter.

A curated loan list stores the Gujarati spelling of English words that conversations actually use. `meeting` is મીટિંગ, `payment` is પેમેન્ટ, and `document` is ડોક્યુમેન્ટ. Those are transliterations, not translations: `school` stays સ્કૂલ. Phonetic mode still returns the typed reading, so `meeting` is મીતિન્ગ there and `karjo` is કર્જો.

A sentence made only of English function words, plain English words, and known loans stays in Latin. `Please send the document tomorrow` is unchanged. `hu office ma chu` is હું ઓફિસ માં છું, because `hu` and `chu` are Gujarati. Spaces stay between words, so માં is its own word when it was typed as `ma`.

`hu office ma chu`, `mare meeting ma javanu che`, `tame mane call karjo`, `aaje payment karvanu che`, `aapde kale vaat karishu`, `hu ghar thi kaam karu chu`, `tamaro message mali gayo`, and `aa document mokli aapjo` resolve to હું ઓફિસ માં છું, મારે મીટિંગ માં જવાનું છે, તમે મને કોલ કરજો, આજે પેમેન્ટ કરવાનું છે, આપણે કાલે વાત કરીશું, હું ઘર થી કામ કરું છું, તમારો મેસેજ મળી ગયો, and આ ડોક્યુમેન્ટ મોકલી આપજો.

## Dictionary

The built-in lexicon is an original editorial word list: everyday and formal Gujarati, verbs, family words, religious vocabulary, personal names, surnames, Gujarat towns and districts, and administrative words. It is not copied from a published dictionary, and the package license covers the compilation. Frequencies are editorial ranks from 1 to 100, not counts from an outside corpus. The list is not a complete dictionary of the language. Unknown words fall back to the phonetic parse.

The current list has 1,412 entries: 699 everyday words, 106 cultural entries, 175 names, 136 places, 272 loans, and 24 phrases. Six keys keep a second, lower-ranked spelling, such as `ma` → માં and મા. Version 1.2.0 had 1,153 entries. The 1.4.0 growth is the curated loan list, not filler toward 5,000. The list is still well short of a 5,000-word lexicon.

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
dart run benchmark/candidates.dart
dart run benchmark/sentences.dart
```

On this development desktop, version 1.2.0 measured a test median of 0.030 ms and a 95th percentile of 0.528 ms, and a benchmark median of 0.032 ms and a 95th percentile of 0.519 ms. Version 1.3.0 measured a test median of 0.025 ms and a 95th percentile of 0.298 ms (2,400 samples), and a benchmark median of 0.023 ms and a 95th percentile of 0.191 ms (3,000 samples). Candidate generation alone, timed separately, had a median of 0.062 ms and a 95th percentile of 0.152 ms over 2,000 ordinary and informal words, and 0.036 ms / 0.115 ms on the conjunct-heavy subset. The five example sentences measured a median of 0.138 ms and a 95th percentile of 0.366 ms. Version 1.4.0 measured a test median of 0.037 ms and a 95th percentile of 0.433 ms (2,400 samples), a word benchmark median of 0.024 ms and a 95th percentile of 0.200 ms (3,000 samples), and a sentence benchmark median of 0.135 ms and a 95th percentile of 0.255 ms (1,800 samples). Those figures are one desktop, not a phone, and not a guarantee. Measure phones separately. A typing session reuses completed words instead of letting them change under the cursor.

## Tests

```bash
dart test
```

The suite covers vowels, consonants, matras, conjunct code points, the three modes, suggestions, context, custom vocabulary, file reload, incremental typing and backspace, a round-trip of the built-in lexicon, unknown-word candidates, the lexicon round-trip corpus, a held-out scheme set, a natural-roman set, and a sentence set.

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

`test/corpus/natural_roman.tsv` is a separate file of 1,500 roman lines: 121 scheme-faithful, 497 informal, 86 short ambiguous, 101 proper nouns, and 695 phrases. Expected spellings were written as standard orthography for this file. They were not exported from the lexicon or the phonetic tables. No separate native-speaker panel reviewed them. `dart test test/natural_test.dart` prints `NATURAL`.

| Split | Items | Top-1 | Top-3 | Character error rate |
| --- | ---: | ---: | ---: | ---: |
| Exact | 121 | 0.760 | 0.909 | 0.074 |
| Informal | 497 | 0.658 | 0.722 | 0.158 |
| Ambiguous short | 86 | 0.628 | 0.721 | 0.213 |
| Proper nouns | 101 | 0.782 | 0.851 | 0.082 |
| Phrases | 695 | 0.396 | 0.417 | 0.174 |
| Everyday phrases | 298 | 0.453 | 0.477 | 0.132 |
| Mixed office phrases | 178 | 0.483 | 0.483 | 0.168 |
| Stored key or phrase | 993 | 0.698 | 0.712 | 0.102 |
| No stored key | 507 | 0.264 | 0.394 | 0.340 |
| Combined | 1,500 | 0.551 | 0.605 | 0.164 |

The combined figure is not overall Gujarati accuracy. The 1.2 held-out explicit score of 1.000 is still only the scheme round-trip. The 507 lines with no stored key remain the harder natural-roman set: top-1 0.264 and top-3 0.394. Mixed office top-1 rose from 0.011 in 1.3.0 to 0.483 because many of those lines are now covered by the loan list or a verb ending. Rows whose expected text translates the English word, or spells an acronym, still miss. Proper-noun top-1 of 0.782 includes names and cities that are stored under the typed key.

`test/corpus/sentences.tsv` is a separate file of 1,030 editor-written sentences. The Gujarati was not exported from the lexicon and was not produced by the engine. 253 rows are marked `review` for a native-speaker pass that has not been done. `dart test test/sentence_corpus_test.dart` prints `SENTENCE` and `WORD`.

| Split | Items | Exact | Top-3 | Character error rate |
| --- | ---: | ---: | ---: | ---: |
| Everyday | 197 | 0.736 | 0.736 | 0.036 |
| Family | 92 | 0.446 | 0.446 | 0.062 |
| Office | 193 | 0.990 | 0.990 | 0.001 |
| Business | 73 | 0.575 | 0.575 | 0.032 |
| Formal | 15 | 0.400 | 0.467 | 0.079 |
| Informal | 61 | 0.623 | 0.623 | 0.034 |
| Questions | 147 | 0.633 | 0.633 | 0.049 |
| Commands | 157 | 0.854 | 0.854 | 0.026 |
| Mixed | 63 | 0.952 | 0.952 | 0.021 |
| Proper nouns | 32 | 0.719 | 0.719 | 0.028 |
| Editor-sure only | 777 | 0.906 | 0.906 | 0.009 |
| All sentences | 1,030 | 0.750 | 0.751 | 0.030 |

On the 3,587 aligned words, 844 have no lexicon entry. Those unseen words score top-1 0.700 and top-3 0.714. Stored words score top-1 0.993. Sentence top-3 is almost the same as exact match because a wrong word is not repaired by listing unrelated full-sentence alternatives. The everyday exact rate of 0.736 and the sentence character error rate of 0.030 meet the 1.4.0 goals on this file. They are not a claim about all Gujarati. Family exact is 0.446, largely where the file writes બહેન and the lexicon's stored spelling is બેન, and where a `review` row uses an unmodeled form. Formal exact is 0.400.

`ben` is બેન and also offers બહેન. `bahen` is બહેન. After ભાઈ, `ben` is બહેન. A name ending in `bhai` uses ભાઈ, so `Rajubhai` is રજુભાઈ and `Virsangbhai` is વીરસંગભાઈ. `Ghanshyam` is ઘનશ્યામ. `Dilipsinh` is દિલીપસિંહ, and `Harubha` is હરુભા. `bhabhi` is ભાભી. `kaka`, `kaki`, `masi`, and `mama` are કાકા, કાકી, માસી, and મામા. `ahval`, `palvanu`, `vyavastha`, `javabdari`, `karyakram`, and `mahiti` are અહેવાલ, પાળવાનું, વ્યવસ્થા, જવાબદારી, કાર્યક્રમ, and માહિતી. `suchna` and `arji` were already સૂચના and અરજી. A stored name or place is not rewritten by a verb ending. `Male` does not become મળે. `Patel`, `Trilok`, and `Rajkot` stay on their name or place spelling.

## Stable API

These signatures are the stable surface at 1.5.0:

- `GujaratiTransliterator.transliterate` and `suggest`
- `addCustomMapping`, `addCorrection`, `learnSelection`, `removeCustomMapping`
- `exportVocabulary`, `importVocabulary`, `load`, and `open`
- `startSession`, `IncrementalSession.update`, and `reset`
- `MemoryVocabularyStore`, `DelegatingVocabularyStore`, and `FileVocabularyStore`
- `DictionaryLoader.addJson` and `WordDictionary.add`
- `TransliterationMode.phonetic`, `standard`, and `intelligent`

The package version is 1.5.0 because this project has already used the 1.x numbers. The signatures above are not being reset to a new 1.0.0. `FileVocabularyStore` is imported from `package:gujarati_transliterator/file.dart` so the core library does not import `dart:io`. Inputs that are missing a roman or Gujarati string throw `ArgumentError` or `FormatException`. The SDK constraint is `>=3.0.0 <4.0.0`.

## Speaker review

`test/corpus/validation_review.tsv` has 2,371 editor-written rows. Every `native_status` is `unreviewed`. That file is the original packet. The review tools do not write to it, and they do not mark a row reviewed.

`review/categories/` has one worksheet each for everyday vocabulary, informal roman, family, office, formal Gujarati, proper nouns, religious vocabulary, English loans, and complete sentences. `review/batches/` splits those worksheets into groups of 80. A reviewer sets `native_status` to `accepted`, `incorrect`, `ambiguous`, or `dialect`, writes `reviewer_spelling`, and may add further approved spellings in `accepted_alternatives`, separated by `|`. `dialect` names the variety. `reviewer_id` is a short code such as `r1`, not a name, email, or phone number.

```shell
dart run tool/review_check.dart
dart run tool/review_import.dart review/batches/family-01.tsv
dart run tool/review_export.dart
dart run tool/review_stats.dart
```

`review_stats` counts a spelling only after import, and only when the row has both a decision and `reviewer_spelling`. Strict top-1 compares the transliteration with that primary spelling. Accepted-variant top-1 also allows `accepted_alternatives`. Top-3, character error rate, and sentence exact match use the same approved rows. With no imported decisions those figures are `not_measured`. Editor-sure sentence accuracy remains the `SENTENCE_SURE` line from `test/sentence_corpus_test.dart`. The held-out file remains the independent split.

## Limits

English spelling does not identify one Gujarati pronunciation. Some words have more than one accepted spelling. Names that are not in the lexicon stay phonetic; they are not replaced by a nearby dictionary word, and a custom entry is how to teach one. A dictionary cannot by itself choose the right word in every sentence. User corrections stay in that user's store; they do not rewrite the shared lexicon. The lexicon round-trip is not held-out accuracy. The held-out combined score is not overall Gujarati accuracy either, because the explicit encodings dominate it. Unknown short roman input is still often wrong at the first suggestion. The review packet has not been marked by a fluent speaker, so this package is not claiming production-ready linguistic accuracy.
