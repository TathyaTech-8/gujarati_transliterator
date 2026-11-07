part of 'builtin_lexicon.dart';

/// More hand-written spellings. These stay out of the held-out corpus.
///
/// The rows are original editorial entries. Frequencies are ranks, not
/// counts from an outside corpus. Inflected forms used as evaluation data
/// are intentionally absent.
const String _growthLexicon = '''
# roman|gujarati|frequency|kind
# Manner and time
khub|ખૂબ|64
bahu|બહુ|60
dhime|ધીમે|52
dhimu|ધીમું|48
turant|તુરત|52
achanak|અચાનક|48
ekdam|એકદમ|52
seedhu|સીધું|50
seedha|સીધા|46
seedhi|સીધી|46
ultu|ઊલટું|40
ulti|ઊલટી|36
aaspas|આસપાસ|44
bilkul|બિલકુલ|40|loan
jor|જોર|44
jor thi|જોરથી|40|phrase
khub saru|ખૂબ સારું|70|phrase
bahu saru|બહુ સારું|60|phrase
dhime dhime|ધીમે ધીમે|56|phrase
tyathi|ત્યાંથી|44
ahinthi|અહીંથી|40
paachal thi|પાછળથી|36|phrase

# Food
handvo|હાંડવો|48
khaman|ખમણ|52
ganthiya|ગાંઠિયા|48
sev|સેવ|40
muthiya|મુઠિયા|40
kothmir|કોથમીર|44
leembu|લીંબુ|48
ringan|રીંગણ|40
tuver|તુવેર|40
chana|ચણા|40
mag|મગ|36
udad|અડદ|36
bajri|બાજરી|44
juvar|જુવાર|36
lassi|લસ્સી|40
doodhpak|દૂધપાક|44
lapsi|લાપસી|40
kheer|ખીર|44
kansar|કંસાર|36
sukhdi|સુખડી|40
barfi|બરફી|36
peda|પેંડા|36
mesub|મેસુબ|36
ghughra|ઘુઘરા|36
chevdo|ચેવડો|40
farali|ફરાળ|36
sakkar|સક્કર|36
chini|ચીની|36
gol|ગોળ|40
puranpoli|પૂરણપોળી|40
daal dhokli|દાળ ઢોકળી|44|phrase

# Farm, trade, and office
khedut|ખેડૂત|52
khedoot|ખેડૂત|40
paak|પાક|40
beej|બીજ|44
khaatar|ખાતર|40
sinchai|સિંચાઈ|40
vero|વેરો|40
mahasul|મહેસૂલ|36
jamabandi|જમાબંધી|36
khaatu|ખાતું|44
bachat|બચત|44
udhaar|ઉધાર|40
vyaaj|વ્યાજ|40
taluko|તાલુકો|48
jillo|જિલ્લો|48
jilla|જિલ્લો|40
mukhya|મુખ્ય|44
sabhya|સભ્ય|40
adhyaksh|અધ્યક્ષ|44
mantri|મંત્રી|48
mukhyamantri|મુખ્યમંત્રી|44
vidhansabha|વિધાનસભા|40
loksabha|લોકસભા|36
chunav|ચૂંટણી|44
matdan|મતદાન|40
paripatra|પરિપત્ર|36
aadhaar|આધાર|36|loan
gram panchayat|ગ્રામ પંચાયત|44|phrase
vakeel|વકીલ|40
faislo|ફેંસલો|36
saja|સજા|40
dand|દંડ|36
kaid|કેદ|36
jel|જેલ|36|loan
dakhlo|દાખલો|36
pramanpatra|પ્રમાણપત્ર|40
aarogya|આરોગ્ય|44
davakhana|દવાખાનું|44
dava|દવા|48
ilaj|ઈલાજ|40
bukhar|બુખાર|40
udharas|ઉધરસ|36
aspatal|હોસ્પિટલ|36|loan
college|કોલેજ|40|loan
vishwavidyalay|વિશ્વવિદ્યાલય|36

# Faith, beside the words already shipped
katha|કથા|44|culture
satsang|સત્સંગ|44|culture
pravachan|પ્રવચન|36|culture
jap|જાપ|36|culture
tulsi|તુલસી|44|culture
divo|દીવો|44|culture
deep|દીપ|36|culture
agarbatti|અગરબત્તી|36|culture
naivedya|નૈવેદ્ય|36|culture
pavitra|પવિત્ર|40|culture
derasar|દેરાસર|40|culture
upashray|ઉપાશ્રય|36|culture
roja|રોજા|36|culture
namaz|નમાઝ|36|culture
azan|અઝાન|36|culture
ishwar|ઈશ્વર|48|culture
parmatma|પરમાત્મા|44|culture
brahma|બ્રહ્મા|40|culture
vishnu|વિષ્ણુ|44|culture
mahakali|મહાકાળી|36|culture
amba|અંબા|40|culture
meldi|મેલડી|36|culture
ramdev|રામદેવ|40|culture
jalaram|જલારામ|40|culture
swaminarayan|સ્વામિનારાયણ|48|culture
bhajan mandali|ભજન મંડળી|36|phrase

# Family
jeth|જેઠ|36
jethani|જેઠાણી|40
derani|દેરાણી|40
nanand|નણંદ|36
salo|સાળો|36
sali|સાળી|40
banevi|બનેવી|36
potra|પૌત્ર|36
potri|પૌત્રી|36

# Towns and talukas not already listed
adalaj|અડાલજ|40|place
mehmdavad|મહેમદાવાદ|40|place
petlad|પેટલાદ|44|place
borsad|બોરસદ|40|place
anklav|આંકલાવ|36|place
sojitra|સોજિત્રા|36|place
umreth|ઉમરેઠ|40|place
dakor|ડાકોર|48|place
kapadvanj|કપડવંજ|40|place
balasinor|બાલાસિનોર|36|place
santrampur|સંતરામપુર|36|place
devgadh baria|દેવગઢબારિયા|36|place
tankara|ટંકારા|36|place
jasdan|જસદણ|40|place
bhanvad|ભાણવડ|36|place
khambhalia|ખંભાળિયા|40|place
jamjodhpur|જામજોધપુર|36|place
kalavad|કાલાવડ|36|place
dhrol|ધ્રોલ|36|place
rajula|રાજુલા|40|place
jafrabad|જાફરાબાદ|36|place
savarkundla|સાવરકુંડલા|36|place
lathi|લાઠી|36|place
damanagar|દામનગર|36|place
bagasara|બગસરા|36|place
sutrapada|સુત્રાપાડા|36|place
talala|તાલાલા|40|place
chorwad|ચોરવાડ|36|place
manavadar|માણાવદર|36|place
keshod|કેશોદ|40|place
mendarda|મેંદરડા|36|place
vanthali|વંથલી|36|place
visavadar|વિસાવદર|36|place
bilkha|બિલખા|36|place
padadhari|પડધરી|36|place
maliya|માળિયા|36|place

# Tools, cloth, and the house
oodi|ઓઢી|36
chadar|ચાદર|40
takiyo|તકિયો|36
palang|પલંગ|40
khurshi|ખુરશી|40
mej|મેજ|36
bari|બારી|44
baranu|બારણું|40
talu|તાળું|40
chavi|ચાવી|44
deevasali|દીવાસળી|36
pankho|પંખો|44
tava|તવા|36
vatki|વાટકી|40
thali|થાળી|48
loto|લોટો|36
ghado|ઘડો|36
matlu|માટલું|40
kodali|કોદાળી|36
pavdo|પાવડો|36
datardu|દાતરડું|36
charkho|ચરખો|36
sadlo|સાડલો|36
chaniyo|ચણિયો|40
choli|ચોળી|36
kediyu|કેડિયું|40
paghdi|પાઘડી|36
mojdi|મોજડી|36
chappal|ચપ્પલ|40|loan
topi|ટોપી|36
rumaal|રૂમાલ|36
angarkhu|અંગરખું|36
''';
