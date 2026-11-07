import '../models/suggestion.dart';
import '../utils/unicode_utils.dart';
import 'phonetic_parser.dart';

/// One grammatical reading of a roman word.
class GrammarReading {
  /// Creates a reading.
  const GrammarReading({
    required this.text,
    required this.score,
    required this.source,
  });

  /// Gujarati spelling produced from a stem plus an ending.
  final String text;

  /// Intelligent-mode score in thousandths. Kept under a frequency-1
  /// dictionary score of 554, and above the typed phonetic score of 500.
  final int score;

  /// Why this reading was produced.
  final SuggestionSource source;
}

/// Productive Gujarati endings and a few suppletive auxiliaries.
///
/// The stem list is closed. An unknown name is not rewritten just because it
/// ends in a letter that can also be an ending. Keys are hash probes of the
/// stem table, never a scan of the lexicon.
abstract final class GrammarReadings {
  /// Readings for one prepared word. Empty when no ending applies.
  static List<GrammarReading> generate({
    required PhoneticParser parser,
    required String original,
    required String prepared,
    required String literal,
    String? nextRoman,
  }) {
    if (prepared.isEmpty || literal.isEmpty || prepared.length > 32) {
      return const [];
    }
    final readings = <GrammarReading>[];
    final seen = <String>{literal};

    void add(String? text, int score, SuggestionSource source) {
      if (text == null || text.isEmpty || text == literal || !seen.add(text)) {
        return;
      }
      readings.add(GrammarReading(text: text, score: score, source: source));
    }

    final titled = _titleCase(original) || _shouting(original);
    if (titled && !_titleSafe.contains(prepared)) return const [];

    final irregular = _irregular[prepared];
    if (irregular != null) {
      final text = GujaratiUnicode.containsGujarati(irregular)
          ? irregular
          : parser.parse(irregular);
      add(text, _score(nextRoman), SuggestionSource.orthographic);
      return readings;
    }
    if (titled) return const [];

    for (final ending in _endings) {
      if (prepared.length <= ending.roman.length) continue;
      if (!prepared.endsWith(ending.roman)) continue;
      final typedStem = prepared.substring(
        0,
        prepared.length - ending.roman.length,
      );
      final stem = _parserStem(typedStem);
      if (stem == null) continue;
      final schwa = ending.schwa && _clusterBefore(prepared, typedStem.length);
      final key = schwa ? '$stem${ending.tail}' : '$stem${ending.bare}';
      add(parser.parse(key), _score(nextRoman), _source(nextRoman));
      return readings;
    }

    if (prepared.length >= 4 && prepared.endsWith('i')) {
      final stem = _parserStem(prepared.substring(0, prepared.length - 1));
      if (stem != null) {
        add(parser.parse('${stem}ee'), _score(nextRoman), _source(nextRoman));
      }
    } else if (prepared.length >= 5 &&
        (prepared.endsWith('o') || prepared.endsWith('u'))) {
      final stem = _parserStem(
        prepared.substring(0, prepared.length - 1),
        requireCluster: true,
      );
      if (stem != null) {
        final nasal = prepared.endsWith('u') && _firstPerson(nextRoman);
        final tail = nasal ? 'u.m' : prepared[prepared.length - 1];
        add(parser.parse('$stem$tail'), _score(nextRoman), _source(nextRoman));
      }
    }
    return readings;
  }
}

class _Ending {
  const _Ending(this.roman, this.bare, this.tail, {this.schwa = false});

  final String roman;
  final String bare;
  final String tail;
  final bool schwa;
}

const List<_Ending> _endings = [
  _Ending('vanum', 'vaanu.m', 'avaanu.m', schwa: true),
  _Ending('ishum', 'iishu.m', 'iishu.m'),
  _Ending('vanu', 'vaanu.m', 'avaanu.m', schwa: true),
  _Ending('vani', 'vaani', 'avaani', schwa: true),
  _Ending('vano', 'vaano', 'avaano', schwa: true),
  _Ending('vana', 'vaanaa', 'avaanaa', schwa: true),
  _Ending('ishu', 'iishu.m', 'iishu.m'),
  _Ending('ishe', 'iishe', 'iishe'),
  _Ending('isho', 'iisho', 'iisho'),
  _Ending('ine', 'iine', 'iine'),
  _Ending('ish', 'iish', 'iish'),
  _Ending('she', 'she', 'ashe', schwa: true),
  _Ending('sho', 'sho', 'asho', schwa: true),
  _Ending('jo', 'jo', 'ajo', schwa: true),
  _Ending('vu', 'vu.m', 'avu.m', schwa: true),
  _Ending('tu', 'tu.m', 'atu.m', schwa: true),
  _Ending('ti', 'tee', 'atee', schwa: true),
  _Ending('to', 'to', 'ato', schwa: true),
];

