import 'package:flutter/material.dart';
import 'package:gita_gpt/Utils/flutter_color_themes.dart';
import 'package:gita_gpt/Utils/flutter_font_style.dart';
import 'package:gita_gpt/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class LanguageDropdown extends StatefulWidget {
  const LanguageDropdown({super.key});

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();

  final List<String> _languages = ['English', 'Hindi'];
  final Map<String, String> _languageToCode = {'English': 'en', 'Hindi': 'hi'};
  final Map<String, String> _codeToLanguage = {'en': 'English', 'hi': 'Hindi'};

  String _getDisplayLanguage(String? code) =>
      _codeToLanguage[code] ?? 'English';

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
        ..._languages.map(
              (lang) => PopupMenuItem<String>(
            value: lang,
            child: Consumer<LanguageProvider>(
              builder: (context, provider, child) {
                final selectedLanguage =
                _getDisplayLanguage(provider.locale.languageCode);
                return Row(
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
                );
              },
            ),
          ),
        ),
      ],
      elevation: 8,
      color: Colors.white,
    );

    if (selected != null) {
      final languageCode = _languageToCode[selected] ?? 'en';
      Provider.of<LanguageProvider>(context, listen: false)
          .changeLanguage(languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        final selectedLanguage =
        _getDisplayLanguage(provider.locale.languageCode);

        return GestureDetector(
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
        );
      },
    );
  }
}
