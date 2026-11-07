# Gujarati review worksheets

`test/corpus/validation_review.tsv` is the editor-written packet. Leave it as it is. Nothing in this folder is a native-speaker decision until a person fills it in.

## Status values

| native_status | Meaning |
| --- | --- |
| `unreviewed` | No person has decided. This is the starting value. |
| `accepted` | `reviewer_spelling` is an approved spelling. |
| `incorrect` | The editor spelling is rejected. Put the correction in `reviewer_spelling` when you know one. |
| `ambiguous` | More than one spelling is reasonable. Put the one you would teach first in `reviewer_spelling`. |
| `dialect` | The spelling depends on variety. Name the variety in `dialect`. |

`accepted_alternatives` holds extra approved spellings, separated by `|`. The editor spelling is not treated as approved unless you copy it into `reviewer_spelling` or `accepted_alternatives`.

`reviewer_id` is a short code you choose, such as `r1`. Do not write a name, email address, or phone number. `reviewer_note` is for the spelling only. `dialect` is a variety label such as `standard`, `kathiyawadi`, or `charotari`.

## Files

- `categories/` has one worksheet for each area: everyday vocabulary (`common`), informal roman, family, office, formal, proper nouns, religious vocabulary, English loanwords, and complete sentences.
- `batches/` splits each area into groups of 80 rows. Use these for one sitting.
- `validated/` receives import and export output. It starts without approved rows.

`roman` and `editor_gujarati` are copies. Do not delete them.

## Commands

From the repository root:

```shell
dart run tool/review_prepare.dart
dart run tool/review_check.dart review/batches/family-01.tsv
dart run tool/review_import.dart review/batches/family-01.tsv
dart run tool/review_export.dart
dart run tool/review_stats.dart
```

`review_prepare` will not overwrite a worksheet that already has a decision, a spelling, a reviewer id, a dialect, or a note. `review_import` skips `unreviewed` rows and does not write the editor packet. `review_stats` reports accuracy only for imported rows that have both a decision and a reviewer spelling. While that count is zero, accuracy is `not_measured`.

Import either the batch you finished or the category worksheet, and do not keep editing both copies of the same id. A later import of the same id replaces the earlier one.