/// Typed stem to the roman the existing parser should see.
const Map<String, String> _stems = {
  'kar': 'kar',
  'ja': 'ja',
  'jav': 'jav',
  'aav': 'aav',
  'av': 'aav',
  'aap': 'aap',
  'ap': 'aap',
  'de': 'de',
  'le': 'le',
  'kha': 'khaa',
  'pi': 'pee',
  'bol': 'bol',
  'rakh': 'raakh',
  'mokal': 'mokal',
  'bes': 'bes',
  'uth': 'uuth',
  'has': 'has',
  'gam': 'gam',
  'jag': 'jaag',
  'chal': 'chaal',
  'bhul': 'bhool',
  'mal': 'ma.l',
  'mar': 'mar',
  'muk': 'mook',
  'ho': 'ho',
  'kah': 'kah',
  'puch': 'poochh',
  'samaj': 'samaj',
  'sikh': 'sheekh',
  'shikh': 'sheekh',
  'jan': 'jaa.n',
  'man': 'maan',
  'ban': 'ban',
  'banav': 'banaav',
  'lav': 'laav',
  'lakh': 'lakh',
  'likh': 'likh',
  'ram': 'ram',
  'far': 'far',
  'pad': 'pa.d',
  'rah': 'rah',
  'khol': 'khol',
  'dekh': 'dekh',
  'jo': 'jo',
  'ju': 'ju',
  'dod': 'dod',
  'bhag': 'bhaag',
  'kadh': 'kaa.dh',
  'vach': 'vaa.mch',
  'bolav': 'bolaav',
  'karav': 'karaav',
  'su': 'soo',
  'joy': 'joy',
  'bhar': 'bhar',
  'dho': 'dho',
  'pu': 'pu',
  'lekh': 'lekh',
  'tha': 'tha',
  'badal': 'badal',
};

const Map<String, String> _irregular = {
  'didhu': 'deedhu.m',
  'didhi': 'deedhee',
  'didha': 'deedhaa',
  'didho': 'deedho',
  'lidhu': 'leedhu.m',
  'lidhi': 'leedhee',
  'lidha': 'leedhaa',
  'lidho': 'leedho',
  'hatu': 'hatu.m',
  'hati': 'hatee',
  'hata': 'hataa',
  'gayu': 'gayu.m',
  'gaya': 'gayaa',
  'gayi': 'ગઈ',
  'gai': 'ગઈ',
  'thayu': 'thayu.m',
  'thaya': 'thayaa',
  'thayi': 'થઈ',
  'thai': 'થઈ',
  'kari': 'karee',
  'aavi': 'aavee',
  'aapi': 'aapee',
  'male': 'ma.le',
  'vage': 'vaage',
  'vagi': 'vaagee',
  'vagyu': 'vaagyu.m',
  'vadharo': 'vadhaaro',
  'vadhari': 'vadhaaree',
  'vadharu': 'vadhaaru.m',
  'ochhu': 'ochhu.m',
  'ochhi': 'ochhee',
  'ochha': 'ochhaa',
  'savare': 'savaare',
  'banave': 'banaave',
  'papa': 'પપ્પા',
  'coffee': 'કોફી',
  'kapda': 'kapa.daa.m',
  'kyare': 'kyaare',
  'kyaare': 'kyaare',
  'kya': 'kyaa.m',
  'kyaan': 'kyaa.m',
  'kevi': 'kevee',
  'kevu': 'kevu.m',
  'rite': 'reete',
  'ahval': 'ahevaal',
  'aheval': 'ahevaal',
  'palvanu': 'paa.lavaanu.m',
  'vyavastha': 'vyavasthaa',
  'javabdari': 'javaabadaaree',
  'jawabdari': 'javaabadaaree',
  'karyakram': 'kaaryakram',
  'mahiti': 'maahitee',
};

