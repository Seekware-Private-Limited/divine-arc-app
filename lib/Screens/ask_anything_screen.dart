
import '../Utils/app_imports.dart';
class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  String selectedLanguage = 'English';
  List<String> languages = ['English', 'Hindi', 'Hinglish', 'Marathi'];

  final GlobalKey _dropdownKey = GlobalKey();

  List<Map<String, String>> geetaList = List.generate(
    4,
        (index) => {
      'title': 'BHAGWAT GEETA',
      'subtitle': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'image': 'assets/images/bhagwatGeeta.png',
    },
  );

  void _showCustomDropdown(BuildContext context) async {
    final RenderBox renderBox =
    _dropdownKey.currentContext!.findRenderObject() as RenderBox;
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
                  selectedLanguage == lang
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedLanguage == lang
                      ? AppColors.gradientStart
                      : Colors.grey,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              Text(
                                selectedLanguage,
                                style: FTextStyle.socialloginbuttonText,
                              ),
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
                    border: Border.all(
                      color: AppColors.gradientStart,
                      width: 1.5,
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/bhagwatGeeta.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('BHAGWAT GEETA', style: FTextStyle.boldText),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.gradientStart,
                            width: 1.5,
                          ),
                          color: Colors.white,
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 80),
                              child: TextFormField(
                                style: FTextStyle.defaultText,
                                decoration: InputDecoration(
                                  hintText: 'Ask Anything',
                                  hintStyle: FTextStyle.defaultText,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                maxLines: 5,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.gradientStart,
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                      color: Colors.white,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.mic,
                                        size: 20,
                                        color: AppColors.gradientStart,
                                      ),
                                      onPressed: () {
                                        // handle mic
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.gradientStart,
                                          AppColors.gradientEnd,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        // handle send
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // GRID VIEW for cards
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: geetaList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => GptScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.GlobalBG,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/swastik.png',
                                    height: 30,
                                    width: 30,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    geetaList[index]['subtitle']!,
                                    style: FTextStyle.defaultText,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
