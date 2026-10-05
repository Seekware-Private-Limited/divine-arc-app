import 'package:divine_arc/Utils/app_imports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LanguageDropdown extends StatefulWidget {
  final ValueChanged<String>? onLanguageChanged;

  const LanguageDropdown({super.key, this.onLanguageChanged});

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();

  final List<String> _languages = ['English', 'हिन्दी'];
  final Map<String, String> _languageToCode = {'English': 'en', 'हिन्दी': 'hi'};
  final Map<String, String> _codeToLanguage = {'en': 'English', 'hi': 'हिन्दी'};

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
        offset.dy + size.height + 6,
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.gradientStart.withValues(alpha: 0.15),
        ),
      ),
      constraints: const BoxConstraints(minWidth: 170),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              'Language',
              style: FTextStyle.socialloginbuttonText.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.grey[500],
              ),
            ),
          ),
        ),
        ..._languages.map(
          (lang) => PopupMenuItem<String>(
            value: lang,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Consumer<LanguageProvider>(
              builder: (context, provider, child) {
                final selectedLanguage = _getDisplayLanguage(
                  provider.locale.languageCode,
                );
                final bool isSelected = selectedLanguage == lang;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.gradientStart.withValues(alpha: 0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang,
                        style:
                            isSelected
                                ? FTextStyle.selectedRadioColorText
                                : FTextStyle.socialloginbuttonText,
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check500,
                          size: 18,
                          color: AppColors.gradientStart,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
      elevation: 6,
      color: Colors.white,
    );

    if (selected != null) {
      final languageCode = _languageToCode[selected] ?? 'en';
      Provider.of<LanguageProvider>(
        context,
        listen: false,
      ).changeLanguage(languageCode);
      PrefUtils.setLanguage(languageCode);
      BlocProvider.of<HomeFlowBloc>(
        context,
      ).add(CreateSessionEvent(language: languageCode));

      widget.onLanguageChanged?.call(languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        final selectedLanguage = _getDisplayLanguage(
          provider.locale.languageCode,
        );

        return BlocListener<HomeFlowBloc, HomeFlowState>(
          listener: (context, state) {
            if (state is CreateSessionSuccess) {
              final response = state.successResponse;
              final sessionID = response['session_id'];
              PrefUtils.setSessionID(sessionID);
            } else if (state is CreateSessionFailure) {
              CommonUtils.showErrorToast(state.error);
            } else if (state is CheckNetworkConnectionHomeFlow) {
              CommonUtils.showErrorToast(
                AppLocalizations.of(context)!.translate('nointernetConnection'),
              );
            } else if (state is CommonServerFailureHome) {
              CommonUtils.showErrorToast(state.error);
            }
          },
          child: Material(
            key: _dropdownKey,
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCustomDropdown(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gradientStart.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientStart.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.globe500,
                      size: 16,
                      color: AppColors.gradientStart,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedLanguage,
                      style: FTextStyle.socialloginbuttonText,
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.chevronDown500,
                      size: 16,
                      color: Colors.grey[500],
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
