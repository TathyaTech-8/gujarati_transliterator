import 'dart:convert';

import 'word_dictionary.dart';

/// Loads extra vocabulary from a JSON list.
///
/// Each object has `roman`, `gujarati`, and optional `frequency` and `kind`.
abstract final class DictionaryLoader {
  /// Adds every entry in [jsonText] to [dictionary].
  static void addJson(WordDictionary dictionary, String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List<Object?>) {
      throw const FormatException('Vocabulary JSON must be a list.');
    }
    for (final item in decoded) {
      if (item is! Map<Object?, Object?>) {
        throw const FormatException('Vocabulary entry must be an object.');
      }
      final roman = item['roman'];
      final gujarati = item['gujarati'];
      if (roman is! String || gujarati is! String) {
        throw const FormatException(
          'Vocabulary entry needs roman and gujarati strings.',
        );
      }
      final frequency = item['frequency'];
      final kindName = item['kind'];
      dictionary.add(
        roman,
        gujarati,
        frequency: frequency is int ? frequency : 50,
        kind: _kind(kindName),
      );
    }
  }

  static EntryKind _kind(Object? name) {
    if (name is! String || name.isEmpty) return EntryKind.common;
    for (final kind in EntryKind.values) {
      if (kind.name == name) return kind;
    }
    throw FormatException('Unknown vocabulary kind "$name".');
  }
}
