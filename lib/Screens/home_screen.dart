import 'package:divine_arc/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:divine_arc/Screens/chalisa_screen.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/common_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String quoteResponse = '';
  bool isPrayersLoading = false;
  List<dynamic> allPrayers = [
    {
      "title_hi": "हनुमान चालीसा",
      "title_en": "Hanuman Chalisa",
      "prayer_hi":
          "दोहा\nश्रीगुरु चरन सरोज रज, निज मनु मुकुरु सुधारि।\nबरनऊं रघुबर बिमल जसु, जो दायकु फल चारि॥\nबुद्धिहीन तनु जानिके, सुमिरौं पवनकुमार।\nबल बुद्धि विद्या देहु मोहिं, हरहु कलेस बिकार॥\n\nचौपाई\nजय हनुमान ज्ञान गुन सागर।\nजय कपीस तिहुं लोक उजागर॥\nराम दूत अतुलित बल धामा।\nअंजनि-पुत्र पवनसुत नामा॥\n\nमहाबीर बिक्रम बजरंगी।\nकुमति निवार सुमति के संगी॥\nकंचन बरन बिराज सुबेसा।\nकानन कुण्डल कुँचित केसा॥\n\nहाथ बज्र औ ध्वजा बिराजे।\nकांधे मूंज जनेउ साजे॥\nशंकर सुवन केसरी नंदन।\nतेज प्रताप महा जग वंदन॥\n\nबिद्यावान गुनी अति चातुर।\nराम काज करिबे को आतुर॥\nप्रभु चरित्र सुनिबे को रसिया।\nराम लखन सीता मन बसिया॥\n\nसूक्ष्म रूप धरि सियहिं दिखावा।\nबिकट रूप धरि लंक जरावा॥\nभीम रूप धरि असुर संहारे।\nरामचन्द्र के काज संवारे॥\n\nलाय सजीवन लखन जियाये।\nश्री रघुबीर हरषि उर लाये॥\nरघुपति कीन्ही बहुत बड़ाई।\nतुम मम प्रिय भरतहि सम भाई॥\n\nसहस बदन तुम्हरो जस गावैं।\nअस कहि श्रीपति कण्ठ लगावैं॥\nसनकादिक ब्रह्मादि मुनीसा।\nनारद सारद सहित अहीसा॥\n\nजम कुबेर दिगपाल जहां ते।\nकबि कोबिद कहि सके कहां ते॥\nतुम उपकार सुग्रीवहिं कीन्हा।\nराम मिलाय राज पद दीन्हा॥\n\nतुम्हरो मंत्र बिभीषन माना।\nलंकेश्वर भए सब जग जाना॥\nजुग सहस्र जोजन पर भानु।\nलील्यो ताहि मधुर फल जानू॥\n\nप्रभु मुद्रिका मेलि मुख माहीं।\nजलधि लांघि गये अचरज नाहीं॥\nदुर्गम काज जगत के जेते।\nसुगम अनुग्रह तुम्हरे तेते॥\n\nराम दुआरे तुम रखवारे।\nहोत न आज्ञा बिनु पैसारे॥\nसब सुख लहै तुम्हारी सरना।\nतुम रच्छक काहू को डर ना॥\n\nआपन तेज सम्हारो आपै।\nतीनों लोक हांक तें कांपै॥\nभूत पिसाच निकट नहिं आवै।\nमहाबीर जब नाम सुनावै॥\n\nनासै रोग हरे सब पीरा।\nजपत निरन्तर हनुमत बीरा॥\nसंकट तें हनुमान छुड़ावै।\nमन क्रम बचन ध्यान जो लावै॥\n\nसब पर राम तपस्वी राजा।\nतिन के काज सकल तुम साजा॥\nऔर मनोरथ जो कोई लावै।\nसोई अमित जीवन फल पावै॥\n\nचारों जुग परताप तुम्हारा।\nहै परसिद्ध जगत उजियारा॥\nसाधु संत के तुम रखवारे।\nअसुर निकन्दन राम दुलारे॥\n\nअष्टसिद्धि नौ निधि के दाता।\nअस बर दीन जानकी माता॥\nराम रसायन तुम्हरे पासा।\nसदा रहो रघुपति के दासा॥\n\nतुह्मरे भजन राम को पावै।\nजनम जनम के दुख बिसरावै॥\nअंत काल रघुबीर पुर जाई।\nजहां जन्म हरिभक्त कहाई॥\n\nऔर देवता चित्त न धरई।\nहनुमत सेइ सर्ब सुख करई॥\nसङ्कट कटै मिटै सब पीरा।\nजो सुमिरै हनुमत बलबीरा॥\n\nजय जय जय हनुमान गोसाईं।\nकृपा करहु गुरुदेव की नाईं॥\nजो सत बार पाठ कर कोई।\nछूटहि बन्दि महा सुख होई॥\n\nजो यह पढ़ै हनुमान चालीसा।\nहोय सिद्धि साखी गौरीसा॥\nतुलसीदास सदा हरि चेरा।\nकीजै नाथ हृदय महं डेरा॥\n\nदोहा\nपवनतनय संकट हरन, मंगल मूरति रूप।\nराम लखन सीता सहित, हृदय बसहु सुर भूप॥",
      "prayer_en":
          "Doha\nWith the dust of the Guru's lotus feet, I clean the mirror of my mind.\nI narrate the pure glory of Shri Raghuvar, which bestows the four fruits.\nKnowing myself to be ignorant, I remember Hanuman, son of the Wind.\nGrant me strength, wisdom, and knowledge, and remove my afflictions and impurities.\n\nChaupai\nVictory to Hanuman, ocean of wisdom and virtue.\nVictory to the Lord of Monkeys, who illuminates the three worlds.\nMessenger of Ram, abode of unmatched strength.\nSon of Anjani, known as Pavanputra.\n\nGreat hero, mighty as the thunderbolt.\nDispeller of evil thoughts, companion of good sense.\nGolden-hued, adorned with beautiful attire.\nWearing earrings and curly hair.\n\nHolding a thunderbolt and flag in hand.\nSacred thread of munja grass adorns your shoulder.\nSon of Shankar, delight of Kesari.\nYour glory and might are revered by the world.\n\nLearned, virtuous, and exceedingly clever.\nEager to perform tasks for Ram.\nYou delight in listening to the Lord’s glories.\nRam, Lakshman, and Sita reside in your heart.\n\nIn subtle form, you appeared before Sita.\nIn fierce form, you burned Lanka.\nIn gigantic form, you destroyed demons.\nYou accomplished the tasks of Shri Ramchandra.\n\nYou brought the Sanjivani to revive Lakshman.\nShri Raghuvir joyfully embraced you.\nRaghupati praised you greatly,\nSaying, 'You are as dear to me as my brother Bharat.'\n\nThousands sing your glory.\nSaying so, Shri Ram embraced you.\nSages like Sanaka, Brahma, and others,\nNarad, Sharada, and Ahisha sing your praise.\n\nYama, Kubera, and the guardians of directions,\nPoets and scholars cannot fully describe you.\nYou rendered great help to Sugriva.\nYou united him with Ram, granting him kingship.\n\nVibhishana accepted your counsel,\nAnd became the king of Lanka, known to all.\nYou swallowed the sun, thousands of miles away,\nThinking it to be a sweet fruit.\n\nWith the Lord’s ring in your mouth,\nYou crossed the ocean, no surprise in that.\nAll difficult tasks in the world,\nBecome easy by your grace.\n\nYou are the guardian at Ram’s door.\nNo one enters without your permission.\nAll joys are found in your shelter.\nWith you as protector, there is no fear.\n\nYou alone can control your splendor.\nThe three worlds tremble at your roar.\nGhosts and spirits dare not come near,\nWhen the name of Mahavir is chanted.\n\nAll diseases and pains are destroyed,\nBy constantly chanting the name of brave Hanuman.\nHanuman frees from difficulties,\nThose who meditate on him with thought, word, and deed.\n\nRam, the ascetic king, reigns over all.\nYou accomplish all his tasks.\nWhoever brings their wishes to you,\nThey attain boundless fruits of life.\n\nYour glory shines through the four ages.\nYour fame illuminates the world.\nYou are the protector of saints and sages,\nThe destroyer of demons, beloved of Ram.\n\nYou grant the eight siddhis and nine nidhis,\nAs blessed by Mother Janaki.\nYou hold the elixir of Ram’s name,\nForever remaining the servant of Raghupati.\n\nBy chanting your name, one reaches Ram.\nThe sorrows of many births are forgotten.\nAt the end, one goes to Raghupati’s abode,\nBorn as a devotee of Hari.\n\nOther gods may not be heeded,\nBut serving Hanuman brings all happiness.\nAll troubles vanish, all pains disappear,\nFor those who remember the mighty Hanuman.\n\nVictory, victory, victory to Lord Hanuman.\nBestow your grace like a Guru.\nWhoever recites this a hundred times,\nIs freed from bondage and attains great joy.\n\nWhoever reads the Hanuman Chalisa,\nAttains perfection, as witnessed by Lord Shiva.\nTulsidas, ever the servant of Hari,\nPrays, 'O Lord, reside in my heart.'\n\nDoha\nSon of the Wind, remover of troubles, embodiment of auspiciousness.\nWith Ram, Lakshman, and Sita, reside in my heart, O King of Gods.",
      "description_hi":
          "श्री हनुमान जी को समर्पित तुलसीदास रचित भक्ति भजन, जो भक्ति, शक्ति और सुरक्षा का प्रतीक है।",
      "description_en":
          "A devotional hymn dedicated to Lord Hanuman, composed by Tulsidas, symbolizing devotion, strength, and protection.",
      "image_url":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRr2az5eDfxbeLjgN7KGpO_FBLDRzUIdx5NtQ&s",
    },
    {
      "title_hi": "दुर्गा माता की आरती",
      "title_en": "Durga Mata Aarti",
      "prayer_hi":
          "जय अंबे गौरी, मैया जय श्यामा गौरी।\nतुमको निशिदिन ध्यावत, हरि ब्रह्मा शिवरी॥ ओम जय अंबे गौरी\n\nमांग सिन्दूर विराजत, टीको मृगमद को।\nउज्जवल से दो‌उ नैना, चन्द्रवदन नीको॥ ओम जय अंबे गौरी\n\nकनक समान कलेवर, रक्ताम्बर राजै।\nरक्तपुष्प गल माला, कण्ठन पर साजै॥ ओम जय अंबे गौरी\n\nकेहरि वाहन राजत, खड्ग खप्परधारी।\nसुर-नर-मुनि-जन सेवत, तिनके दुखहारी॥ ओम जय अंबे गौरी\n\nकानन कुण्डल शोभित, नासाग्रे मोती।\nकोटिक चन्द्र दिवाकर, सम राजत ज्योति॥ ओम जय अंबे गौरी\n\nशुम्भ-निशुम्भ बिदारे, महिषासुर घाती।\nधूम्र विलोचन नैना, निशिदिन मदमाती॥ ओम जय अंबे गौरी\n\nचण्ड-मुण्ड संहारे, शोणित बीज हरे।\nमधु-कैटभ दो‌उ मारे, सुर भयहीन करे॥ ओम जय अंबे गौरी\n\nब्रहमाणी रुद्राणी तुम कमला रानी।\nआगम-निगम-बखानी, तुम शिव पटरानी॥ ओम जय अंबे गौरी\n\nचौंसठ योगिनी मंगल गावत, नृत्य करत भैरूं।\nबाजत ताल मृदंगा, अरु बाजत डमरु॥ ओम जय अंबे गौरी\n\nतुम ही जग की माता, तुम ही हो भरता।\nभक्‍तन की दु:ख हरता, सुख सम्पत्ति करता॥ ओम जय अंबे गौरी\n\nभुजा चार अति शोभित, वर-मुद्रा धारी।\nमनवान्छित फल पावत, सेवत नर-नारी॥ ओम जय अंबे गौरी\n\nकंचन थाल विराजत, अगर कपूर बाती।\nश्रीमालकेतु में राजत, कोटि रतन ज्योति॥ ओम जय अंबे गौरी\n\nश्री अम्बेजी की आरती, जो को‌ई नर गावै।\nकहत शिवानन्द स्वामी, सुख सम्पत्ति पावै॥ ओम जय अंबे गौरी\n\nजोर से बोलो जय माता दी, सारे बोले जय माता दी।\nबोल सांचे दरबार की जय, जयकारा शेरावाली का बोल सांचे दरबार की जय",
      "prayer_en":
          "Victory to Mother Ambe, victory to Shyama Gauri.\nYou are meditated upon day and night by Hari, Brahma, and Shiva. Om Jai Ambe Gauri.\n\nVermilion adorns your forehead, with a mark of musk.\nYour radiant eyes and moon-like face are beautiful. Om Jai Ambe Gauri.\n\nYour body shines like gold, draped in red attire.\nA garland of red flowers adorns your neck. Om Jai Ambe Gauri.\n\nRiding a lion, holding a sword and skull,\nGods, humans, and sages serve you, remover of their sorrows. Om Jai Ambe Gauri.\n\nEarrings shine, with a pearl on your nose.\nYour radiance equals millions of moons and suns. Om Jai Ambe Gauri.\n\nYou destroyed Shumbha-Nishumbha and Mahishasura.\nYour smoky eyes are ever enchanting. Om Jai Ambe Gauri.\n\nYou vanquished Chanda-Munda and Shonit Beej.\nYou slew Madhu-Kaitabha, making gods fearless. Om Jai Ambe Gauri.\n\nYou are Brahmani, Rudrani, and Kamala Rani.\nScriptures proclaim you as Shiva’s queen. Om Jai Ambe Gauri.\n\nSixty-four yoginis sing your praises, Bhairav dances.\nDrums and damaru resound in your glory. Om Jai Ambe Gauri.\n\nYou are the mother and sustainer of the world.\nYou remove devotees’ sorrows and grant joy and prosperity. Om Jai Ambe Gauri.\n\nYour four arms shine, holding the gesture of boons.\nMen and women who serve you gain their desired fruits. Om Jai Ambe Gauri.\n\nA golden plate with incense and camphor glows.\nIn Shree Malketu, your light equals millions of gems. Om Jai Ambe Gauri.\n\nWhoever sings the Aarti of Ambeji,\nAs Shivanand Swami says, gains happiness and prosperity. Om Jai Ambe Gauri.\n\nLoudly proclaim, Victory to the Mother!\nAll say, Victory to the Mother! Hail the true court of the lion-riding Goddess!",
      "description_hi":
          "माँ दुर्गा की स्तुति में गाया जाने वाला पावन भजन, जो शक्ति, साहस और देवी माँ के आशीर्वाद का प्रतीक है।",
      "description_en":
          "A sacred hymn sung in praise of Mother Durga, symbolizing strength, courage, and the blessings of the Goddess.",
      "image_url":
          "https://t4.ftcdn.net/jpg/09/75/63/59/360_F_975635990_6M7X8OwBuHtxmZiti6Rqy4gjyC8uMqid.jpg",
    },
    {
      "title_hi": "शिव तांडव स्तोत्रम",
      "title_en": "Shiva Tandava Stotram",
      "prayer_hi":
          "जटाटवीगलज्जलप्रवाहपावितस्थले\nगलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम्।\nडमड्डमड्डमड्डमन्निनादवड्डमर्वयं\nचकार चण्डताण्डवं तनोतु नः शिवः शिवम्॥१॥\n\nजटाकटाहसंभ्रमभ्रमन्निलिम्पनिर्झरी\nविलोलवीचिवल्लरीविराजमानमूर्धनि।\nधगद्धगद्धगज्ज्वलल्ललाटपट्टपावके\nकिशोरचन्द्रशेखरे रतिः प्रतिक्षणं मम॥२॥\n\nधराधरेन्द्रनंदिनीविलासबन्धुबन्धुर\nस्फुरद्दिगन्तसन्तति प्रभोत्तमप्रदीप्तकम्।\nबुधाबुधाविनाशिनीं महायोगिनीं नमामि ताम्\nनमामि तं विनोदिनीं नमामि तं च ताण्डवम्॥३॥\n\nजटाभुजङ्गपिङ्गलस्फुरत्फणामणिप्रभा\nकदम्बकुङ्कुमद्रवप्रलिप्तदिग्वधूमुखे।\nमदान्धसिन्धुरस्फुरत्त्वगुत्तरीयमेदुरे\nमनो विनोदमद्भुतं बिभर्तु भूतभर्तरि॥४॥\n\nसहस्रलोचनप्रभृत्यशेषलेखशेखर\nप्रसूनधूलिधोरणी विधूसराङ्घ्रिपीठभूः।\nभुजङ्गराजमालया निबद्धजाटजूटकः\nश्रियै चिराय जायते चकार चण्डताण्डवम्॥५॥\n\nस्पृषद्विचित्रतन्तुं तनुरुहैर्विलासिनीं\nविलोललोललोचनं ललामभाललग्नकम्।\nकपालभालपावकं धगद्धगद्धगज्ज्वलं\nमहाकपालिनीं नमामि तं च ताण्डवम्॥६॥\n\nकरालभालपट्टिकाधगद्धगद्धगज्ज्वल\nद्धनञ्जयाहुतीकृतप्रचण्डपञ्चसायकम्।\nनमामि तं नमामि तं नमामि तं च ताण्डवम्\nनमामि तं नमामि तं नमामि तं च ताण्डवम्॥७॥\n\nनवीनमेघमण्डली निरुद्धदुर्धरस्फुरत्\nकुहूर्निशीथिनीतमः प्रबन्धबन्धकन्धरः।\nनिलिम्पनिर्झरीधरस्तनोतु कृत्तिसिन्धुरः\nकलानिधानबन्धुरः श्रियं जगद्धुरंधरः॥८॥\n\nप्रफुल्लनीलपङ्कजप्रपञ्चकालिमच्छटा\nविलोललोचनं कटि प्रभासति त्रिलोचनम्।\nललाटचत्वरज्वलद्धनञ्जयस्फुरत्प्रभा\nप्रभासति त्रिलोचनं नमामि तं च ताण्डवम्॥९॥\n\nसुधामयूखलेखया विराजमानशेखरं\nमहाकपालिसम्पदे शिरोजटालमस्तु नः।\nकरालभालपट्टिकाधगद्धगद्धगज्ज्वलं\nमहाकपालिनीं नमामि तं च ताण्डवम्॥१०॥\n\nइमं हि नित्यमेवमुक्तमुत्तमं स्तवं\nपठन्स्मरन्ब्रुवन्नरो विशुद्धिमेति सन्ततम्।\nहरे गुरौ सुभक्तिमाशु याति नान्यथा गतिं\nविमोहनं हि देहिनां सुशङ्करस्य चिन्तनम्॥११॥\n\nपूजावसानसमये दशवक्त्रगीतं\nयः शम्भुपूजनपरं पठति प्रदोषे।\nतस्य स्थिरां रथगजेन्द्रतुरङ्गयुक्तां\nलक्ष्मीं सदैव सुमुखीं प्रददाति शम्भुः॥१२॥",
      "prayer_en":
          "With matted locks dripping sacred water, purifying the ground,\nA lofty serpent garland hangs around his neck.\nWith the sound of damaru—damad-damad-damad—\nShiva performs the fierce Tandava; may he grant us auspiciousness.\n\nHis matted hair, a whirl of the celestial river’s waves,\nAdorns his head like a flowing vine.\nThe blazing fire on his forehead shines,\nMy heart delights in the moon-crowned Shiva every moment.\n\nThe playful friend of Parvati, daughter of the mountain king,\nHis radiant splendor spreads across the universe.\nI bow to the destroyer of ignorance, the great yogini,\nI bow to her, the delightful one, and her Tandava.\n\nHis matted locks shine with the serpent’s gem-like glow,\nSmeared with saffron and kumkum, radiant in all directions.\nHis skin, adorned with a flowing garment, sparkles,\nThe Lord of beings holds my mind in wondrous delight.\n\nCrowned with Indra and endless divine forms,\nHis feet, dusted with flower pollen, touch the earth.\nSerpent king entwined in his matted locks,\nHe performs the fierce Tandava for eternal prosperity.\n\nHis body adorned with intricate patterns, charming,\nHis playful eyes and forehead marked with splendor.\nThe fire on his skull blazes—dhagad-dhagad—\nI bow to the great Kapalini and her Tandava.\n\nHis fierce forehead blazes with fire—dhagad-dhagad—\nOffering the five arrows to the blazing fire.\nI bow to him, I bow to him, I bow to his Tandava,\nI bow to him, I bow to him, I bow to his Tandava.\n\nAmid clouds restraining the fierce storm,\nHis neck, dark as midnight, holds the celestial river.\nHe bears the moon and wears a deer skin,\nThe bearer of the world grants prosperity.\n\nHis radiant third eye shines like a blooming blue lotus,\nHis waist glows, the three-eyed one dazzles.\nThe fire on his forehead blazes with splendor,\nI bow to the three-eyed one and his Tandava.\n\nCrowned with moonbeams, radiant with glory,\nMay his matted locks, rich with Kapali’s wealth, bless us.\nHis fierce forehead blazes—dhagad-dhagad—\nI bow to the great Kapalini and her Tandava.\n\nWhoever recites this supreme hymn daily,\nMeditating and chanting, attains constant purity.\nIn devotion to the Guru, one finds no other path,\nThe thought of auspicious Shiva liberates souls.\n\nAt the end of worship, chanting this hymn of Ravana,\nRecited at dusk in devotion to Shambhu,\nGrants lasting wealth—chariots, elephants, and horses—\nShiva bestows eternal prosperity and grace.",
      "description_hi":
          "रावण रचित यह स्तोत्र भगवान शिव के तांडव नृत्य की महिमा का वर्णन करता है, जो शक्ति और आध्यात्मिक ऊर्जा का प्रतीक है।",
      "description_en":
          "Composed by Ravana, this hymn describes the glory of Lord Shiva’s Tandava dance, symbolizing power and spiritual energy.",
      "image_url":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPMeO-wt9Omcum7oYO55hDW4rfZlU-XfW79GmpUQEisa4FRQ4IWaQINDiJtZCbNhOiRlw&usqp=CAU",
    },
    {
      "title_hi": "साईं अमृतवाणी",
      "title_en": "Sai Amritvani",
      "prayer_hi":
          "श्री साईं नाथाय नमः\nसाईं बाबा के दरबार में, सबको मिलता है प्यार।\nभक्तों की पुकार सुनते, साईं हैं दयालु अपार॥\n\nसाईं बाबा, साईं बाबा, तुम हो दीनदयाल।\nसच्चिदानंद स्वरूप तुम, भक्तों के रखवाल॥\n\nशिर्डी में बिराजे साईं, द्वारकामाई में ध्यान।\nसबके दुख हर लेते हैं, साईं का है बलवान॥\n\nॐ साईं, श्री साईं, जय जय साईं नाथ।\nभक्तों के हृदय में बस्ते, साईं प्रभु की बात॥\n\nसबका मालिक एक है, साईं का है संदेश।\nहिंदू-मुस्लिम एक करे, प्रेम का है विश्वास॥\n\nउदी लगाकर मस्तक पर, साईं का आशीर्वाद।\nसंकट मोचन साईं बाबा, करते हैं सब बरबाद॥\n\nसाईं की लीला अपरंपार, कोई न समझे भेद।\nभक्तों के जीवन में साईं, बिखेरें सुख की रेत॥\n\nश्रद्धा और सबुरी सिखाते, साईं बाबा महान।\nजो भी शरण में आए, पूरा हो उसका काम॥\n\nसाईं बाबा के चरणों में, अर्पित है यह गान।\nजय साईं राम, जय साईं श्याम, साईं का है सम्मान॥",
      "prayer_en":
          "Salutations to Shri Sai Nath.\nIn Sai Baba’s court, everyone receives love.\nHe listens to the cries of devotees, compassionate beyond measure.\n\nSai Baba, Sai Baba, you are the merciful one.\nEmbodiment of truth, consciousness, and bliss, protector of devotees.\n\nSai resides in Shirdi, meditating in Dwarkamai.\nHe removes all sorrows, his power is supreme.\n\nOm Sai, Shri Sai, Victory to Sai Nath.\nResiding in devotees’ hearts, Sai’s words shine.\n\n‘All have one master,’ is Sai’s message.\nUniting Hindu and Muslim, his faith is in love.\n\nApplying udi on the forehead, Sai’s blessings flow.\nSai Baba, the remover of obstacles, destroys all miseries.\n\nSai’s divine play is boundless, beyond comprehension.\nIn devotees’ lives, he spreads the sand of joy.\n\nTeaching faith and patience, Sai Baba is great.\nWhoever seeks his shelter, their wishes are fulfilled.\n\nAt Sai Baba’s feet, this song is offered.\nVictory to Sai Ram, victory to Sai Shyam, Sai is honored.",
      "description_hi":
          "श्री साईं बाबा को समर्पित यह भजन श्रद्धा, सबुरी और एकता का संदेश देता है।",
      "description_en":
          "This hymn dedicated to Shri Sai Baba conveys the message of faith, patience, and unity.",
      "image_url":
          "https://www.tallengestore.com/cdn/shop/products/ShirdiSaiBaba-SpiritualPaintingPoster.jpg?v=1688682538",
    },
  ];

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetRandomQuoteEvent());
    // Uncomment if you want to fetch prayers from API
    // BlocProvider.of<HomeFlowBloc>(context).add(GetAllPrayersEvent());
  }

  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1)),
          child: Scaffold(
            body: SafeArea(
              child: BlocListener<HomeFlowBloc, HomeFlowState>(
                listener: (context, state) {
                  if (state is GetRandomQuoteLoading) {
                    setState(() {
                      isLoading = true;
                    });
                  } else if (state is GetRandomQuoteSuccess) {
                    setState(() {
                      isLoading = false;
                      quoteResponse = state.successResponse;
                    });
                  } else if (state is GetRandomQuoteFailure) {
                    setState(() {
                      isLoading = false;
                    });
                    CommonUtils.showErrorToast(
                      state.failureResponse['message'],
                    );
                  } else if (state is GetAllPrayersLoading) {
                    setState(() {
                      isPrayersLoading = true;
                    });
                  } else if (state is GetAllPrayersLoaded) {
                    setState(() {
                      isPrayersLoading = false;
                      allPrayers.addAll(state.successResponse);
                    });
                  } else if (state is GetAllPrayersFailure) {
                    setState(() {
                      isPrayersLoading = false;
                    });
                    CommonUtils.showErrorToast('Failed to load prayers');
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/bgGitaGPT.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          // Sticky Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('home'),
                                  style: FTextStyle.homeText,
                                ),
                              ),
                              LanguageDropdown(),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Sticky Card with search
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                              color: Colors.white,
                            ),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.GlobalBG,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Image.asset(
                                        'assets/images/homeImage.png',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (isLoading)
                                          Center(
                                            child:
                                                LoadingAnimationWidget.staggeredDotsWave(
                                                  color:
                                                      AppColors.gradientStart,
                                                  size: 50,
                                                ),
                                          )
                                        else
                                          Text(
                                            quoteResponse.isNotEmpty
                                                ? quoteResponse
                                                : AppLocalizations.of(
                                                  context,
                                                )!.translate('loremipsumShort'),
                                            style:
                                                FTextStyle
                                                    .socialloginbuttonText,
                                            textAlign: TextAlign.center,
                                          ),
                                        const SizedBox(height: 20),
                                        Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                'assets/images/searchIcon.png',
                                                height: 16,
                                                width: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: searchController,
                                                  textInputAction:
                                                      TextInputAction.search,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                AskAnythingScreen(),
                                                      ),
                                                    );
                                                  },
                                                  readOnly: true,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.translate(
                                                          'askAnything',
                                                        ),
                                                    hintStyle:
                                                        FTextStyle.defaultText,
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Scrollable list
                          Expanded(
                            child:
                                isPrayersLoading
                                    ? Center(
                                      child:
                                          LoadingAnimationWidget.staggeredDotsWave(
                                            color: AppColors.gradientStart,
                                            size: 50,
                                          ),
                                    )
                                    : ListView.builder(
                                      itemCount: allPrayers.length,
                                      itemBuilder: (context, index) {
                                        final locale =
                                            Localizations.localeOf(
                                              context,
                                            ).languageCode;
                                        final item = allPrayers[index];

                                        // Select fields for display in the list (optional, for preview)
                                        final title =
                                            locale == 'en'
                                                ? item['title_en'] ??
                                                    item['title_hi']
                                                : item['title_hi'] ??
                                                    item['title_en'];
                                        final description =
                                            locale == 'en'
                                                ? item['description_en'] ??
                                                    item['description_hi']
                                                : item['description_hi'] ??
                                                    item['description_en'];
                                        final prayer =
                                            locale == 'en'
                                                ? item['prayer_en'] ??
                                                    item['prayer_hi']
                                                : item['prayer_hi'] ??
                                                    item['prayer_en'];

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 15,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ChalisaScreen(
                                                        image:
                                                            item['image_url'] ??
                                                            '',
                                                        titleEn:
                                                            item['title_en'] ??
                                                            'No English Title',
                                                        titleHi:
                                                            item['title_hi'] ??
                                                            'No Hindi Title',
                                                        prayerEn:
                                                            item['prayer_en'] ??
                                                            'No English Prayer',
                                                        prayerHi:
                                                            item['prayer_hi'] ??
                                                            'No Hindi Prayer',
                                                        // Optionally pass description if needed
                                                        descriptionEn:
                                                            item['description_en'] ??
                                                            'No English Description',
                                                        descriptionHi:
                                                            item['description_hi'] ??
                                                            'No Hindi Description',
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 100,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.GlobalBG,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Show network image from `image_url`
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      item['image_url'] ?? '',
                                                      height: 80,
                                                      width: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Image.asset(
                                                            'assets/images/hanuman_placeholder.png',
                                                            height: 80,
                                                            width: 80,
                                                            fit: BoxFit.cover,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Title and Description
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          title ?? 'No Title',
                                                          style: FTextStyle
                                                              .defaultText
                                                              .copyWith(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                          description ??
                                                              'No Description',
                                                          style: FTextStyle
                                                              .defaultText
                                                              .copyWith(
                                                                fontSize: 10,
                                                              ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Right Arrow Icon
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => ChalisaScreen(
                                                                image:
                                                                    item['image_url'] ??
                                                                    '',
                                                                titleEn:
                                                                    item['title_en'] ??
                                                                    'No English Title',
                                                                titleHi:
                                                                    item['title_hi'] ??
                                                                    'No Hindi Title',
                                                                prayerEn:
                                                                    item['prayer_en'] ??
                                                                    'No English Prayer',
                                                                prayerHi:
                                                                    item['prayer_hi'] ??
                                                                    'No Hindi Prayer',
                                                                // Optionally pass description if needed
                                                                descriptionEn:
                                                                    item['description_en'] ??
                                                                    'No English Description',
                                                                descriptionHi:
                                                                    item['description_hi'] ??
                                                                    'No Hindi Description',
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      height: 30,
                                                      width: 30,
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors
                                                                .gradientStart,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                      child: Image.asset(
                                                        'assets/images/whiteArrow.png',
                                                        height: 8,
                                                        width: 8,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
