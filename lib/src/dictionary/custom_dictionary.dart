import '../models/custom_entry.dart';
import '../utils/input_normalizer.dart';

/// User mappings kept apart from the built-in lexicon.
class CustomDictionary {
  final Map<String, List<CustomEntry>> _entries = {};

  /// All saved entries, ordered by roman key then output.
  List<CustomEntry> get entries {
    final all = <CustomEntry>[for (final list in _entries.values) ...list];
    all.sort((a, b) {
      final byInput = a.input.compareTo(b.input);
      if (byInput != 0) return byInput;
      return a.output.compareTo(b.output);
    });
    return List.unmodifiable(all);
  }

  /// Replaces the saved set. Used when a store is loaded.
  void replaceAll(Iterable<CustomEntry> entries) {
    _entries.clear();
    for (final entry in entries) {
      upsert(entry);
    }
  }

  /// Inserts [incoming] or updates the matching output.
  void upsert(CustomEntry incoming, {bool incrementHits = false}) {
    final key = normalizeMappingKey(incoming.input);
    if (key.isEmpty) {
      throw ArgumentError.value(
        incoming.input,
        'input',
        'must contain at least one word',
      );
    }
    final list = _entries.putIfAbsent(key, () => <CustomEntry>[]);
    final index = list.indexWhere((entry) => entry.output == incoming.output);
    if (index < 0) {
      list.add(
        CustomEntry(
          input: key,
          output: incoming.output,
          prefer: incoming.prefer,
          origin: incoming.origin,
          hits: incoming.hits < 1 ? 1 : incoming.hits,
          updatedAt: incoming.updatedAt,
        ),
      );
      return;
    }
    final current = list[index];
    final hits = incrementHits
        ? current.hits + 1
        : (incoming.hits > current.hits ? incoming.hits : current.hits);
    list[index] = CustomEntry(
      input: key,
      output: current.output,
      prefer: incoming.prefer,
      origin: incoming.origin,
      hits: hits,
      updatedAt: incrementHits
          ? DateTime.now().toUtc()
          : (incoming.updatedAt ?? current.updatedAt),
    );
  }

  /// Removes every spelling saved for [input].
  void remove(String input) {
    _entries.remove(normalizeMappingKey(input));
  }

  /// Saved spellings for [input], which may be a word or a phrase.
  List<CustomEntry> lookup(String input) {
    final list = _entries[normalizeMappingKey(input)];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }
}
