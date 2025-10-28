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
          "|| Doha ||\nShri Guru Charan Saroj Raj, Nija Manu Mukura Sudhari |\n\nBaranau Raghuvar Bimal Jasu, Jo Dayaku Phala Chari ||\n\nBudheeheen Tanu Jannike, Sumiro Pavan Kumara |\n\nBal Buddhi Vidya Dehoo Mohee, Harahu Kalesh Vikaar ||\n\n\n|| Chaupai ||\nJai Hanuman Gyan Gun Sagar | Jai Kapis Tihun Lok Ujagar ||\n\nRam Doot Atulit Bal Dhama | Anjani Putra Pavan Sut Nama ||\n\nMahabir Vikram Bajrangi | Kumati Nivar Sumati Ke Sangi ||\n\nKanchan Varan Viraj Subesa | Kanan Kundal Kunchit Kesha || 4\n\nHath Vajra Aur Dhwaja Viraje | Kaandhe Moonj Janeu Saaje ||\n\nSankar Suvan Kesri Nandan | Tej Prataap Maha Jag Vandan ||\n\nVidyavaan Guni Ati Chatur | Ram Kaj Karibe Ko Aatur ||\n\nPrabhu Charitra Sunibe Ko Rasiya | Ram Lakhan Sita Man Basiya || 8\n\nSukshma Roop Dhari Siyahi Dikhava | Vikat Roop Dhari Lank Jalava ||\n\nBhim Roop Dhari Asur Sanhare | Ramachandra Ke Kaj Sanvare ||\n\nLaye Sanjivan Lakhan Jiyaye | Shri Raghuvir Harashi Ur. Laye ||\n\nRaghupati Kinhi Bahut Badai | Tum Mama Priya Bharat-Hi-Sam Bhai || 12\n\nSahas Badan Tumharo Yash Gaave | As Kahi Shripati Kanth Lagaave ||\n\nSankadhik Brahmaadi Muneesa | Narad Sarad Sahit Aheesa ||\n\nYam Kuber Dikpaal Jahan Te | Kavi Kovid Kahi Sake Kahan Te ||\n\nTum Upkar Sugreevahin Keenha | Ram Milaye Rajpad Deenha || 16\n\nTumhro Mantra Vibheeshan Maana | Lankeshwar Bhaye Sab Jag Jana ||\n\nYug Sahasra Yojan Par Bhanu | Leelyo Tahi Madhur Phal Janu ||\n\nPrabhu Mudrika Meli Mukh Mahee | Jaladhi Langhi Gaye Achraj Nahee ||\n\nDurgam Kaj Jagat Ke Jete | Sugam Anugraha Tumhre Tete || 20\n\nRam Duwaare Tum Rakhvare | Hot Na Agya Binu Paisare ||\n\nSab Sukh Lahai Tumhari Sarna | Tum Rakshak Kahu Ko Darna ||\n\nAapan Tej Samharo Aapai | Teenon Lok Hank Te Kanpai ||\n\nBhoot Pisaach Nikat Nahin Aavai | Mahavir Jab Naam Sunavai || 24\n\nNase Rog Harae Sab Peera | Japat Nirantar Hanumat Beera ||\n\nSankat Se Hanuman Chhudavai | Man Kram Vachan Dhyan Jo Lavai ||\n\nSab Par Ram Tapasvee Raja | Tin Ke Kaj Sakal Tum Saja ||\n\nAur Manorath Jo Koi Lavai | Soi Amit Jeevan Phal Pavai || 28\n\nCharon Jug Partap Tumhara | Hai Parsiddh Jagat Ujiyara ||\n\nSadhu Sant Ke Tum Rakhware | Asur Nikandan Ram Dulare ||\n\nAshta Siddhi Nav Nidhi Ke Data | As Var Deen Janki Mata ||\n\nRam Rasayan Tumhare Pasa | Sada Raho Raghupati Ke Dasa || 32\n\nTumhare Bhajan Ram Ko Pavai | Janam Janam Ke Dukh Bisraavai ||\n\nAntkaal Raghuvar Pur Jayee | Jahan Janam Hari Bhakt Kahayee ||\n\nAur Devta Chitt Na Dharahin | Hanumat Sei Sarv Sukh Karahin ||\n\nSankat Kate Mite Sab Peera | Jo Sumirai Hanumat Balbeera || 36\n\nJai Jai Jai Hanuman Gosain | Kripa Karahun Gurudev Ki Nayin ||\n\nJo Shat Bar Path Kare Koi | Chhutahin Bandi Maha Sukh Hoi ||\n\nJo Yeh Padhe Hanuman Chalisa | Hoye Siddhi Saakhi Gaureesa ||\n\nTulsidas Sada Hari Chera | Keejai Nath Hriday Mahn Dera || 40\n\n|| Doha ||\nPavan Tanay Sankat Harana, Mangala Murati Roop |\nRam Lakhan Sita Sahita, Hriday Basahu Soor Bhoop ||",
      "description_hi":
          "श्री हनुमान जी को समर्पित तुलसीदास रचित भक्ति भजन, जो भक्ति, शक्ति और सुरक्षा का प्रतीक है।",
      "description_en":
          "A devotional hymn dedicated to Lord Hanuman, composed by Tulsidas, symbolizing devotion, strength, and protection.",
      "image_url":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRr2az5eDfxbeLjgN7KGpO_FBLDRzUIdx5NtQ&s",
      "audio": "audio/hanumanChalisa.mp3",
    },
    {
      "title_hi": "दुर्गा माता की आरती",
      "title_en": "Durga Mata Aarti",
      "prayer_hi":
          "जय अंबे गौरी, मैया जय श्यामा गौरी।\nतुमको निशिदिन ध्यावत, हरि ब्रह्मा शिवरी॥ ओम जय अंबे गौरी\n\nमांग सिन्दूर विराजत, टीको मृगमद को।\nउज्जवल से दो‌उ नैना, चन्द्रवदन नीको॥ ओम जय अंबे गौरी\n\nकनक समान कलेवर, रक्ताम्बर राजै।\nरक्तपुष्प गल माला, कण्ठन पर साजै॥ ओम जय अंबे गौरी\n\nकेहरि वाहन राजत, खड्ग खप्परधारी।\nसुर-नर-मुनि-जन सेवत, तिनके दुखहारी॥ ओम जय अंबे गौरी\n\nकानन कुण्डल शोभित, नासाग्रे मोती।\nकोटिक चन्द्र दिवाकर, सम राजत ज्योति॥ ओम जय अंबे गौरी\n\nशुम्भ-निशुम्भ बिदारे, महिषासुर घाती।\nधूम्र विलोचन नैना, निशिदिन मदमाती॥ ओम जय अंबे गौरी\n\nचण्ड-मुण्ड संहारे, शोणित बीज हरे।\nमधु-कैटभ दो‌उ मारे, सुर भयहीन करे॥ ओम जय अंबे गौरी\n\nब्रहमाणी रुद्राणी तुम कमला रानी।\nआगम-निगम-बखानी, तुम शिव पटरानी॥ ओम जय अंबे गौरी\n\nचौंसठ योगिनी मंगल गावत, नृत्य करत भैरूं।\nबाजत ताल मृदंगा, अरु बाजत डमरु॥ ओम जय अंबे गौरी\n\nतुम ही जग की माता, तुम ही हो भरता।\nभक्‍तन की दु:ख हरता, सुख सम्पत्ति करता॥ ओम जय अंबे गौरी\n\nभुजा चार अति शोभित, वर-मुद्रा धारी।\nमनवान्छित फल पावत, सेवत नर-नारी॥ ओम जय अंबे गौरी\n\nकंचन थाल विराजत, अगर कपूर बाती।\nश्रीमालकेतु में राजत, कोटि रतन ज्योति॥ ओम जय अंबे गौरी\n\nश्री अम्बेजी की आरती, जो को‌ई नर गावै।\nकहत शिवानन्द स्वामी, सुख सम्पत्ति पावै॥ ओम जय अंबे गौरी\n\nजोर से बोलो जय माता दी, सारे बोले जय माता दी।\nबोल सांचे दरबार की जय, जयकारा शेरावाली का बोल सांचे दरबार की जय",
      "prayer_en":
          "Jai Ambe Gauri, Maiya Jai Shyama Gauri.\n\nTumako Nishadin Dhyavat, Hari Bramha Shivari.\nOm Jai Ambe Gauri\n\nMang Sindur Virajat, Tiko Mrigamad Ko.\nUjjval Se Dou Naina, Chandravadan Niko.\nOm Jai Ambe Gauri\n\nKanak Saman Kalevar, Raktambar Raje,\nRaktpushp Gal Mala, Kanthan Par Saje.\nOm Jai Ambe Gauri\n\nKehari Vahan Rajat, Khadag Khappar Dhari,\nSur-Nar-Munijan Sevat, Tinake Dukhahari.\nOm Jai Ambe Gauri\n\nKaanan Kundal Shobhit, Nasagre Moti,\nKotik Chandr Divakar, Rajat Sam Jyoti.\nOm Jai Ambe Gauri\n\nShumbh-Nishumbh Bidare, Mahishasur Ghati,\nDhumr Vilochan Naina, Nishadin Madamati.\nOm Jai Ambe Gauri\n\nChand-Mund Sanhare, Shonit Bij Hare,\nMadhu-Kaitabh Dou Mare, Sur Bhayahin Kare.\nOm Jai Ambe Gauri\n\nBramhani, Rudrani, Tum Kamala Rani,\nAgam Nigam Bakhani, Tum Shiv Patarani.\nOm Jai Ambe Gauri\n\nChausath Yogini Mangal Gavat, Nritya Karat Bhairu,\nBajat Tal Mridanga, Aru Baajat Damaru.\nOm Jai Ambe Gauri\n\nTum Hi Jag Ki Mata, Tum Hi Ho Bharata,\nBhaktan Ki Dukh Harta, Sukh Sampati Karta.\nOm Jai Ambe Gauri\n\nBhuja Char Ati Shobhi, Varamudra Dhari,\nManvanchhit Fal Pavat, Sevat Nar Nari.\nOm Jai Ambe Gauri\n\nKanchan Thal Virajat, Agar Kapur Bati,\nShrimalaketu Mein Rajat, Koti Ratan Jyoti.\nOm Jai Ambe Gauri\n\nShri Ambeji Ki Arati, Jo Koi Nar Gave,\nKahat Shivanand Svami, Sukh-Sampatti Pave.\nOm Jai Ambe Gauri",
      "description_hi":
          "माँ दुर्गा की स्तुति में गाया जाने वाला पावन भजन, जो शक्ति, साहस और देवी माँ के आशीर्वाद का प्रतीक है।",
      "description_en":
          "A sacred hymn sung in praise of Mother Durga, symbolizing strength, courage, and the blessings of the Goddess.",
      "image_url":
          "https://t4.ftcdn.net/jpg/09/75/63/59/360_F_975635990_6M7X8OwBuHtxmZiti6Rqy4gjyC8uMqid.jpg",
      "audio": "audio/durgamataAarti.mp3",
    },
    {
      "title_hi": "शिव तांडव स्तोत्रम",
      "title_en": "Shiva Tandava Stotram",
      "prayer_hi":
          "जटाटवीगलज्जलप्रवाहपावितस्थले\nगलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम्।\nडमड्डमड्डमड्डमन्निनादवड्डमर्वयं\nचकार चण्डताण्डवं तनोतु नः शिवः शिवम्॥१॥\n\nजटाकटाहसंभ्रमभ्रमन्निलिम्पनिर्झरी\nविलोलवीचिवल्लरीविराजमानमूर्धनि।\nधगद्धगद्धगज्ज्वलल्ललाटपट्टपावके\nकिशोरचन्द्रशेखरे रतिः प्रतिक्षणं मम॥२॥\n\nधराधरेन्द्रनंदिनीविलासबन्धुबन्धुर\nस्फुरद्दिगन्तसन्तति प्रभोत्तमप्रदीप्तकम्।\nबुधाबुधाविनाशिनीं महायोगिनीं नमामि ताम्\nनमामि तं विनोदिनीं नमामि तं च ताण्डवम्॥३॥\n\nजटाभुजङ्गपिङ्गलस्फुरत्फणामणिप्रभा\nकदम्बकुङ्कुमद्रवप्रलिप्तदिग्वधूमुखे।\nमदान्धसिन्धुरस्फुरत्त्वगुत्तरीयमेदुरे\nमनो विनोदमद्भुतं बिभर्तु भूतभर्तरि॥४॥\n\nसहस्रलोचनप्रभृत्यशेषलेखशेखर\nप्रसूनधूलिधोरणी विधूसराङ्घ्रिपीठभूः।\nभुजङ्गराजमालया निबद्धजाटजूटकः\nश्रियै चिराय जायते चकार चण्डताण्डवम्॥५॥\n\nस्पृषद्विचित्रतन्तुं तनुरुहैर्विलासिनीं\nविलोललोललोचनं ललामभाललग्नकम्।\nकपालभालपावकं धगद्धगद्धगज्ज्वलं\nमहाकपालिनीं नमामि तं च ताण्डवम्॥६॥\n\nकरालभालपट्टिकाधगद्धगद्धगज्ज्वल\nद्धनञ्जयाहुतीकृतप्रचण्डपञ्चसायकम्।\nनमामि तं नमामि तं नमामि तं च ताण्डवम्\nनमामि तं नमामि तं नमामि तं च ताण्डवम्॥७॥\n\nनवीनमेघमण्डली निरुद्धदुर्धरस्फुरत्\nकुहूर्निशीथिनीतमः प्रबन्धबन्धकन्धरः।\nनिलिम्पनिर्झरीधरस्तनोतु कृत्तिसिन्धुरः\nकलानिधानबन्धुरः श्रियं जगद्धुरंधरः॥८॥\n\nप्रफुल्लनीलपङ्कजप्रपञ्चकालिमच्छटा\nविलोललोचनं कटि प्रभासति त्रिलोचनम्।\nललाटचत्वरज्वलद्धनञ्जयस्फुरत्प्रभा\nप्रभासति त्रिलोचनं नमामि तं च ताण्डवम्॥९॥\n\nसुधामयूखलेखया विराजमानशेखरं\nमहाकपालिसम्पदे शिरोजटालमस्तु नः।\nकरालभालपट्टिकाधगद्धगद्धगज्ज्वलं\nमहाकपालिनीं नमामि तं च ताण्डवम्॥१०॥\n\nइमं हि नित्यमेवमुक्तमुत्तमं स्तवं\nपठन्स्मरन्ब्रुवन्नरो विशुद्धिमेति सन्ततम्।\nहरे गुरौ सुभक्तिमाशु याति नान्यथा गतिं\nविमोहनं हि देहिनां सुशङ्करस्य चिन्तनम्॥११॥\n\nपूजावसानसमये दशवक्त्रगीतं\nयः शम्भुपूजनपरं पठति प्रदोषे।\nतस्य स्थिरां रथगजेन्द्रतुरङ्गयुक्तां\nलक्ष्मीं सदैव सुमुखीं प्रददाति शम्भुः॥१२॥",
      "prayer_en":
          "Jatatavi galajjala pravaha pavitasthale\nGalevalambya lambitam bhujanga tungamalikam\nDamad damad damad dama ninada vadda marvayam\nChakara chanda tandavam tanotu nah shivah shivam\n\nJata kata hasam bhrama bhrama nilimpa nirjhari\nVilolavi chivallari viraja mana murdhani\nDhagadhagadha gajjvala lalata patta pavake\nKishora chandra shekhare ratih pratikshanam mama\n\nDhara dharendra nandini vilasa bandhu bandhura\nSphuraddi ganta santati pramoda mana manase\nKrupa kataksha dhorani nirudhadurdha rapadi\nKvachit digambare mano vinodametu vastuni\n\nJata bhujanga pingala sphurat phana mani prabha\nKadamba kunkuma drava pralipta digva dhumukhe\nMadandha sindhura sphura tvaguttari ya medure\nMano vinoda madbhutam bibhartu bhuta bhartari\n\nSahasra lochana prabhritya shesha lekha shekhara\nPrasuna dhulidhorani vidhu saranghri pithabhuh\nBhujanga raja malaya nibaddha jata jutaka\nShriyai chiraya jayatam chakora bandhu shekharah\n\nLalata chatva rajvala dhanan jaya sphu lingabha\nNipita pancha sayakam naman nilimpa nayakam\nSudha mayukha lekhaya viraja mana shekharam\nMaha kapali sampade shiro jata lamastu nah\n\nKarala phala pattika dhagad dhagad dhagaj jvala\nDdhanan jaya dhari kruta prachanda pancha sayake\nDhara dharendra nandini kuchagra chitra patraka\nPrakalpa naika shilpini trilochane ratir mama\n\nNavina megha mandali niruddha durdha rasphurat\nKuhunishithi nitamah prabandha baddha kandharah\nNilimpa nirjhari dhara stanotu krutti sindhurah\nKala nidhana bandhurah shriyam jagad dhurandharah\n\nPrafulla nila pankaja prapancha kali maprabha\nValambi kantha kandali ruchi prabaddha kandharam\nSmarachhidam purachhidam bhavachhidam makhachhidam\nGajachhidandha kachhidam tamanta kachhidam bhaje\n\nAgarva sarva mangala kala kadamba manjari\nRasa pravaha madhuri vijrumbhana madhuvratam\nSmarantakam purantakam bhavantakam makhantakam\nGajanta kandha kantakam tamanta kantakam bhaje\n\nJayatvada bhravibhrama bhramad bhujanga mashvasa\nDvi nirgamatkrama sphurat karala phala havyavat\nDhimid dhimid dhimidhvanan mrudanga tunga mangala\nDhvani krama pravartita prachanda tandavah shivah\n\nDrushadvi chitra talpayor bhujanga maukti kasrajor\nGarishtha ratna loshthayoh suhrudvi paksha pakshayoh\nTrushnara vinda chakshushoh praja mahi mahendrayoh\nSamam pravartayan manah kada sada shivam bhaje\n\nKada nilimpa nirjhari nikunja kotare vasan\nVimukta durmatih sada shirah sthamanjalim vahan\nVimukta lola lochano lalama bhala lagnakah\nShiveti mantra munchharan kada sukhi bhavamyaham\n\nImam hi nityameva mukta mutta mottamam stavam\nPathan smaran bruvannaro vishuddhi meti santatam\nHare gurav subhakti mashu yati nanyatha gatim\nVimohanam hi dehinam sushankarasya chintanam",
      "description_hi":
          "रावण रचित यह स्तोत्र भगवान शिव के तांडव नृत्य की महिमा का वर्णन करता है, जो शक्ति और आध्यात्मिक ऊर्जा का प्रतीक है।",
      "description_en":
          "Composed by Ravana, this hymn describes the glory of Lord Shiva’s Tandava dance, symbolizing power and spiritual energy.",
      "image_url":
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPMeO-wt9Omcum7oYO55hDW4rfZlU-XfW79GmpUQEisa4FRQ4IWaQINDiJtZCbNhOiRlw&usqp=CAU",
      "audio": "audio/shivaTandavaStotram.mp3",
    },

    {
      "title_hi": "आरती कुंजबिहारी",
      "title_en": "Aarti Kunj Bihari",
      "prayer_hi":
          "आरती कुंजबिहारी की,\nश्री गिरिधर कृष्ण मुरारी की ॥\nआरती कुंजबिहारी की,\nश्री गिरिधर कृष्ण मुरारी की ॥\nगले में बैजंती माला, बजावै मुरली मधुर बाला । श्रवण में कुण्डल झलकाला, नंद के आनंद नंदलाला ।\nगगन सम अंग कांति काली, राधिका चमक रही आली । लतन में ठाढ़े बनमाली भ्रमर सी अलक, कस्तूरी तिलक, चंद्र सी झलक, ललित छवि श्यामा प्यारी की, श्री गिरिधर कृष्ण मुरारी की ॥\n॥ आरती कुंजबिहारी की...॥\nकनकमय मोर मुकुट बिलसै, देवता दरसन को तरसैं । गगन सों सुमन रासि बरसै । बजे मुरचंग, मधुर मिरदंग, ग्वालिन संग, अतुल रति गोप कुमारी की, श्री गिरिधर कृष्णमुरारी की ॥\n॥ आरती कुंजबिहारी की...॥\nजहां ते प्रकट भई गंगा, सकल मन हारिणि श्री गंगा । स्मरन ते होत मोह भंगा बसी शिव सीस, जटा के बीच, हरै अघ कीच, चरन छवि श्रीबनवारी की, श्री गिरिधर कृष्णमुरारी की ॥\n॥ आरती कुंजबिहारी की...॥\nचमकती उज्ज्वल तट रेनू, बज रही वृंदावन बेनू । चहुं दिसि गोपि ग्वाल धेनू हंसत मृदु मंद, चांदनी चंद, कटत भव फंद, टेर सुन दीन दुखारी की, श्री गिरिधर कृष्णमुरारी की ॥\n॥ आरती कुंजबिहारी की...॥\nआरती कुंजबिहारी की,\nश्री गिरिधर कृष्ण मुरारी की ॥\nआरती कुंजबिहारी की,\nश्री गिरिधर कृष्ण मुरारी की ॥",
      "prayer_en":
          "Aarti Kunj Bihari Ki,\nShri Girdhar Krishna Murari Ki ॥\nAarti Kunj Bihari Ki,\nShri Girdhar Krishna Murari Ki ॥\n\nGale Mein Baijanti Mala, Bajave Murali Madhur Bala । Shravan Mein Kundal Jhalakala,\nNand Ke Anand Nandlala । Gagan Sam Ang Kanti Kali, Radhika Chamak Rahi Aali ।\nLatan Mein Thadhe Banamali Bhramar Si Alak, Kasturi Tilak, Chandra Si Jhalak,\nLalit Chavi Shyama Pyari Ki, Shri Girdhar Krishna Murari Ki ॥\n॥ Aarti Kunj Bihari Ki...॥\n\nKanakmay Mor Mukut Bilse, Devata Darsan Ko Tarse । Gagan So Suman Raasi Barse\nBaje Murchang, Madhur Mridang, Gwaalin Sang Atual Rati Gop Kumari Ki,\nShri Girdhar Krishna Murari Ki ॥\n॥ Aarti Kunj Bihari Ki...॥\n\nJahaan Te Pragat Bhayi Ganga, Sakal Man Haarini Shri Ganga । Smaran Te Hot Moh Bhanga\nBasi Shiv Shish, Jataa Ke Beech, Harei Agh Keech, Charan Chhavi Shri Banvaari Ki,\nShri Girdhar Krishna Murari Ki ॥\n॥ Aarti Kunj Bihari Ki...॥\n\nChamakati Ujjawal Tat Renu, Baj Rahi Vrindavan Benu। Chahu Disi Gopi Gwaal Dhenu\nHansat Mridu Mand, Chandani Chandra, Katat Bhav Phand, Ter Sun Deen Dukhari Ki,\nShri Girdhar Krishna Murari Ki ॥\n॥ Aarti Kunj Bihari Ki...॥\n\nAarti Kunj Bihari Ki,\nShri Girdhar Krishna Murari Ki ॥\nAarti Kunj Bihari Ki,\nShri Girdhar Krishna Murari Ki ॥",
      "description_hi":
          "श्री कृष्ण को समर्पित यह आरती भक्ति, प्रेम और आनंद का संदेश देती है।",
      "description_en":
          "This Aarti dedicated to Lord Krishna conveys the essence of devotion, love, and divine joy.",
      "image_url":
          "https://m.media-amazon.com/images/I/51YrcSFYDRL._AC_UF894,1000_QL80_.jpg",
      "audio": "audio/krishnaAarti.mp3",
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
                                                        audio: item['audio'],
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
                                                                audio:
                                                                    item['audio'],
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
