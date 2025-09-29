import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class ChalisaScreen extends StatefulWidget {
  final String image;
  final String titleEn;
  final String titleHi;
  final String prayerEn;
  final String prayerHi;
  final String descriptionEn; // Optional
  final String descriptionHi; // Optional

  const ChalisaScreen({
    super.key,
    required this.image,
    required this.titleEn,
    required this.titleHi,
    required this.prayerEn,
    required this.prayerHi,
    required this.descriptionEn,
    required this.descriptionHi,
  });

  @override
  State<ChalisaScreen> createState() => _ChalisaScreenState();
}

class _ChalisaScreenState extends State<ChalisaScreen> {
  double _fontSizeMultiplier = 1.0;

  // Callback function to handle language change
  void _onLanguageChanged() {
    setState(() {
      // Refresh the UI when language changes
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final locale = Localizations.localeOf(context).languageCode;

    // Select content based on locale
    final title = locale == 'en' ? widget.titleEn : widget.titleHi;
    final prayer = locale == 'en' ? widget.prayerEn : widget.prayerHi;
    // Optionally use description
    final description =
        locale == 'en' ? widget.descriptionEn : widget.descriptionHi;

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_fontSizeMultiplier)),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('home'),
                      style: FTextStyle.homeText,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LanguageDropdown(onLanguageChanged: _onLanguageChanged),
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
                          width: screenWidth * 0.9,
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
                                child: Image.network(
                                  widget.image,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        context,
                                        error,
                                        stackTrace,
                                      ) => Image.asset(
                                        'assets/images/hanuman_placeholder.png',
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(title, style: FTextStyle.boldText),
                              const SizedBox(height: 10),
                              Text(
                                prayer,
                                style: FTextStyle.defaultText,
                                textAlign: TextAlign.center,
                              ),
                              // Optionally display description
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  description,
                                  style: FTextStyle.defaultText,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
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
