import 'dart:convert';

import '../models/custom_entry.dart';
import '../utils/input_normalizer.dart';

/// Persistence for custom words and corrections.
///
/// The core package does not open files or the network. [MemoryVocabularyStore]
/// keeps entries for the current process. [DelegatingVocabularyStore] lets an
/// application read and write the JSON itself, for example from shared
/// preferences. File storage is available from `package:gujarati_transliterator/file.dart`.
abstract interface class VocabularyStore {
  /// Reads the saved entries. Missing storage returns an empty list.
  Future<List<CustomEntry>> load();

  /// Replaces the saved entries with [entries].
  Future<void> save(List<CustomEntry> entries);
}

/// Store that lives only in memory.
class MemoryVocabularyStore implements VocabularyStore {
  /// Creates a memory store, optionally seeded with [initial] entries.
  MemoryVocabularyStore([List<CustomEntry>? initial])
      : _entries = List<CustomEntry>.of(initial ?? const []);

  List<CustomEntry> _entries;

  /// Current entries without loading asynchronously.
  List<CustomEntry> peek() => List<CustomEntry>.unmodifiable(_entries);

  @override
  Future<List<CustomEntry>> load() async => peek();

  @override
  Future<void> save(List<CustomEntry> entries) async {
    _entries = List<CustomEntry>.of(entries);
  }
}

/// Store backed by application-provided read and write callbacks.
class DelegatingVocabularyStore implements VocabularyStore {
  /// Creates a store that delegates persistence to the host app.
  DelegatingVocabularyStore({required this.read, required this.write});

  /// Returns the saved JSON, or null when nothing has been saved yet.
  final Future<String?> Function() read;

  /// Persists the JSON document.
  final Future<void> Function(String contents) write;

  @override
  Future<List<CustomEntry>> load() async {
    final raw = await read();
    if (raw == null || raw.trim().isEmpty) return const [];
    return VocabularyCodec.decode(raw);
  }

  @override
  Future<void> save(List<CustomEntry> entries) {
    return write(VocabularyCodec.encode(entries));
  }
}

/// JSON codec for custom vocabulary files.
abstract final class VocabularyCodec {
  /// Schema version written by [encode].
  static const int version = 1;

  /// Serializes [entries] as indented JSON.
  static String encode(List<CustomEntry> entries) {
    final payload = <String, Object?>{
      'version': version,
      'entries': [
        for (final entry in entries)
          <String, Object?>{
            'input': entry.input,
            'output': entry.output,
            'prefer': entry.prefer,
            'origin': entry.origin.name,
            'hits': entry.hits,
            if (entry.updatedAt != null)
              'updatedAt': entry.updatedAt!.toUtc().toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses a document produced by [encode].
  static List<CustomEntry> decode(String jsonText) {
    if (jsonText.trim().isEmpty) return const [];
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Vocabulary file must be a JSON object.');
    }
    final version = decoded['version'];
    if (version != VocabularyCodec.version) {
      throw FormatException('Unsupported vocabulary version: $version');
    }
    final rawEntries = decoded['entries'];
    if (rawEntries is! List<dynamic>) {
      throw const FormatException('Vocabulary file is missing entries.');
    }
    return [for (final item in rawEntries) _entry(item)];
  }

  static CustomEntry _entry(Object? item) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Custom entry must be an object.');
    }
    final input = item['input'];
    final output = item['output'];
    if (input is! String || normalizeMappingKey(input).isEmpty) {
      throw const FormatException('Custom entry is missing input.');
    }
    if (output is! String || output.trim().isEmpty) {
      throw const FormatException('Custom entry is missing output.');
    }
    final originName = item['origin'];
    final origin = originName == CustomOrigin.correction.name
        ? CustomOrigin.correction
        : CustomOrigin.custom;
    final rawHits = item['hits'];
    final hits = rawHits is num ? rawHits.toInt() : 1;
    final rawTime = item['updatedAt'];
    return CustomEntry(
      input: input,
      output: output.trim(),
      prefer: item['prefer'] is bool ? item['prefer'] as bool : true,
      origin: origin,
      hits: hits < 1 ? 1 : hits,
      updatedAt: rawTime is String ? DateTime.tryParse(rawTime) : null,
    );
  }
}
