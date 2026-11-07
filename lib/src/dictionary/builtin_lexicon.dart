import '../utils/unicode_utils.dart';
import 'word_dictionary.dart';

part 'lexicon_extended.dart';
part 'lexicon_growth.dart';
part 'loanwords.dart';

/// Builds the offline lexicon shipped with the package.
WordDictionary createBuiltinDictionary() {
  final dictionary = WordDictionary();
  loadBuiltinLexicon(dictionary);
  return dictionary;
}

/// Loads the curated core vocabulary into [dictionary].
void loadBuiltinLexicon(WordDictionary dictionary) {
  _loadRows(dictionary, _lexicon);
  _loadRows(dictionary, _extendedLexicon);
  _loadRows(dictionary, _growthLexicon);
  _loadRows(dictionary, _loanLexicon);
  _loadContext(dictionary, _context);
}

void _loadRows(WordDictionary dictionary, String table) {
  for (final line in table.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('|');
    if (parts.length < 2) {
      throw FormatException('Bad lexicon row: $trimmed');
    }
    final roman = parts[0].trim();
    final gujarati = parts[1].trim();
    if (!GujaratiUnicode.containsGujarati(gujarati)) {
      throw FormatException('Lexicon entry has no Gujarati: $roman');
    }
    final frequency = parts.length >= 3 ? int.parse(parts[2].trim()) : 50;
    final kind = parts.length >= 4
        ? EntryKind.values.byName(parts[3].trim())
        : EntryKind.common;
    dictionary.add(roman, gujarati, frequency: frequency, kind: kind);
  }
}

void _loadContext(WordDictionary dictionary, String table) {
  for (final line in table.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('|');
    if (parts.length != 4) {
      throw FormatException('Bad context row: $trimmed');
    }
    dictionary.addContext(
      parts[0].trim(),
      parts[1].trim(),
      parts[2].trim(),
      boostThousandths: int.parse(parts[3].trim()),
    );
  }
}

const String _context = '''
# previous Gujarati | roman | preferred Gujarati | boost thousandths
કેમ|cho|છો|120
મારી|ma|મા|180
તમારી|ma|મા|180
મારો|baap|બાપ|140
ખૂબ|saru|સારું|80
બહુ|saru|સારું|80
ભાઈ|ben|બહેન|420
''';

