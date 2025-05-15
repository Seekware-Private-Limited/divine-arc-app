import 'package:gita_gpt/Utils/FontSizeDropdown.dart';
import 'package:gita_gpt/Utils/app_imports.dart';

class ChalisaScreen extends StatefulWidget {
  const ChalisaScreen({super.key});

  @override
  State<ChalisaScreen> createState() => _ChalisaScreenState();
}

class _ChalisaScreenState extends State<ChalisaScreen> {
  double _fontSizeMultiplier = 1.0;
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_fontSizeMultiplier),
      ),
      child: Scaffold(
        backgroundColor: AppColors.GlobalBG,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.translate('home'), style: FTextStyle.homeText),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LanguageDropdown(),
                        FontSizeDropdown(
                          currentScale: _fontSizeMultiplier,
                          onFontSizeChanged: (newScale) {
                            setState(() {
                              _fontSizeMultiplier = newScale;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
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
                              child: Image.asset('assets/images/bhagwatGeeta.png',height: 70,width: 70,fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 20),
                            Text(AppLocalizations.of(context)!.translate('hanumanChalisa'),style: FTextStyle.boldText),
                            const SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.translate('doha'),style: FTextStyle.dohaText),
                            const SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.translate('dohaDesc'),style: FTextStyle.defaultText),
                            const SizedBox(height: 20),
                            Text(AppLocalizations.of(context)!.translate('chaupai'),style: FTextStyle.dohaText),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalizations.of(context)!.translate('chalisa'),
                              textAlign: TextAlign.center,
                              style: FTextStyle.defaultText,
                            )
                          ],
                        ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
