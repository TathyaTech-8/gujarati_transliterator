## 1.5.1

- Spell joined names as whole words. `Rajubhai` is રજુભાઈ, `Virsangbhai` is વીરસંગભાઈ, `Ghanshyam` is ઘનશ્યામ, `Dilipsinh` is દિલીપસિંહ, and `Harubha` is હરુભા. No change to `transliterate`, `suggest`, the stores, or the three modes.

## 1.5.0

- Keep both family spellings: `ben` is બેન and also offers બહેન, `bahen` is બહેન, and `bhai ben` is ભાઈ બહેન. Add ભાભી. કાકા, કાકી, માસી, and મામા stay as stored.
- Read અહેવાલ, પાળવાનું, વ્યવસ્થા, જવાબદારી, કાર્યક્રમ, and માહિતી from the typed roman. સૂચના and અરજી were already stored. માહિતી is not a lexicon key, so the held-out absence check still holds.
- Leave a stored name or place on its lexicon spelling. A title-case word is not given a verb ending unless it is a closed function or kinship word.
- Map `sbi` to એસબીઆઇ. Other abbreviations are local `addCustomMapping` entries, or rows in `assets/dictionaries/acronyms.json` loaded with `DictionaryLoader.addJson`.
- A frozen word stays frozen. An uncommitted `bolu chu` is still બોલું છું, and the live word after `bahu ` still becomes સારું.
- Add 2,371 editor-written rows in `test/corpus/validation_review.tsv` for fluent speakers. Every row is `unreviewed`. Native-speaker accuracy is not measured.
- Add review worksheets in `review/` and `tool/review_*.dart` for batches, duplicate checks, import, export, and accepted-variant scoring. Unreviewed rows are not counted. No row is marked reviewed by the tools.
- Record the public API as stable at 1.5.0. `homepage` and `repository` point at the GitHub remote. No breaking change to `transliterate`, `suggest`, the stores, or the three modes.

## 1.4.0

- Resolve common verb endings and a few closed pronouns from the typed stem, using the existing parser. `karjo` is કરજો, `javanu` is જવાનું, and `bolu chu` stays બોલું છું. A committed word is still frozen.
- Add a curated loan list. `meeting` is મીટિંગ and `payment` is પેમેન્ટ. An English sentence such as `Please send the document tomorrow` stays in Latin. Phonetic mode still returns the typed reading.
- Score 1,030 editor-written sentences separately. Unseen words, 844 of 3,587, score top-1 0.700 and top-3 0.714. Everyday sentences score exact 0.736. Sentence character error rate is 0.030. Family exact is 0.446 and formal exact is 0.400. 253 rows are marked for native-speaker review; no panel has reviewed them.
- No breaking change to `transliterate`, `suggest`, the vocabulary stores, or the three modes. The parser is unchanged.

## 1.3.0

- Rank a standard spelling ahead of the typed reading in intelligent mode only when evidence is narrow: one vowel-length or schwa edit that hits a frequent lexicon entry one character away, or a closed pattern for મારે, આપણું, and ઉં before છું.
- Keep શ/સ, ચ/છ, aspiration, and retroflex changes as lower suggestions. Phonetic mode still returns the typed reading. A word committed in a typing session is not rewritten when the next word arrives.
- Score 1,500 natural roman lines separately from the scheme corpus. Informal top-1 is 0.646. Lines with no stored key score 0.224 top-1 and 0.339 top-3. That split is the accuracy claim.
- No breaking change to `transliterate`, `suggest`, the vocabulary stores, or the default intelligent mode. The parser is unchanged.

## 1.2.0

- Suggest further readings for an unknown word: long and short vowels, vocalic ર, a retroflex consonant, chandrabindu, and a diphthong. The typed reading stays first unless the lexicon or a short anusvara cluster wins.
- Add hand-written vocabulary for verbs, family, food, towns, faith, and administration. The lexicon is 1,153 spellings and 1,147 keys, up from 953 spellings. It was not padded toward 5,000.
- Resolve a few stored phrases from the preceding word, including ખૂબ સારું and બહુ સારું, without changing a word that a typing session has already committed.
- Score a held-out set of 1,039 items whose keys are absent from the lexicon. Explicit scheme encodings score 1.000 top-1. Ambiguous short roman scores 0.000 top-1 and 0.455 top-3. That split is the accuracy claim. The older 1.000 figure remains the lexicon reproducing itself.
- No breaking change to `transliterate`, `suggest`, the vocabulary stores, or the default intelligent mode.

## 1.1.0

- Prefer established spellings for a larger hand-written Gujarati lexicon, including conjunct-heavy words such as શ્રદ્ધાંજલિ, પ્રજ્ઞા, and સંસ્કૃતિ.
- Offer vocalic ર and retroflex ષ as extra candidates for `ri`, `ru`, and `shh` without changing the plain phonetic reading of an unknown word.
- Keep a later user correction ahead of an earlier one when both are saved in the same millisecond.
- Add a checked corpus, accuracy metrics, and a desktop latency benchmark.
- No breaking change to `transliterate`, `suggest`, the vocabulary stores, or the default intelligent mode.

## 1.0.0

- Initial offline English-to-Gujarati transliterator with phonetic, standard, and intelligent modes.
