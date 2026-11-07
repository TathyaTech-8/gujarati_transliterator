/// How the engine chooses a Gujarati spelling.
enum TransliterationMode {
  /// Follow the pronunciation encoded by the typed letters.
  phonetic,

  /// Prefer established Gujarati spellings, then orthographic conventions.
  standard,

  /// Combine pronunciation, dictionary frequency, and nearby words.
  ///
  /// This is the default.
  intelligent,
}
