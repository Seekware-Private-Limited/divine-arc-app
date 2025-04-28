import 'package:gita_gpt/Screens/ask_anything_screen.dart';
import 'package:gita_gpt/Screens/gpt_screen.dart';

import '../Utils/app_imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedLanguage = 'English';
  List<String> languages = ['English', 'Hindi', 'Hinglish', 'Marathi'];

  final GlobalKey _dropdownKey = GlobalKey();

  List<Map<String, String>> geetaList = List.generate(
    10,
        (index) => {
      'title': 'BHAGWAT GEETA',
      'subtitle': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'image': 'assets/images/bhagwatGeeta.png',
    },
  );

  void _showCustomDropdown(BuildContext context) async {
    final RenderBox renderBox = _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 3,
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Language", style: FTextStyle.socialloginbuttonText),
              const Divider(),
            ],
          ),
        ),
        ...languages.map(
              (lang) => PopupMenuItem<String>(
            value: lang,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang,
                  style: selectedLanguage == lang
                      ? FTextStyle.selectedRadioColorText
                      : FTextStyle.socialloginbuttonText,
                ),
                Icon(
                  selectedLanguage == lang ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selectedLanguage == lang ? AppColors.gradientStart : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
      elevation: 8,
      color: Colors.white,
    );

    if (selected != null) {
      setState(() {
        selectedLanguage = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.GlobalBG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(child: Text('Home', style: FTextStyle.homeText)),
                    Positioned(
                      right: 0,
                      top: 5,
                      child: GestureDetector(
                        key: _dropdownKey,
                        onTap: () => _showCustomDropdown(context),
                        child: Container(
                          height: 35,
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(selectedLanguage, style: FTextStyle.socialloginbuttonText),
                              const Icon(Icons.keyboard_arrow_down_sharp),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
            
                // Main card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gradientStart, width: 1.5),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Container(
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
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Lorem ipsum dolor sit.",
                                    style: FTextStyle.defaultTextBold,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Lorem ipsum dolor sit amet, dolor sit amet, conse",
                                    style: FTextStyle.socialloginbuttonText,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Image.asset('assets/images/searchIcon.png', height: 16, width: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Search',
                                              hintStyle: FTextStyle.defaultText,
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
                      const SizedBox(height: 20),
            
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: geetaList.length,
                        itemBuilder: (context, index) {
                          final item = geetaList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AskAnythingScreen()));
                              },
                              child: Container(
                                height: 100,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.GlobalBG,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        item['image']!,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item['title']!,
                                            style: FTextStyle.defaultText.copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            item['subtitle']!,
                                            style: FTextStyle.defaultText.copyWith(fontSize: 10),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      height: 30,
                                      width: 30,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.gradientStart,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Image.asset(
                                        'assets/images/whiteArrow.png',
                                        height: 10,
                                        width: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
  }
}
