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
