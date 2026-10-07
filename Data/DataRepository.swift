import Foundation

class DataRepository {
    
    static let shared = DataRepository()
    
    // Vowels
    let vowels: [Letter] = [
        Letter(id: "v1", char: "അ", transliteration: "A", example: "അമ്മ", exampleEn: "Amma (Mother)", imageName: "v1", category: "vowel"),
        Letter(id: "v2", char: "ആ", transliteration: "AA", example: "ആന", exampleEn: "Aana (Elephant)", imageName: "v2", category: "vowel"),
        Letter(id: "v3", char: "ഇ", transliteration: "I", example: "ഇല", exampleEn: "Ila (Leaf)", imageName: "v3", category: "vowel"),
        Letter(id: "v4", char: "ഈ", transliteration: "EE", example: "ഈച്ച", exampleEn: "Eecha (Fly)", imageName: "v4", category: "vowel"),
        Letter(id: "v5", char: "ഉ", transliteration: "U", example: "ഉരൽ", exampleEn: "Ural (Mortar)", imageName: "v5", category: "vowel"),
        Letter(id: "v6", char: "ഊ", transliteration: "UU", example: "ഊഞ്ഞാൽ", exampleEn: "Oonjal (Swing)", imageName: "v6", category: "vowel"),
        Letter(id: "v7", char: "ഋ", transliteration: "R", example: "ഋഷി", exampleEn: "Rishi (Sage)", imageName: "v7", category: "vowel"),
        Letter(id: "v8", char: "എ", transliteration: "E", example: "എലി", exampleEn: "Eli (Rat)", imageName: "v8", category: "vowel"),
        Letter(id: "v9", char: "ഏ", transliteration: "EE", example: "ഏണി", exampleEn: "Eni (Ladder)", imageName: "v9", category: "vowel"),
        Letter(id: "v10", char: "ഐ", transliteration: "AI", example: "ഐസ്", exampleEn: "Ice", imageName: "v10", category: "vowel"),
        Letter(id: "v11", char: "ഒ", transliteration: "O", example: "ഒട്ടകം", exampleEn: "Ottakam (Camel)", imageName: "v11", category: "vowel"),
        Letter(id: "v12", char: "ഓ", transliteration: "OO", example: "ഓണം", exampleEn: "Onam", imageName: "v12", category: "vowel"),
        Letter(id: "v13", char: "ഔ", transliteration: "AU", example: "ഔഷധം", exampleEn: "Oushadham (Medicine)", imageName: "v13", category: "vowel")
    ]
    
