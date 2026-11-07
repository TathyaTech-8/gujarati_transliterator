import '../dictionary/word_dictionary.dart';
import 'english_guard.dart';
import 'phonetic_parser.dart';

/// Standard spelling of a roman name built from known name parts.
///
/// Several English spellings of one part share a Gujarati form. A stored
/// given name can join a stored surname (`rameshpatel`, `rameshpattel`). An
/// unfamiliar first name keeps its letters and can still take a known ending
/// or a known surname. A word that is not a sequence of these parts is left
/// on the letter reading. This is the common stock of Gujarati and Indian
/// names, not every surname.
String? readName({
  required PhoneticParser parser,
  required WordDictionary dictionary,
  required String prepared,
}) {
  if (prepared.length < 2 || prepared.length > 40) return null;
  if (_skip.contains(prepared)) return null;
  // An internal Sh, Th, or Dh is a phonetic dot. In a name it is a
  // boundary, as in SureshShah.
  if (prepared.contains('.')) {
    final joined = prepared.replaceAll('.', '');
    if (joined != prepared && joined.length >= 2 && !_skip.contains(joined)) {
      final fromJoin = _readPrepared(joined, parser, dictionary);
      if (fromJoin != null) return fromJoin;
    }
  }
  return _readPrepared(prepared, parser, dictionary);
}

String? _readPrepared(
  String prepared,
  PhoneticParser parser,
  WordDictionary dictionary,
) {
  final covered = _coverMulti(prepared, dictionary);
  if (covered != null) return covered;
  final alone = _alone(prepared);
  if (alone != null) return alone;
  return _withEnding(parser, dictionary, prepared);
}

class _NamePiece {
  const _NamePiece(
    this.roman,
    this.gujarati, {
    this.peel = false,
    this.alone = false,
  });

  final String roman;
  final String gujarati;

  /// This part may close a name, as in રાજસિંહ or હરુભા.
  final bool peel;

  /// Typed by itself, this spelling should win over the raw letters.
  final bool alone;
}

const Set<String> _skip = {
  'anymore',
  'caravan',
  'chosen',
  'destroy',
  'forevermore',
  'instagram',
  'maidan',
  'patelji',
  'program',
  'vitamin',
};

const List<_NamePiece> _pieces = [
  _NamePiece('meenakshi', 'મીનાક્ષી', alone: true),
  _NamePiece('minakshi', 'મીનાક્ષી', alone: true),
  _NamePiece('menakshi', 'મીનાક્ષી', alone: true),
  _NamePiece('pruthvee', 'પૃથ્વી', alone: true),
  _NamePiece('prithvee', 'પૃથ્વી', alone: true),
  _NamePiece('narayana', 'નારાયણ', peel: true),
  _NamePiece('bhavanee', 'ભવાની', alone: true),
  _NamePiece('narayan', 'નારાયણ', peel: true),
  _NamePiece('bhavani', 'ભવાની', alone: true),
  _NamePiece('prakash', 'પ્રકાશ', peel: true),
  _NamePiece('pruthvi', 'પૃથ્વી', alone: true),
  _NamePiece('prithvi', 'પૃથ્વી', alone: true),
  _NamePiece('krushna', 'કૃષ્ણ', alone: true),
  _NamePiece('krishna', 'કૃષ્ણ', alone: true),
  _NamePiece('chandra', 'ચંદ્ર', peel: true),
  _NamePiece('vishwa', 'વિશ્વ', alone: true),
  _NamePiece('vishva', 'વિશ્વ', alone: true),
  _NamePiece('dileep', 'દિલીપ', alone: true),
  _NamePiece('shyaam', 'શ્યામ', peel: true, alone: true),
  _NamePiece('bhaai', 'ભાઈ', peel: true),
  _NamePiece('kumaar', 'કુમાર', peel: true, alone: true),
  _NamePiece('divyaa', 'દિવ્ય', alone: true),
  _NamePiece('sahib', 'સાહેબ', peel: true, alone: true),
  _NamePiece('saheb', 'સાહેબ', peel: true, alone: true),
  _NamePiece('singh', 'સિંહ', peel: true),
  _NamePiece('shyam', 'શ્યામ', peel: true, alone: true),
  _NamePiece('devee', 'દેવી', peel: true, alone: true),
  _NamePiece('dilip', 'દિલીપ', alone: true),
  _NamePiece('divya', 'દિવ્ય', alone: true),
  _NamePiece('kumar', 'કુમાર', peel: true, alone: true),
  _NamePiece('devi', 'દેવી', peel: true, alone: true),
  _NamePiece('mohan', 'મોહન'),
  _NamePiece('bhaa', 'ભા', peel: true),
  _NamePiece('sang', 'સંગ', peel: true),
  _NamePiece('veer', 'વીર', peel: true),
  _NamePiece('sinh', 'સિંહ', peel: true),
  _NamePiece('bhai', 'ભાઈ', peel: true),
  _NamePiece('raaj', 'રાજ', peel: true, alone: true),
  _NamePiece('raam', 'રામ'),
  _NamePiece('daan', 'દાન', alone: true),
  _NamePiece('daas', 'દાસ'),
  _NamePiece('laal', 'લાલ', peel: true),
  _NamePiece('ghan', 'ઘન'),
  _NamePiece('raj', 'રાજ', peel: true, alone: true),
  _NamePiece('ram', 'રામ'),
  _NamePiece('das', 'દાસ'),
  _NamePiece('lal', 'લાલ', peel: true),
  _NamePiece('dan', 'દાન', alone: true),
  _NamePiece('van', 'વન', alone: true),
  _NamePiece('dev', 'દેવ'),
  _NamePiece('nar', 'નર'),
  _NamePiece('vir', 'વીર', peel: true),
  _NamePiece('ben', 'બેન', peel: true),
  _NamePiece('bha', 'ભા', peel: true),
  _NamePiece('baa', 'બા', peel: true),
  _NamePiece('ba', 'બા', peel: true),
];

