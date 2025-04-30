import 'package:gita_gpt/Utils/app_imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> geetaList = List.generate(
      10,
          (index) => {
        'title': AppLocalizations.of(context)!.translate('bhagwatGeeta'),
        'subtitle': AppLocalizations.of(context)!.translate('loremipsumLong'),
        'image': 'assets/images/bhagwatGeeta.png',
      },
    );

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
          child: Scaffold(
            backgroundColor: AppColors.GlobalBG,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Sticky Header
                    Stack(
                      children: [
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.translate('home'),
                            style: FTextStyle.homeText,
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          top: 5,
                          child: LanguageDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sticky Card with search
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gradientStart, width: 1.5),
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
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.translate('loremipsumShort'),
                                    style: FTextStyle.defaultTextBold,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.translate('loremipsumLong'),
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
                                              hintText: AppLocalizations.of(context)!.translate('search'),
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
                    ),

                    const SizedBox(height: 20),

                    // Scrollable list
                    Expanded(
                      child: ListView.builder(
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
                                        height: 8,
                                        width: 8,
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
            ),
          ),
        );
      },
    );
  }

}