    // Consonants
    let consonants: [Letter] = [
        Letter(id: "c1", char: "ക", transliteration: "Ka", example: "കത്രിക", exampleEn: "Kathrika (Scissors)", imageName: "c1", category: "consonant"),
        Letter(id: "c2", char: "ഖ", transliteration: "Kha", example: "ഖനി", exampleEn: "Khani (Mine)", imageName: "c2", category: "consonant"),
        Letter(id: "c3", char: "ഗ", transliteration: "Ga", example: "ഗജം", exampleEn: "Gajam (Elephant)", imageName: "c3", category: "consonant"),
        Letter(id: "c4", char: "ഘ", transliteration: "Gha", example: "ഘടികാരം", exampleEn: "Ghadikaram (Clock)", imageName: "c4", category: "consonant"),
        Letter(id: "c5", char: "ങ", transliteration: "Nga", example: "മാങ്ങ", exampleEn: "Maanga (Mango)", imageName: "c5", category: "consonant"),
        Letter(id: "c6", char: "ച", transliteration: "Cha", example: "ചക്ക", exampleEn: "Chakka (Jackfruit)", imageName: "c6", category: "consonant"),
        Letter(id: "c7", char: "ഛ", transliteration: "Chha", example: "ഛായ", exampleEn: "Chhaya (Shadow)", imageName: "c7", category: "consonant"),
        Letter(id: "c8", char: "ജ", transliteration: "Ja", example: "ജഗ്", exampleEn: "Jug", imageName: "c8", category: "consonant"),
        Letter(id: "c9", char: "ഝ", transliteration: "Jha", example: "ഝഷം", exampleEn: "Jhasham (Fish)", imageName: "c9", category: "consonant"),
        Letter(id: "c10", char: "ഞ", transliteration: "Nya", example: "ഞണ്ട്", exampleEn: "Njandu (Crab)", imageName: "c10", category: "consonant"),
        Letter(id: "c11", char: "ട", transliteration: "Ta", example: "ടയർ", exampleEn: "Tyre", imageName: "c11", category: "consonant"),
        Letter(id: "c12", char: "ഠ", transliteration: "Tha", example: "മിഠായി", exampleEn: "Mittaayi (Candy)", imageName: "c12", category: "consonant"),
        Letter(id: "c13", char: "ഡ", transliteration: "Da", example: "ഡമരു", exampleEn: "Damaru (Drum)", imageName: "c13", category: "consonant"),
        Letter(id: "c14", char: "ഢ", transliteration: "Dha", example: "ഢക്ക", exampleEn: "Dhakka (Large drum)", imageName: "c14", category: "consonant"),
        Letter(id: "c15", char: "ണ", transliteration: "Na", example: "വീണ", exampleEn: "Veena", imageName: "c15", category: "consonant"),
        Letter(id: "c16", char: "ത", transliteration: "Ta", example: "തവള", exampleEn: "Thavala (Frog)", imageName: "c16", category: "consonant"),
        Letter(id: "c17", char: "ഥ", transliteration: "Tha", example: "രഥം", exampleEn: "Ratham (Chariot)", imageName: "c17", category: "consonant"),
        Letter(id: "c18", char: "ദ", transliteration: "Da", example: "ദീപം", exampleEn: "Deepam (Lamp)", imageName: "c18", category: "consonant"),
        Letter(id: "c19", char: "ധ", transliteration: "Dha", example: "ധനു", exampleEn: "Dhanu (Bow)", imageName: "c19", category: "consonant"),
        Letter(id: "c20", char: "ന", transliteration: "Na", example: "നഖം", exampleEn: "Nakham (Nail)", imageName: "c20", category: "consonant"),
        Letter(id: "c21", char: "പ", transliteration: "Pa", example: "പന്ത്", exampleEn: "Panthu (Ball)", imageName: "c21", category: "consonant"),
        Letter(id: "c22", char: "ഫ", transliteration: "Pha", example: "ഫലം", exampleEn: "Phalam (Fruit)", imageName: "c22", category: "consonant"),
        Letter(id: "c23", char: "ബ", transliteration: "Ba", example: "ബസ്", exampleEn: "Bus", imageName: "c23", category: "consonant"),
        Letter(id: "c24", char: "ഭ", transliteration: "Bha", example: "ഭരണി", exampleEn: "Bharani (Jar)", imageName: "c24", category: "consonant"),
        Letter(id: "c25", char: "മ", transliteration: "Ma", example: "മരം", exampleEn: "Maram (Tree)", imageName: "c25", category: "consonant"),
        Letter(id: "c26", char: "യ", transliteration: "Ya", example: "യന്ത്രം", exampleEn: "Yanthram (Machine)", imageName: "c26", category: "consonant"),
        Letter(id: "c27", char: "ര", transliteration: "Ra", example: "രവി", exampleEn: "Ravi (Sun)", imageName: "c27", category: "consonant"),
        Letter(id: "c28", char: "ല", transliteration: "La", example: "ലത", exampleEn: "Latha (Creeper)", imageName: "c28", category: "consonant"),
        Letter(id: "c29", char: "വ", transliteration: "Va", example: "വണ്ടി", exampleEn: "Vandi (Vehicle)", imageName: "c29", category: "consonant"),
        Letter(id: "c30", char: "ശ", transliteration: "Sha", example: "ശംഖ്", exampleEn: "Shankh (Conch)", imageName: "c30", category: "consonant"),
        Letter(id: "c31", char: "ഷ", transliteration: "Sha", example: "ഷഡ്പദം", exampleEn: "Shadpadam (Beetle)", imageName: "c31", category: "consonant"),
        Letter(id: "c32", char: "സ", transliteration: "Sa", example: "സഞ്ചി", exampleEn: "Sanchi (Bag)", imageName: "c32", category: "consonant"),
        Letter(id: "c33", char: "ഹ", transliteration: "Ha", example: "ഹംസം", exampleEn: "Hamsam (Swan)", imageName: "c33", category: "consonant"),
        Letter(id: "c34", char: "ള", transliteration: "La", example: "വാള", exampleEn: "Vala (Sword)", imageName: "c34", category: "consonant"),
        Letter(id: "c35", char: "ഴ", transliteration: "Zha", example: "പഴം", exampleEn: "Pazham (Fruit)", imageName: "c35", category: "consonant"),
        Letter(id: "c36", char: "റ", transliteration: "Ra", example: "പറ", exampleEn: "Para (Vessel)", imageName: "c36", category: "consonant")
    ]
    
