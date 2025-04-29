import 'package:gita_gpt/Utils/app_imports.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: AppColors.GlobalBG,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('bookmark'), style: FTextStyle.homeText),
                      const LanguageDropdown()
                    ],
                  ),
                  const SizedBox(height: 20),
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
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 10,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: EdgeInsets.all(20),
                             decoration: BoxDecoration(
                               color: AppColors.GlobalBG,
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child:Row(
                               children: [
                                 Expanded(child: Text(AppLocalizations.of(context)!.translate('dummyText'),style: FTextStyle.defaultText)),
                                 Image.asset('assets/images/bookmark.png',height: 18,width: 18,)
                               ],
                             )
                          ),
                        );
                      },
              
                    )
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