const String _lexicon = '''
# roman|gujarati|frequency|kind
# Greetings, particles, pronouns
kem|કેમ|90
cho|છો|96
chho|છો|94
chhe|છે|96
che|છે|90
chhu|છું|92
chhun|છું|88
chu|છું|75
hu|હું|93
hun|હું|93
hum|હું|80
shu|શું|95
shun|શું|90
ha|હા|90
haa|હા|88
na|ના|86
nathi|નથી|90
nahi|નહીં|88
nahin|નહીં|80
pan|પણ|90
pan|પાન|55
to|તો|90
ke|કે|70
ane|અને|90
thi|થી|88
ne|ને|80
nu|નું|80
no|નો|78
ni|ની|78
ma|માં|92
ma|મા|74
maa|મા|90
maan|માં|88
par|પર|70
mate|માટે|80
maate|માટે|84
vagar|વગર|60
sudhi|સુધી|70
pachi|પછી|84
pachhi|પછી|80
pahela|પહેલાં|70
pahelaa|પહેલાં|74
tame|તમે|90
ame|અમે|84
aapne|આપણે|80
tu|તું|88
tun|તું|86
te|તે|70
teo|તેઓ|60
mane|મને|88
tane|તને|84
tamne|તમને|86
amne|અમને|70
mari|મારી|86
mari|મરી|48
maro|મારો|84
maru|મારું|84
tari|તારી|80
taro|તારો|78
taru|તારું|78
tamari|તમારી|86
tamaro|તમારો|84
tamaru|તમારું|86
amari|અમારી|70
amaro|અમારો|68
amaru|અમારું|68
potanu|પોતાનું|60
potani|પોતાની|60
potano|પોતાનો|58
kon|કોણ|88
kone|કોને|70
kya|ક્યાં|80
kyan|ક્યાં|84
kyaan|ક્યાં|86
kyare|ક્યારે|86
kevu|કેવું|70
kevi|કેવી|68
ketlu|કેટલું|74
ketla|કેટલા|70
aaje|આજે|90
kale|કાલે|84
kal|કાલ|85
have|હવે|88
savar|સવાર|80
savaar|સવાર|84
sanje|સાંજે|80
ratri|રાત્રી|86
ratre|રાત્રે|80
divas|દિવસ|80
diwas|દિવસ|70
varsh|વર્ષ|60
mahino|મહિનો|60
atyare|અત્યારે|70
aabhar|આભાર|92
abhar|આભાર|84
aabhaar|આભાર|88
dhanyavaad|ધન્યવાદ|84
dhanyavad|ધન્યવાદ|80
namaste|નમસ્તે|90
namaskar|નમસ્કાર|88
swagat|સ્વાગત|70
maaf|માફ|64
kshama|ક્ષમા|64
shubh|શુભ|70
prabhat|પ્રભાત|56
majama|મજામાં|74
maja|મજા|64
kem cho|કેમ છો|96|phrase
shu chhe|શું છે|90|phrase
shubh prabhat|શુભ પ્રભાત|70|phrase
shubh ratri|શુભ રાત્રી|74|phrase
saru chhe|સારું છે|70|phrase

# Days, months, numbers
ravivar|રવિવાર|80
somvar|સોમવાર|80
somavar|સોમવાર|78
mangalvar|મંગળવાર|80
budhvar|બુધવાર|80
guruvar|ગુરુવાર|80
shukravar|શુક્રવાર|92
shukravaar|શુક્રવાર|88
shanivar|શનિવાર|80
kartak|કારતક|50|culture
magshar|માગશર|50|culture
posh|પોષ|50|culture
maha|મહા|48|culture
fagan|ફાગણ|50|culture
chaitra|ચૈત્ર|50|culture
vaishakh|વૈશાખ|50|culture
jeth|જેઠ|50|culture
ashadh|અષાઢ|50|culture
shravan|શ્રાવણ|56|culture
bhadarvo|ભાદરવો|50|culture
aaso|આસો|50|culture
ek|એક|80
be|બે|80
tran|ત્રણ|80
char|ચાર|80
chaar|ચાર|78
panch|પાંચ|82
paanch|પાંચ|80
chha|છ|70
saat|સાત|80
sat|સાત|74
aath|આઠ|80
ath|આઠ|72
nav|નવ|70
das|દસ|74
sou|સો|60
so|સો|56
hazaar|હજાર|60
hajaar|હજાર|56
lakh|લાખ|56
karod|કરોડ|50

# Verbs and adjectives
karvu|કરવું|70
karo|કરો|80
kari|કરી|74
karyu|કર્યું|70
karya|કર્યા|64
aavvu|આવવું|64
aave|આવે|74
aavo|આવો|74
aavyo|આવ્યો|70
aavi|આવી|68
aavya|આવ્યા|64
aavyu|આવ્યું|64
aavu|આવું|60
aavjo|આવજો|70
javu|જવું|64
jaay|જાય|70
jay|જય|66|name
jao|જાઓ|60
gayo|ગયો|74
gaya|ગયા|70
gayi|ગઈ|70
gai|ગઈ|66
gayu|ગયું|64
jovu|જોવું|60
juo|જુઓ|74
khavu|ખાવું|64
khao|ખાઓ|60
peevu|પીવું|56
piyo|પીઓ|50
pidhu|પીધું|60
levu|લેવું|56
lidhu|લીધું|60
aapvu|આપવું|64
aapo|આપો|74
bolvu|બોલવું|56
bolo|બોલો|60
sambhalo|સાંભળો|56
samjho|સમજો|56
thase|થશે|70
thayu|થયું|70
thai|થઈ|66
thay|થાય|70
hatu|હતું|80
hato|હતો|78
hati|હતી|78
hata|હતા|74
rahu|રહું|74
rahe|રહે|60
raho|રહો|60
joiye|જોઈએ|74
joie|જોઈએ|70
saru|સારું|86
sari|સારી|74
saro|સારો|72
kharab|ખરાબ|74
motu|મોટું|70
moti|મોટી|60
mota|મોટા|64
nanu|નાનું|70
nani|નાની|60
sundar|સુંદર|74
safed|સફેદ|56
kalu|કાળું|50
laal|લાલ|56
lal|લાલ|52
lilu|લીલું|50
pilu|પીળું|50
bhooru|ભૂરું|40
garm|ગરમ|56
thandu|ઠંડું|56
mithu|મીઠું|60
kadvo|કડવું|40
saras|સરસ|70
barabar|બરાબર|64
khotu|ખોટું|56
sachu|સાચું|64
navu|નવું|56
nava|નવા|50

# Food, home, family, body
pani|પાણી|95
paani|પાણી|90
panee|પાણી|64
dudh|દૂધ|86
doodh|દૂધ|84
cha|ચા|88
chaa|ચા|86
chai|ચા|80
rotli|રોટલી|80
rotlo|રોટલો|74
shaak|શાક|74
bhat|ભાત|74
bhaat|ભાત|78
dal|દાળ|74
daal|દાળ|78
roti|રોટી|60
khichdi|ખીચડી|64
shiro|શીરો|56
dhokla|ઢોકળા|64
khandvi|ખાંડવી|56
thepla|થેપલા|56
undhiyu|ઊંધિયું|56
khakhra|ખાખરા|56
fafda|ફાફડા|56
bhajiya|ભજિયા|56
papad|પાપડ|50
dahi|દહીં|64
ghee|ઘી|64
ghi|ઘી|60
tel|તેલ|56
khand|ખાંડ|56
mithai|મીઠાઈ|50
phal|ફળ|50
ghar|ઘર|90
rasodu|રસોડું|50
bajar|બજાર|56
bazaar|બજાર|52
bhai|ભાઈ|90
bahen|બહેન|74
ben|બેન|80
ben|બહેન|58
ba|બા|70
bap|બાપ|60
baap|બાપ|70
pita|પિતા|64
bapu|બાપુ|74
bapuji|બાપુજી|70
dikro|દીકરો|74
dikri|દીકરી|74
chhokro|છોકરો|70
chhokri|છોકરી|68
chokro|છોકરો|64
pati|પતિ|56
patni|પત્ની|56
parivar|પરિવાર|70
mitra|મિત્ર|80
prem|પ્રેમ|56
pyar|પ્યાર|50
manas|માણસ|74
stri|સ્ત્રી|64
purush|પુરુષ|50
balak|બાળક|56
mathu|માથું|50
aankh|આંખ|64
ankh|આંખ|56
naak|નાક|50
nak|નાક|44
haath|હાથ|64
hath|હાથ|56
pag|પગ|50
pet|પેટ|44
dil|દિલ|50
man|મન|44

# Places
gujarat|ગુજરાત|96|place
gujaraat|ગુજરાત|90|place
gujarati|ગુજરાતી|90
surendranagar|સુરેન્દ્રનગર|80|place
ahmedabad|અમદાવાદ|90|place
amdavad|અમદાવાદ|88|place
surat|સુરત|84|place
vadodara|વડોદરા|84|place
baroda|વડોદરા|60|place
rajkot|રાજકોટ|84|place
bhavnagar|ભાવનગર|74|place
junagadh|જૂનાગઢ|74|place
jamnagar|જામનગર|74|place
gandhinagar|ગાંધીનગર|80|place
bhuj|ભુજ|74|place
anand|આણંદ|74|place
nadiad|નડિયાદ|64|place
mehsana|મહેસાણા|64|place
morbi|મોરબી|64|place
porbandar|પોરબંદર|70|place
dwarka|દ્વારકા|70|place
somnath|સોમનાથ|70|place
gir|ગીર|50|place
kutch|કચ્છ|64|place
kachchh|કચ્છ|70|place
bharuch|ભરૂચ|64|place
valsad|વલસાડ|56|place
navsari|નવસારી|56|place
gondal|ગોંડલ|50|place
veraval|વેરાવળ|56|place
palanpur|પાલનપુર|56|place
patan|પાટણ|60|place
himatnagar|હિંમતનગર|56|place
godhra|ગોધરા|56|place
dahod|દાહોદ|50|place
amreli|અમરેલી|50|place
botad|બોટાદ|44|place
gandhidham|ગાંધીધામ|56|place
mandvi|માંડવી|50|place
mundra|મુન્દ્રા|50|place
bhachau|ભચાઉ|44|place
anjar|અંજાર|50|place
siddhpur|સિદ્ધપુર|50|place
sidhpur|સિદ્ધપુર|46|place
unjha|ઊંઝા|50|place
visnagar|વિસનગર|50|place
dholka|ધોળકા|44|place
kalol|કલોલ|44|place
kadi|કડી|40|place
ankleshwar|અંકલેશ્વર|56|place
kheda|ખેડા|44|place
okha|ઓખા|40|place
narmada|નર્મદા|56|place
sabarmati|સાબરમતી|56|place
girnar|ગિરનાર|50|place
palitana|પાલીતાણા|44|place
bharat|ભારત|80|place
hindustan|હિન્દુસ્તાન|64|place
india|ઇન્ડિયા|50|place
gam|ગામ|64
gaam|ગામ|70
sheher|શહેર|56
shahar|શહેર|60
nagar|નગર|50
rajya|રાજ્ય|44
sarkar|સરકાર|56

# Names
narvirsinh|નરવીરસિંહ|80|name
narvir|નરવીર|70|name
sinh|સિંહ|80|name
singh|સિંહ|82|name
narvir sinh|નરવીરસિંહ|85|name
patel|પટેલ|90|name
shah|શાહ|84|name
mehta|મહેતા|74|name
desai|દેસાઈ|74|name
joshi|જોશી|70|name
trivedi|ત્રિવેદી|64|name
pandya|પંડ્યા|60|name
gandhi|ગાંધી|84|name
modi|મોદી|70|name
bhatt|ભટ્ટ|64|name
dave|દવે|64|name
shukla|શુક્લ|50|name
parmar|પરમાર|64|name
solanki|સોલંકી|64|name
rathod|રાઠોડ|64|name
jadeja|જાડેજા|64|name
chauhan|ચૌહાણ|56|name
rana|રાણા|50|name
vaghela|વાઘેલા|56|name
chavda|ચાવડા|44|name
gohil|ગોહિલ|44|name
thakor|ઠાકોર|56|name
chaudhary|ચૌધરી|56|name
choudhary|ચૌધરી|52|name
chaudhari|ચૌધરી|50|name
prajapati|પ્રજાપતિ|50|name
suthar|સુથાર|40|name
makwana|મકવાણા|50|name
nayak|નાયક|44|name
amin|અમીન|40|name
sheikh|શેખ|44|name
shaikh|શેખ|44|name
khan|ખાન|50|name
pathan|પઠાણ|44|name
brahman|બ્રાહ્મણ|44|name
brahmin|બ્રાહ્મણ|40|name
acharya|આચાર્ય|44|name
shastri|શાસ્ત્રી|40|name
ambani|અંબાણી|50|name
adani|અદાણી|50|name
tata|ટાટા|40|name
raj|રાજ|50|name
amit|અમિત|44|name
priya|પ્રિયા|44|name
ankit|અંકિત|40|name
neel|નીલ|36|name
kiran|કિરણ|40|name
mehul|મેહુલ|36|name
hardik|હાર્દિક|40|name
virat|વિરાટ|36|name
aditya|આદિત્ય|36|name
arjun|અર્જુન|44|name
krishna|કૃષ્ણ|70|name
krushna|કૃષ્ણ|66|name
krishn|કૃષ્ણ|50|name
radha|રાધા|50|name
sita|સીતા|50|name
lakshmi|લક્ષ્મી|56|name
laxmi|લક્ષ્મી|52|name
ganesh|ગણેશ|64|name
ganpati|ગણપતિ|50|name
hanuman|હનુમાન|60|name
mahesh|મહેશ|44|name
suresh|સુરેશ|44|name
ramesh|રમેશ|44|name
dinesh|દિનેશ|40|name
mukesh|મુકેશ|40|name
naresh|નરેશ|36|name
hitesh|હિતેશ|36|name
jignesh|જિગ્નેશ|40|name
alpesh|અલ્પેશ|36|name
paresh|પરેશ|36|name
nilesh|નિલેશ|36|name
kamlesh|કમલેશ|36|name
ketan|કેતન|36|name
nayan|નયન|36|name
puja|પૂજા|50|name
neha|નેહા|36|name
asha|આશા|40|name
gita|ગીતા|44|name
meena|મીના|36|name
vijay|વિજય|44|name
ajay|અજય|40|name
sanjay|સંજય|44|name
jayesh|જયેશ|36|name
manish|મનીષ|36|name
ashok|અશોક|44|name
vikas|વિકાસ|36|name
prakash|પ્રકાશ|50|name
subhash|સુભાષ|36|name
narendra|નરેન્દ્ર|50|name
mahatma|મહાત્મા|50|name
sardar|સરદાર|44|name
vallabhbhai|વલ્લભભાઈ|40|name
rajubhai|રજુભાઈ|64|name
dilip|દિલીપ|64|name
dilipsinh|દિલીપસિંહ|64|name
harubha|હરુભા|64|name
vishwarajsinh|વિશ્વરાજસિંહ|64|name
danbha|દાનભા|64|name
vanrajsinh|વનરાજસિંહ|64|name
bhavanisinh|ભવાનીસિંહ|64|name
minakshiba|મીનાક્ષીબા|64|name
pruthvirajsinh|પૃથ્વીરાજસિંહ|64|name
divyaraj|દિવ્યરાજ|64|name
krishnaraj|કૃષ્ણરાજ|64|name
virsangbhai|વીરસંગભાઈ|64|name
veersangbhai|વીરસંગભાઈ|60|name
ghanshyam|ઘનશ્યામ|70|name
shyam|શ્યામ|68|name
jai|જય|40|name

# Culture and conjunct-heavy words
bhagwan|ભગવાન|74|culture
bhagavan|ભગવાન|60|culture
mahadev|મહાદેવ|64|culture
shiv|શિવ|64|culture
shiva|શિવ|60|culture
mandir|મંદિર|74|culture
aarti|આરતી|56|culture
prasad|પ્રસાદ|56|culture
dharma|ધર્મ|64|culture
karma|કર્મ|50|culture
moksh|મોક્ષ|44|culture
moksha|મોક્ષ|40|culture
ahimsa|અહિંસા|56|culture
satya|સત્ય|56|culture
mantra|મંત્ર|44|culture
guru|ગુરુ|56|culture
yoga|યોગ|50|culture
yog|યોગ|46|culture
ayurved|આયુર્વેદ|44|culture
diwali|દીવાળી|74|culture
navratri|નવરાત્રી|74|culture
holi|હોળી|56|culture
uttarayan|ઉત્તરાયણ|64|culture
makarsankranti|મકરસંક્રાંતિ|44|culture
janmashtami|જન્માષ્ટમી|44|culture
rathyatra|રથયાત્રા|50|culture
garba|ગરબા|74|culture
garbi|ગરબી|50|culture
dandiya|દાંડિયા|64|culture
dhol|ઢોલ|44|culture
ramayan|રામાયણ|50|culture
mahabharat|મહાભારત|50|culture
gyan|જ્ઞાન|74
gyaan|જ્ઞાન|70
jnan|જ્ઞાન|56
dnyan|જ્ઞાન|64
gnan|જ્ઞાન|50
vidya|વિદ્યા|56
vidyarthi|વિદ્યાર્થી|64
shiksha|શિક્ષા|56
shikshak|શિક્ષક|56
prarthana|પ્રાર્થના|56
siddhi|સિદ્ધિ|36
yuddha|યુદ્ધ|44
sanskrit|સંસ્કૃત|50
swatantra|સ્વતંત્ર|44
swatantrata|સ્વતંત્રતા|50
gandhiji|ગાંધીજી|56|name
sant|સંત|64
shant|શાંત|56
kshatriya|ક્ષત્રિય|36
shri|શ્રી|70
shree|શ્રી|66
om|ઓમ|78|culture
om|ૐ|62|culture
ram|રામ|91|name
ram|રમ|42

# Loanwords and everyday nouns
bus|બસ|50|loan
train|ટ્રેન|50|loan
doctor|ડૉક્ટર|56|loan
station|સ્ટેશન|50|loan
school|સ્કૂલ|44|loan
shala|શાળા|64
mobile|મોબાઈલ|44|loan
computer|કમ્પ્યુટર|44|loan
amul|અમૂલ|50|loan
naam|નામ|84
nam|નામ|80
kaam|કામ|80
kam|કામ|74
pustak|પુસ્તક|50
kitab|કિતાબ|44|loan
paisa|પૈસા|64
rupiya|રૂપિયા|50
dost|દોસ્ત|44|loan
varsad|વરસાદ|64
pavan|પવન|50
dharati|ધરતી|44
aakash|આકાશ|50
suraj|સૂરજ|56
surya|સૂર્ય|44
chand|ચંદ્ર|44
chandra|ચંદ્ર|50
tara|તારા|36
samudra|સમુદ્ર|44
nadi|નદી|50
parvat|પર્વત|36
jhad|ઝાડ|50
zad|ઝાડ|44
phool|ફૂલ|50
ful|ફૂલ|46
pruthvi|પૃથ્વી|40
vijli|વીજળી|44
vahan|વાહન|40
''';