final Map<String, _NamePiece> _pieceByRoman = {
  for (final piece in _pieces) piece.roman: piece,
};

/// Surnames safe to attach to an unfamiliar first name.
///
/// Short or English-shaped keys in [_coverOnly] still join a known given
/// name, and they are not peeled off an ordinary word.
const Map<String, String> _surnames = {
  'patell': 'પટેલ',
  'pattel': 'પટેલ',
  'paatel': 'પટેલ',
  'patel': 'પટેલ',
  'shaah': 'શાહ',
  'shaha': 'શાહ',
  'shah': 'શાહ',
  'mehtaa': 'મહેતા',
  'mehta': 'મહેતા',
  'dessai': 'દેસાઈ',
  'desayi': 'દેસાઈ',
  'desae': 'દેસાઈ',
  'desai': 'દેસાઈ',
  'joshee': 'જોશી',
  'joshi': 'જોશી',
  'trivedee': 'ત્રિવેદી',
  'trivedy': 'ત્રિવેદી',
  'trivedi': 'ત્રિવેદી',
  'pandeya': 'પંડ્યા',
  'pandia': 'પંડ્યા',
  'pandya': 'પંડ્યા',
  'gaandhi': 'ગાંધી',
  'gandhi': 'ગાંધી',
  'modee': 'મોદી',
  'modi': 'મોદી',
  'bhatta': 'ભટ્ટ',
  'bhatt': 'ભટ્ટ',
  'bhati': 'ભાટી',
  'daave': 'દવે',
  'dave': 'દવે',
  'shukla': 'શુક્લ',
  'parmaar': 'પરમાર',
  'parmar': 'પરમાર',
  'solankee': 'સોલંકી',
  'solanki': 'સોલંકી',
  'rathaur': 'રાઠોડ',
  'rathore': 'રાઠોડ',
  'rathod': 'રાઠોડ',
  'jadeja': 'જાડેજા',
  'chouhan': 'ચૌહાણ',
  'chohan': 'ચૌહાણ',
  'chauhan': 'ચૌહાણ',
  'raana': 'રાણા',
  'rana': 'રાણા',
  'vaghela': 'વાઘેલા',
  'chavada': 'ચાવડા',
  'chawda': 'ચાવડા',
  'chavda': 'ચાવડા',
  'gohil': 'ગોહિલ',
  'thakore': 'ઠાકોર',
  'thakor': 'ઠાકોર',
  'thakur': 'ઠાકુર',
  'chowdhury': 'ચૌધરી',
  'chowdhary': 'ચૌધરી',
  'choudhury': 'ચૌધરી',
  'choudhary': 'ચૌધરી',
  'chaudhri': 'ચૌધરી',
  'chaudhari': 'ચૌધરી',
  'chaudhary': 'ચૌધરી',
  'prajapati': 'પ્રજાપતિ',
  'suthar': 'સુથાર',
  'sutar': 'સુથાર',
  'makvana': 'મકવાણા',
  'makwana': 'મકવાણા',
  'nayak': 'નાયક',
  'naik': 'નાયક',
  'amin': 'અમીન',
  'shaykh': 'શેખ',
  'shekh': 'શેખ',
  'sheikh': 'શેખ',
  'shaikh': 'શેખ',
  'khaan': 'ખાન',
  'khan': 'ખાન',
  'pathan': 'પઠાણ',
  'brahmin': 'બ્રાહ્મણ',
  'brahman': 'બ્રાહ્મણ',
  'aacharya': 'આચાર્ય',
  'acharya': 'આચાર્ય',
  'shastri': 'શાસ્ત્રી',
  'ambani': 'અંબાણી',
  'adani': 'અદાણી',
  'tata': 'ટાટા',
  'vyaas': 'વ્યાસ',
  'vyas': 'વ્યાસ',
  'purohit': 'પુરોહિત',
  'pandit': 'પંડિત',
  'kothari': 'કોઠારી',
  'soni': 'સોની',
  'lohar': 'લુહાર',
  'luhar': 'લુહાર',
  'darjee': 'દરજી',
  'darji': 'દરજી',
  'mochi': 'મોચી',
  'kumhar': 'કુંભાર',
  'kumbhar': 'કુંભાર',
  'barot': 'બારોટ',
  'raval': 'રાવળ',
  'rawal': 'રાવળ',
  'brahmbhatt': 'બ્રહ્મભટ્ટ',
  'bhavsar': 'ભાવસાર',
  'kansara': 'કંસારા',
  'valand': 'વાળંદ',
  'mistry': 'મિસ્ત્રી',
  'mistri': 'મિસ્ત્રી',
  'gajjar': 'ગજ્જર',
  'patidar': 'પાટીદાર',
  'parikh': 'પરીખ',
  'parekh': 'પારેખ',
  'doshi': 'દોશી',
  'sanghavi': 'સંઘવી',
  'sanghvi': 'સંઘવી',
  'sheth': 'શેઠ',
  'dalal': 'દલાલ',
  'vakil': 'વકીલ',
  'zala': 'ઝાલા',
  'jhala': 'ઝાલા',
  'rathva': 'રાઠવા',
  'vasava': 'વસાવા',
  'gamit': 'ગમીત',
  'dodia': 'ડોડિયા',
  'bariya': 'બારિયા',
  'ahir': 'આહીર',
  'rabari': 'રબારી',
  'bharwad': 'ભરવાડ',
  'charan': 'ચારણ',
  'gadhvi': 'ગઢવી',
  'gadhavi': 'ગઢવી',
  'macwan': 'મેકવાન',
  'khokhar': 'ખોખર',
  'meman': 'મેમણ',
  'memon': 'મેમણ',
  'malek': 'મલેક',
  'mallik': 'મલિક',
  'malik': 'મલિક',
  'khoja': 'ખોજા',
  'bohora': 'બોહરા',
  'bohra': 'બોહરા',
  'vohra': 'વ્હોરા',
  'quraishi': 'કુરેશી',
  'kureshi': 'કુરેશી',
  'qureshi': 'કુરેશી',
  'ansari': 'અન્સારી',
  'sayyid': 'સૈયદ',
  'saiyed': 'સૈયદ',
  'sayed': 'સૈયદ',
  'syed': 'સૈયદ',
  'qadri': 'કાદરી',
  'kadri': 'કાદરી',
  'qazi': 'કાઝી',
  'kazi': 'કાઝી',
  'ghanchi': 'ઘાંચી',
  'momin': 'મોમિન',
  'baloch': 'બલોચ',
  'sipahi': 'સિપાઈ',
  'sipai': 'સિપાઈ',
  'godrej': 'ગોદરેજ',
  'wadia': 'વાડિયા',
  'sethna': 'સેઠના',
  'sharma': 'શર્મા',
  'verma': 'વર્મા',
  'varma': 'વર્મા',
  'gupta': 'ગુપ્તા',
  'agarwala': 'અગ્રવાલ',
  'aggarwal': 'અગ્રવાલ',
  'agrawal': 'અગ્રવાલ',
  'agarwal': 'અગ્રવાલ',
  'jain': 'જૈન',
  'reddy': 'રેડ્ડી',
  'nair': 'નાયર',
  'menon': 'મેનન',
  'pillai': 'પિળ્ળૈ',
  'iyengar': 'અય્યંગાર',
  'iyer': 'અય્યર',
  'kaur': 'કૌર',
  'dhillon': 'ઢિલ્લોં',
  'sethi': 'સેઠી',
  'kapoor': 'કપૂર',
  'kapur': 'કપૂર',
  'khanna': 'ખન્ના',
  'malhotra': 'મલહોત્રા',
  'chopra': 'ચોપ્રા',
  'mehra': 'મેહરા',
  'saxena': 'સક્સેના',
  'srivastav': 'શ્રીવાસ્તવ',
  'shrivastav': 'શ્રીવાસ્તવ',
  'srivastava': 'શ્રીવાસ્તવ',
  'banerji': 'બેનર્જી',
  'banerjee': 'બેનર્જી',
  'chaterjee': 'ચેટર્જી',
  'chatterjee': 'ચેટર્જી',
  'mukherji': 'મુખર્જી',
  'mukherjee': 'મુખર્જી',
  'dasgupta': 'દાસગુપ્તા',
  'chakraborty': 'ચક્રવર્તી',
  'chakravarty': 'ચક્રવર્તી',
  'panday': 'પાંડે',
  'pandey': 'પાંડે',
  'tivari': 'તિવારી',
  'tiwari': 'તિવારી',
  'misra': 'મિશ્ર',
  'mishra': 'મિશ્ર',
  'dubey': 'દુબે',
  'dube': 'દુબે',
  'yadav': 'યાદવ',
  'kushwaha': 'કુશવાહા',
  'patil': 'પાટીલ',
  'shinde': 'શિંદે',
  'jadhav': 'જાધવ',
  'bose': 'બોઝ',
  'ghosh': 'ઘોષ',
  'datta': 'દત્ત',
  'dutta': 'દત્ત',
  'dutt': 'દત્ત',
  'merchant': 'મર્ચન્ટ',
  'more': 'મોરે',
  'nath': 'નાથ',
  'rao': 'રાવ',
  'roy': 'રોય',
  'sen': 'સેન',
  'jha': 'ઝા',
  'wallah': 'વાલા',
  'wala': 'વાલા',
  'vala': 'વાલા',
};

