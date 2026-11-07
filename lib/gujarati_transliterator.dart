/// Offline English-to-Gujarati transliteration.
///
/// ```dart
/// import 'package:gujarati_transliterator/gujarati_transliterator.dart';
///
/// final engine = GujaratiTransliterator();
/// final result = engine.transliterate('Shukravar');
/// print(result.text); // શુક્રવાર
/// ```
library;

export 'src/dictionary/dictionary_loader.dart';
export 'src/dictionary/vocabulary_store.dart';
export 'src/dictionary/word_dictionary.dart';
export 'src/engine/transliteration_engine.dart';
export 'src/models/custom_entry.dart';
export 'src/models/suggestion.dart';
export 'src/models/transliteration_mode.dart';
export 'src/models/transliteration_result.dart';
