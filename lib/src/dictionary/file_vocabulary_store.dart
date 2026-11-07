import 'dart:io';

import '../models/custom_entry.dart';
import 'vocabulary_store.dart';

/// JSON file store for custom vocabulary.
///
/// This uses `dart:io`, so it is available on the Dart VM and on Flutter
/// mobile and desktop. Web applications should use [DelegatingVocabularyStore].
class FileVocabularyStore implements VocabularyStore {
  /// Creates a store that reads and writes [path].
  FileVocabularyStore(String path) : _file = File(path);

  final File _file;

  /// File that holds the vocabulary JSON.
  File get file => _file;

  @override
  Future<List<CustomEntry>> load() async {
    if (!await _file.exists()) return const [];
    return VocabularyCodec.decode(await _file.readAsString());
  }

  @override
  Future<void> save(List<CustomEntry> entries) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(VocabularyCodec.encode(entries));
  }
}