/// These join a known given name. They are not cut off an ordinary word.
const Set<String> _coverOnly = {
  'datta',
  'dutt',
  'dutta',
  'ghosh',
  'jha',
  'merchant',
  'more',
  'nath',
  'rao',
  'roy',
  'sen',
};

const Set<String> _noAlone = {
  'datta',
  'dutt',
  'dutta',
  'ghosh',
  'jha',
  'merchant',
  'more',
  'nath',
  'rao',
  'roy',
  'sen',
  'vala',
  'wala',
  'wallah',
};

/// Given-name spellings that are not already a lexicon key.
const Map<String, String> _given = {
  'aaryan': 'આર્યન',
  'aarav': 'આરવ',
  'aamir': 'આમિર',
  'abdulla': 'અબ્દુલ્લા',
  'abdullah': 'અબ્દુલ્લા',
  'abdul': 'અબ્દુલ',
  'ahmad': 'અહમદ',
  'ahmed': 'અહમદ',
  'aisha': 'આયેશા',
  'amir': 'આમિર',
  'anand': 'આનંદ',
  'anita': 'અનિતા',
  'batli': 'બાટલી',
  'anjali': 'અંજલિ',
  'aryan': 'આર્યન',
  'ayesha': 'આયેશા',
  'bhavesh': 'ભાવેશ',
  'bhoomi': 'ભૂમિ',
  'bhumi': 'ભૂમિ',
  'bhupender': 'ભુપેન્દ્ર',
  'bhupendra': 'ભુપેન્દ્ર',
  'chirag': 'ચિરાગ',
  'david': 'ડેવિડ',
  'deepa': 'દીપા',
  'devendra': 'દેવેન્દ્ર',
  'dharmendra': 'ધર્મેન્દ્ર',
  'dipa': 'દીપા',
  'diya': 'દિયા',
  'falguni': 'ફાલ્ગુની',
  'fareeda': 'ફરીદા',
  'farida': 'ફરીદા',
  'fatema': 'ફાતેમા',
  'fatima': 'ફાતેમા',
  'feroz': 'ફિરોઝ',
  'firoz': 'ફિરોઝ',
  'foram': 'ફોરમ',
  'gajendra': 'ગજેન્દ્ર',
  'geeta': 'ગીતા',
  'gopal': 'ગોપાલ',
  'govind': 'ગોવિંદ',
  'haresh': 'હરેશ',
  'harish': 'હરીશ',
  'harsh': 'હર્ષ',
  'hasan': 'હસન',
  'hassan': 'હસન',
  'hetal': 'હેતલ',
  'hiren': 'હિરેન',
  'homi': 'હોમી',
  'husain': 'હુસેન',
  'hussain': 'હુસેન',
  'ibrahim': 'ઇબ્રાહિમ',
  'imran': 'ઇમરાન',
  'irfan': 'ઇરફાન',
  'ishvar': 'ઈશ્વર',
  'ishwar': 'ઈશ્વર',
  'ismail': 'ઇસ્માઇલ',
  'jagannath': 'જગન્નાથ',
  'jalpa': 'જલ્પા',
  'jamshed': 'જમશેદ',
  'javed': 'જાવેદ',
  'jehangir': 'જહાંગીર',
  'jitender': 'જિતેન્દ્ર',
  'jitendra': 'જિતેન્દ્ર',
  'john': 'જોન',
  'joseph': 'જોસેફ',
  'kalpesh': 'કલ્પેશ',
  'kavita': 'કવિતા',
  'kavya': 'કાવ્યા',
  'kinjal': 'કિંજલ',
  'komal': 'કોમલ',
  'lalita': 'લલિતા',
  'lokesh': 'લોકેશ',
  'madhav': 'માધવ',
  'mahendra': 'મહેન્દ્ર',
  'mamta': 'મમતા',
  'manoj': 'મનોજ',
  'maria': 'મારિયા',
  'mary': 'મેરી',
  'mayur': 'મયૂર',
  'meher': 'મેહેર',
  'michael': 'માઇકલ',
  'mohamed': 'મોહમ્મદ',
  'mohammad': 'મોહમ્મદ',
  'mohammed': 'મોહમ્મદ',
  'mohit': 'મોહિત',
  'muhammad': 'મોહમ્મદ',
  'mustafa': 'મુસ્તફા',
  'nariman': 'નરીમાન',
  'nasreen': 'નસરીન',
  'nasrin': 'નસરીન',
  'neeta': 'નીતા',
  'nikita': 'નિકિતા',
  'nitin': 'નિતિન',
  'omkar': 'ઓમકાર',
  'parth': 'પાર્થ',
  'parveen': 'પરવીન',
  'parvin': 'પરવીન',
  'pervez': 'પરવેઝ',
  'peter': 'પીટર',
  'priyanka': 'પ્રિયંકા',
  'rajendra': 'રાજેન્દ્ર',
  'rajesh': 'રાજેશ',
  'rakesh': 'રાકેશ',
  'rashid': 'રશીદ',
  'rasheed': 'રશીદ',
  'ratan': 'રતન',
  'rehana': 'રેહાના',
  'riya': 'રિયા',
  'rohit': 'રોહિત',
  'sachin': 'સચિન',
  'salman': 'સલમાન',
  'sankar': 'શંકર',
  'savita': 'સવિતા',
  'seeta': 'સીતા',
  'shabana': 'શબાના',
  'shankar': 'શંકર',
  'shilpa': 'શિલ્પા',
  'shweta': 'શ્વેતા',
  'sneha': 'સ્નેહા',
  'sohail': 'સોહેલ',
  'sohil': 'સોહેલ',
  'som': 'સોમ',
  'sonal': 'સોનલ',
  'sunita': 'સુનિતા',
  'surendra': 'સુરેન્દ્ર',
  'swaroop': 'સ્વરૂપ',
  'swarup': 'સ્વરૂપ',
  'sweta': 'શ્વેતા',
  'thomas': 'થોમસ',
  'umesh': 'ઉમેશ',
  'urvashi': 'ઉર્વશી',
  'urvasi': 'ઉર્વશી',
  'vipul': 'વિપુલ',
  'viren': 'વીરેન',
  'yash': 'યશ',
  'yogesh': 'યોગેશ',
  'yusuf': 'યુસુફ',
  'rahul': 'રાહુલ',
};