    // Stories — image names match Android drawable names
    let stories: [Story] = [
        Story(
            id: "s1", title: "ദാഹിച്ച കാക്ക", titleEn: "The Thirsty Crow",
            coverImageName: "thirsty_crow_cover",
            pages: [
                StoryPage(text: "കൊടുംവെയിലായിരുന്നു. ഒരു കാക്കയ്ക്ക് വളരെ ദാഹമായി. അത് വെള്ളം തേടി എല്ലായിടത്തും പറന്നു. ഒടുവിൽ ഒരു വീട്ടുമുറ്റത്ത് ഒരു കുടം കണ്ടു.", imageName: "thirsty_crow_1", highlight: nil),
                StoryPage(text: "കാക്ക കുടത്തിനരികിലെത്തി നോക്കിയപ്പോൾ അതിൽ കുറച്ച് വെള്ളം മാത്രമേ ഉണ്ടായിരുന്നുള്ളൂ. വെള്ളം വളരെ താഴെയായതിനാൽ അതിന് കൊക്ക് എത്തിക്കാൻ കഴിഞ്ഞില്ല.", imageName: "thirsty_crow_2", highlight: nil),
                StoryPage(text: "കാക്ക ചുറ്റും നോക്കി. അവിടെ കുറെ ചെറിയ കല്ലുകൾ കിടക്കുന്നത് കണ്ടു. അത് ഓരോ കല്ലും എടുത്ത് കുടത്തിലിട്ടു.", imageName: "thirsty_crow_3", highlight: nil),
                StoryPage(text: "കുറച്ച് നേരം കഴിഞ്ഞപ്പോൾ വെള്ളം മുകളിലേക്ക് ഉയർന്നു. കാക്കയ്ക്ക് വെള്ളം കുടിക്കാൻ സാധിച്ചു.", imageName: "thirsty_crow_4", highlight: nil),
                StoryPage(text: "ദാഹം മാറിയ കാക്ക സന്തോഷത്തോടെ പറന്നുപോയി.", imageName: "thirsty_crow_5", highlight: nil),
                StoryPage(text: "പാഠം: ബുദ്ധിയും ക്ഷമയും ഉണ്ടെങ്കിൽ ഏത് പ്രശ്നത്തിനും പരിഹാരം കണ്ടെത്താം.", imageName: "thirsty_crow_6", highlight: nil)
            ]
        ),
        Story(
            id: "s2", title: "ഉറുമ്പും പ്രാവും", titleEn: "The Ant and the Dove",
            coverImageName: "ant_dove_cover",
            pages: [
                StoryPage(text: "ഒരു ദിവസം ഒരു ഉറുമ്പ് വെള്ളം കുടിക്കാൻ നദിക്കരയിൽ എത്തി. അബദ്ധത്തിൽ അത് വെള്ളത്തിൽ വീണു. ശക്തമായ ഒഴുക്കിൽ ഉറുമ്പ് ഒഴുകിപ്പോകാൻ തുടങ്ങി.", imageName: "ant_dove_1", highlight: nil),
                StoryPage(text: "അടുത്തുള്ള മരത്തിൽ ഇരുന്നിരുന്ന ഒരു പ്രാവ് ഇത് കണ്ടു. അത് ഉടൻ ഒരു ഇല പറിച്ചെടുത്ത് വെള്ളത്തിലിട്ടു.", imageName: "ant_dove_2", highlight: nil),
                StoryPage(text: "ഉറുമ്പ് ആ ഇലയിലേക്ക് കയറി സുരക്ഷിതമായി കരയിലെത്തി. അത് പ്രാവിന് നന്ദി പറഞ്ഞു.", imageName: "ant_dove_3", highlight: nil),
                StoryPage(text: "കുറച്ച് ദിവസങ്ങൾക്ക് ശേഷം ഒരു വേട്ടക്കാരൻ പ്രാവിനെ ലക്ഷ്യമാക്കി അമ്പെയ്യാൻ ഒരുങ്ങി. ഇത് കണ്ട ഉറുമ്പ് വേട്ടക്കാരന്റെ കാലിൽ കടിച്ചു.", imageName: "ant_dove_4", highlight: nil),
                StoryPage(text: "വേദനകൊണ്ട് വേട്ടക്കാരന്റെ ലക്ഷ്യം തെറ്റി. പ്രാവ് അപകടത്തിൽ നിന്ന് രക്ഷപ്പെട്ടു.", imageName: "ant_dove_5", highlight: nil),
                StoryPage(text: "പാഠം: നല്ലത് ചെയ്താൽ നല്ലത് തിരിച്ചുകിട്ടും.", imageName: "ant_dove_6", highlight: nil)
            ]
        ),
        Story(
            id: "s3", title: "മുയലും ആമയും", titleEn: "The Tortoise and the Hare",
            coverImageName: "hare_tortoise_cover",
            pages: [
                StoryPage(text: "ഒരിക്കൽ ഒരു കാട്ടിൽ ഒരു മുയലും ഒരു ആമയും താമസിച്ചിരുന്നു. മുയൽ വളരെ വേഗത്തിൽ ഓടുമായിരുന്നു. അതുകൊണ്ട് തന്നെ അത് എപ്പോഴും ആമയെ കളിയാക്കുമായിരുന്നു.", imageName: "hare_tortoise_1", highlight: nil),
                StoryPage(text: "\"നീ ഇത്ര പതുക്കെയാണോ നടക്കുന്നത്? എനിക്ക് ഒരു മിനിറ്റിൽ പോകാവുന്ന ദൂരം പോകാൻ നിനക്ക് ഒരു ദിവസം വേണം!\" മുയൽ ചിരിച്ചു പറഞ്ഞു.", imageName: "hare_tortoise_2", highlight: nil),
                StoryPage(text: "ആമ ശാന്തമായി മറുപടി പറഞ്ഞു: \"വേഗം മാത്രം പോരാ. സ്ഥിരതയും പ്രധാനമാണ്.\"", imageName: "hare_tortoise_3", highlight: nil),
                StoryPage(text: "ഇത് കേട്ട മുയൽ ചിരിച്ചു. ഒടുവിൽ ഇരുവരും ഒരു ഓട്ടമത്സരം നടത്താൻ തീരുമാനിച്ചു.", imageName: "hare_tortoise_4", highlight: nil),
                StoryPage(text: "മത്സരം തുടങ്ങി. മുയൽ അതിവേഗം മുന്നിലെത്തി. \"ഇനി കുറച്ച് നേരം ഉറങ്ങിയാലും ഞാൻ ജയിക്കും,\" എന്ന് വിചാരിച്ച് മുയൽ ഒരു മരച്ചുവട്ടിൽ കിടന്ന് ഉറങ്ങി.", imageName: "hare_tortoise_5", highlight: nil),
                StoryPage(text: "ആമ പതുക്കെയെങ്കിലും നിർത്താതെ മുന്നോട്ട് നടന്നു. സമയം കടന്നുപോയി. ആമ ലക്ഷ്യത്തിനടുത്തെത്തി.", imageName: "hare_tortoise_6", highlight: nil),
                StoryPage(text: "ഉറക്കമുണർന്ന മുയൽ വേഗത്തിൽ ഓടി. പക്ഷേ അതിന് മുമ്പേ ആമ ലക്ഷ്യരേഖ കടന്നിരുന്നു.", imageName: "hare_tortoise_7", highlight: nil),
                StoryPage(text: "കാട്ടിലെ എല്ലാ മൃഗങ്ങളും ആമയെ അഭിനന്ദിച്ചു. മുയലിന് തന്റെ അഹങ്കാരത്തിന്റെ തെറ്റ് മനസ്സിലായി.", imageName: "hare_tortoise_8", highlight: nil),
                StoryPage(text: "പാഠം: സ്ഥിരതയും കഠിനാധ്വാനവും വിജയത്തിലേക്കുള്ള വഴിയാണ്.", imageName: "hare_tortoise_9", highlight: nil)
            ]
        ),
        Story(
            id: "s4", title: "സിംഹവും എലിയും", titleEn: "The Lion and the Mouse",
            coverImageName: "lion_mouse_cover",
            pages: [
                StoryPage(text: "ഒരു ദിവസം ഒരു സിംഹം കാട്ടിലെ വലിയ മരത്തിന്റെ ചുവട്ടിൽ ഉറങ്ങുകയായിരുന്നു. അപ്പോൾ ഒരു ചെറിയ എലി കളിച്ചുകൊണ്ട് അവിടെയെത്തി. അറിയാതെ അത് സിംഹത്തിന്റെ മേൽ കയറി ഓടി.", imageName: "lion_mouse_1", highlight: nil),
                StoryPage(text: "സിംഹം പെട്ടെന്ന് ഉണർന്നു. അതിന് ദേഷ്യം വന്നു. അത് എലിയെ തന്റെ വലിയ കൈയിൽ പിടിച്ചു.", imageName: "lion_mouse_2", highlight: nil),
                StoryPage(text: "\"എന്നെ എന്തിന് ശല്യപ്പെടുത്തി?\" സിംഹം ഗർജിച്ചു.", imageName: "lion_mouse_3", highlight: nil),
                StoryPage(text: "എലി പേടിച്ച് വിറച്ചു. \"രാജാവേ, ദയവായി എന്നെ വിട്ടയക്കൂ. ഒരിക്കൽ എനിക്കും നിങ്ങളെ സഹായിക്കാൻ കഴിയും,\" എന്ന് അത് അപേക്ഷിച്ചു.", imageName: "lion_mouse_4", highlight: nil),
                StoryPage(text: "ഇത് കേട്ട് സിംഹം ചിരിച്ചു.", imageName: "lion_mouse_5", highlight: nil),
                StoryPage(text: "\"നീ എന്നെ സഹായിക്കുമോ? ഇത്ര ചെറിയ നീ?\" എന്നെങ്കിലും സിംഹത്തിന് എലിയോട് കരുണ തോന്നി. അത് എലിയെ വിട്ടയച്ചു.", imageName: "lion_mouse_6", highlight: nil),
                StoryPage(text: "കുറച്ച് ദിവസങ്ങൾക്കുശേഷം, വേട്ടക്കാർ കാട്ടിൽ വല വിരിച്ചു. അറിയാതെ സിംഹം അതിൽ കുടുങ്ങി. എത്ര ശ്രമിച്ചിട്ടും രക്ഷപ്പെടാൻ കഴിഞ്ഞില്ല.", imageName: "lion_mouse_7", highlight: nil),
                StoryPage(text: "സിംഹത്തിന്റെ കരച്ചിൽ കേട്ട് എലി ഓടിയെത്തി. അത് വലയുടെ കയറുകൾ മൂർച്ചയുള്ള പല്ലുകൾ കൊണ്ട് കടിച്ചു മുറിക്കാൻ തുടങ്ങി.", imageName: "lion_mouse_8", highlight: nil),
                StoryPage(text: "കുറച്ച് നേരം കഴിഞ്ഞപ്പോൾ വല പൊട്ടി. സിംഹം സ്വതന്ത്രനായി.", imageName: "lion_mouse_9", highlight: nil),
                StoryPage(text: "\"നന്ദി, സുഹൃത്തേ,\" സിംഹം പറഞ്ഞു. \"ചെറിയവരെയും ഒരിക്കലും വിലകുറച്ച് കാണരുതെന്ന് ഇന്ന് ഞാൻ പഠിച്ചു.\"", imageName: "lion_mouse_10", highlight: nil),
                StoryPage(text: "എലി സന്തോഷത്തോടെ ചിരിച്ചു.", imageName: "lion_mouse_11", highlight: nil),
                StoryPage(text: "പാഠം: വലിപ്പമല്ല പ്രധാനം, നല്ല മനസ്സും സഹായിക്കാനുള്ള മനോഭാവവുമാണ് ഏറ്റവും വലിയ ശക്തി.", imageName: "lion_mouse_12", highlight: nil)
            ]
        ),
        Story(
            id: "s5", title: "രണ്ട് ആടുകൾ", titleEn: "The Two Goats",
            coverImageName: "two_goats_cover",
            pages: [
                StoryPage(text: "ഒരു ചെറിയ പാലത്തിന്റെ ഇരുവശങ്ങളിൽ നിന്ന് രണ്ട് ആടുകൾ നടന്നു വന്നു. പാലം വളരെ ഇടുങ്ങിയതായിരുന്നു. ഒരേസമയം ഒരാൾക്ക് മാത്രമേ കടക്കാൻ കഴിയൂ.", imageName: "two_goats_1", highlight: nil),
                StoryPage(text: "ആദ്യ ആട് പറഞ്ഞു, \"ഞാനാണ് ആദ്യം പോകേണ്ടത്!\"", imageName: "two_goats_2", highlight: nil),
                StoryPage(text: "രണ്ടാമത്തെ ആടും വിട്ടുകൊടുക്കാൻ തയ്യാറായില്ല.", imageName: "two_goats_3", highlight: nil),
                StoryPage(text: "ഇരുവരും തമ്മിൽ തള്ളിത്തുടങ്ങി. അപ്പോൾ ബാലൻസ് തെറ്റി രണ്ടുപേരും നദിയിലേക്ക് വീണു.", imageName: "two_goats_4", highlight: nil),
                StoryPage(text: "കുറച്ച് ദിവസങ്ങൾക്ക് ശേഷം മറ്റൊരു രണ്ട് ആടുകൾ അതേ പാലത്തിൽ എത്തി. അവരിൽ ഒരാൾ താഴെ കിടന്നു. മറ്റേ ആട് അതിന്റെ മുകളിലൂടെ പതുക്കെ കടന്നു.", imageName: "two_goats_5", highlight: nil),
                StoryPage(text: "പിന്നീട് കിടന്ന ആടും എഴുന്നേറ്റ് പാലം കടന്നു.", imageName: "two_goats_6", highlight: nil),
                StoryPage(text: "ഇരുവരും സുരക്ഷിതമായി മറുകരയിലെത്തി.", imageName: "two_goats_7", highlight: nil),
                StoryPage(text: "പാഠം: സഹകരണവും പരസ്പര ബഹുമാനവും വിജയത്തിലേക്കുള്ള വഴി തുറക്കും.", imageName: "two_goats_8", highlight: nil)
            ]
        )
    ]
    
    func getMascotAppu() -> String {
        return "mascot_appu"
    }
}
