part of 'transliteration_engine.dart';

/// Typing state for one text field.
///
/// Completed words keep the spelling they had when the user finished them.
/// The last word, while it has no space or punctuation after it, is live and
/// is transliterated again on every update.
class IncrementalSession {
  IncrementalSession._(this._engine, this._mode);

  final GujaratiTransliterator _engine;
  TransliterationMode _mode;
  final _CommitMemory _memory = _CommitMemory();
  TransliterationResult? _last;

  /// Mode used for the next [update]. Changing it clears frozen words.
  TransliterationMode get mode => _mode;

  set mode(TransliterationMode value) {
    if (_mode == value) return;
    _mode = value;
    _memory.clear();
  }

  /// Result of the most recent [update].
  TransliterationResult? get last => _last;

  /// Transliterates the field contents in [input].
  TransliterationResult update(String input) {
    _last = _engine._render(input, mode: _mode, memory: _memory);
    return _last!;
  }

  /// Forgets frozen words. The next update transliterates [input] afresh.
  void reset() {
    _memory.clear();
    _last = null;
  }
}