String? _alone(String prepared) {
  final piece = _pieceByRoman[prepared];
  if (piece != null && piece.alone) return piece.gujarati;
  if (_noAlone.contains(prepared)) return null;
  return _surnames[prepared] ?? _given[prepared];
}

String? _match(String slice, WordDictionary dictionary) {
  if (slice.length < 2) return null;
  final piece = _pieceByRoman[slice];
  if (piece != null) return piece.gujarati;
  if (slice.length >= 3) {
    final stored = _bestName(dictionary, slice);
    if (stored != null) return stored;
  }
  return _surnames[slice] ?? _given[slice];
}

String? _bestName(WordDictionary dictionary, String slice) {
  final hits = dictionary.lookupWord(slice);
  DictionaryEntry? best;
  for (final hit in hits) {
    if (hit.kind != EntryKind.name) continue;
    if (best == null || hit.frequency > best.frequency) best = hit;
  }
  return best?.gujarati;
}

String? _coverMulti(String text, WordDictionary dictionary) {
  if (text.length < 4) return null;
  final memo = List<String?>.filled(text.length + 1, null);
  final seen = List<bool>.filled(text.length + 1, false);

  String? oneOrMore(int start) {
    if (start == text.length) return '';
    if (seen[start]) return memo[start];
    seen[start] = true;
    for (var len = text.length - start; len >= 2; len--) {
      final part = _match(text.substring(start, start + len), dictionary);
      if (part == null) continue;
      final rest = oneOrMore(start + len);
      if (rest == null) continue;
      memo[start] = '$part$rest';
      return memo[start];
    }
    return null;
  }

  for (var len = text.length - 2; len >= 2; len--) {
    final part = _match(text.substring(0, len), dictionary);
    if (part == null) continue;
    final rest = oneOrMore(len);
    if (rest == null || rest.isEmpty) continue;
    return '$part$rest';
  }
  return null;
}

