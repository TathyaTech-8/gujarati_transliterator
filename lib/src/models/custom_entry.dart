/// Whether a saved mapping was typed in as vocabulary or chosen as a fix.
enum CustomOrigin { custom, correction }

/// One locally saved roman-to-Gujarati mapping.
class CustomEntry {
  /// Creates a saved mapping.
  const CustomEntry({
    required this.input,
    required this.output,
    this.prefer = true,
    this.origin = CustomOrigin.custom,
    this.hits = 1,
    this.updatedAt,
  });

  /// Normalized roman key. Word casing is ignored.
  final String input;

  /// Replacement text. This is usually Gujarati Unicode.
  final String output;

  /// When true, this entry outranks the built-in dictionary and phonetic rules.
  final bool prefer;

  /// How the entry was saved.
  final CustomOrigin origin;

  /// How many times this reading has been saved or selected.
  final int hits;

  /// When the entry was last saved, in UTC when the engine wrote it.
  final DateTime? updatedAt;

  /// Returns a copy with the given fields replaced.
  CustomEntry copyWith({
    String? input,
    String? output,
    bool? prefer,
    CustomOrigin? origin,
    int? hits,
    DateTime? updatedAt,
  }) {
    return CustomEntry(
      input: input ?? this.input,
      output: output ?? this.output,
      prefer: prefer ?? this.prefer,
      origin: origin ?? this.origin,
      hits: hits ?? this.hits,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