const Set<String> _titleSafe = {
  'aapde',
  'ahval',
  'aheval',
  'coffee',
  'javabdari',
  'jawabdari',
  'kapda',
  'karyakram',
  'kya',
  'kyaan',
  'kyaare',
  'kyare',
  'mahiti',
  'palvanu',
  'papa',
  'savare',
  'vyavastha',
};

String? _parserStem(String stem, {bool requireCluster = false}) {
  if (stem.length < 2) return null;
  if (requireCluster && _insertSchwa(stem) == null) return null;
  final direct = _stems[stem];
  if (direct != null) return direct;
  if (stem.length < 4) return null;
  final expanded = _insertSchwa(stem);
  if (expanded == null) return null;
  return _stems[expanded];
}

bool _clusterBefore(String prepared, int stemLength) {
  if (stemLength <= 0 || stemLength >= prepared.length) return false;
  return _isConsonantEnd(prepared.substring(0, stemLength)) &&
      _isConsonantStart(prepared.substring(stemLength));
}

bool _isConsonantEnd(String text) {
  if (text.isEmpty) return false;
  const vowels = [
    'aa',
    'ai',
    'au',
    'ee',
    'ii',
    'oo',
    'ou',
    'uu',
    'a',
    'e',
    'i',
    'o',
    'u'
  ];
  for (final vowel in vowels) {
    if (text.endsWith(vowel)) return false;
  }
  return true;
}

bool _isConsonantStart(String text) {
  if (text.isEmpty) return false;
  return !'aeiou'.contains(text[0]);
}

String? _insertSchwa(String stem) {
  final parts = _pieces(stem);
  for (var i = 0; i < parts.length - 1; i++) {
    if (!parts[i].consonant || !parts[i + 1].consonant) continue;
    final at = parts[i + 1].start;
    return '${stem.substring(0, at)}a${stem.substring(at)}';
  }
  return null;
}

class _Piece {
  const _Piece(this.consonant, this.start);
  final bool consonant;
  final int start;
}

List<_Piece> _pieces(String text) {
  const consonants = [
    'chh',
    'ksh',
    'th',
    'dh',
    'kh',
    'gh',
    'bh',
    'ph',
    'sh',
    'ch',
  ];
  const vowels = [
    'aa',
    'ai',
    'au',
    'ee',
    'ii',
    'oo',
    'ou',
    'uu',
    'a',
    'e',
    'i',
    'o',
    'u'
  ];
  final pieces = <_Piece>[];
  var index = 0;
  while (index < text.length) {
    String? consonant;
    for (final candidate in consonants) {
      if (text.startsWith(candidate, index)) {
        consonant = candidate;
        break;
      }
    }
    if (consonant != null) {
      pieces.add(_Piece(true, index));
      index += consonant.length;
      continue;
    }
    String? vowel;
    for (final candidate in vowels) {
      if (text.startsWith(candidate, index)) {
        vowel = candidate;
        break;
      }
    }
    if (vowel != null) {
      pieces.add(_Piece(false, index));
      index += vowel.length;
      continue;
    }
    final unit = text.codeUnitAt(index);
    if (unit >= 0x61 && unit <= 0x7A) pieces.add(_Piece(true, index));
    index++;
  }
  return pieces;
}

int _score(String? next) => _confirms(next) ? 548 : 540;

SuggestionSource _source(String? next) =>
    _confirms(next) ? SuggestionSource.context : SuggestionSource.orthographic;

bool _confirms(String? next) {
  if (next == null || next.isEmpty) return false;
  final key = next.toLowerCase();
  const cues = {
    'che',
    'chhe',
    'chu',
    'chhu',
    'chhun',
    'chum',
    'cho',
    'chho',
    'nathi',
    'hoy',
  };
  return cues.contains(key);
}

bool _firstPerson(String? next) {
  if (next == null) return false;
  const cues = {'chu', 'chhu', 'chhun', 'chum'};
  return cues.contains(next.toLowerCase());
}

bool _titleCase(String word) {
  if (word.length < 2) return false;
  final rest = word.substring(1);
  return word[0].toUpperCase() == word[0] &&
      word[0].toLowerCase() != word[0] &&
      rest == rest.toLowerCase();
}

bool _shouting(String word) {
  final letters = word.replaceAll(RegExp('[^A-Za-z]'), '');
  return letters.length >= 2 && letters == letters.toUpperCase();
}