class _Hit {
  const _Hit(this.roman, this.gujarati);
  final String roman;
  final String gujarati;
}

_Hit? _bestPeel(String rest) {
  _Hit? best;
  void consider(String roman, String gujarati, {required bool surname}) {
    if (rest.length <= roman.length || !rest.endsWith(roman)) return;
    final stem = rest.substring(0, rest.length - roman.length);
    if (surname && !_surnameStemOk(stem, roman)) return;
    if (best == null || roman.length > best!.roman.length) {
      best = _Hit(roman, gujarati);
    }
  }

  for (final piece in _pieces) {
    if (!piece.peel) continue;
    consider(piece.roman, piece.gujarati, surname: false);
  }
  final max = rest.length - 3;
  if (max >= 4) {
    final limit = max > 18 ? 18 : max;
    for (var len = limit; len >= 4; len--) {
      final suffix = rest.substring(rest.length - len);
      if (_coverOnly.contains(suffix)) continue;
      final spelling = _surnames[suffix];
      if (spelling == null) continue;
      consider(suffix, spelling, surname: true);
    }
  }
  return best;
}

bool _surnameStemOk(String stem, String suffix) {
  if (stem.length < 3 || EnglishGuard.isPlainOrFunction(stem)) return false;
  if (suffix == 'wala' || suffix == 'vala' || suffix == 'wallah') {
    return stem.length >= 4;
  }
  if (suffix.length < 5 && stem.length < 4) return false;
  return true;
}

String? _withEnding(
  PhoneticParser parser,
  WordDictionary dictionary,
  String text,
) {
  final endings = <String>[];
  var rest = text;
  while (rest.isNotEmpty) {
    final peel = _bestPeel(rest);
    if (peel == null) break;
    endings.insert(0, peel.gujarati);
    rest = rest.substring(0, rest.length - peel.roman.length);
  }
  if (endings.isEmpty || rest.length < 2) return null;
  final head = _coverMulti(rest, dictionary) ??
      _match(rest, dictionary) ??
      _storedName(dictionary, rest) ??
      parser.parse(rest);
  if (head.isEmpty) return null;
  return '$head${endings.join()}';
}

String? _storedName(WordDictionary dictionary, String stem) {
  final hits = dictionary.lookupWord(stem);
  if (hits.isEmpty) return null;
  var best = hits.first;
  for (final hit in hits.skip(1)) {
    if (hit.frequency > best.frequency) best = hit;
  }
  if (best.kind != EntryKind.name && best.kind != EntryKind.place) {
    return null;
  }
  return best.gujarati;
}
