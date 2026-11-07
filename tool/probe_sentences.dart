import 'package:gujarati_transliterator/gujarati_transliterator.dart';

void main() {
  final engine = GujaratiTransliterator();
  const lines = <String>[
    'hu gujarati bolu chu',
    'aaje bahu saru che',
    'mare ghar javu che',
    'tame kem cho',
    'aapnu gujarat',
    'paani',
    'ghaar',
    'tme',
    'gujrati',
    'raajkot',
    'suurat',
    'bolu',
    'bolu chu',
    'raju chu',
    'Raju',
    'mare',
    'prakriya',
    'shikshan',
    'math',
    'Trilok',
    'patelji',
    'kal',
  ];
  for (final line in lines) {
    final result = engine.transliterate(line);
    final phonetic = engine.transliterate(
      line,
      mode: TransliterationMode.phonetic,
    );
    final top = result.suggestions
        .take(4)
        .map((item) => '${item.text}:${item.confidence.toStringAsFixed(3)}:${item.source.name}')
        .join(', ');
    print('$line => ${result.text} | phonetic ${phonetic.text} | $top');
  }
}
