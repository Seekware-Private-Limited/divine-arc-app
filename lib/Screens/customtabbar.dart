import 'package:divine_arc/Utils/custompopup.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 0;

  final List<IconData> _icons = [
    LucideIcons.house500,
    LucideIcons.bookmark500,
    LucideIcons.history500,
    LucideIcons.user500,
  ];

  final List<Widget> _screens = [
    HomeScreen(),
    BookmarkScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  /// Handle back press and show exit confirmation
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => CustomPopup(
            title: "Confirm Exit",
            content: "Are you sure you want to exit the app?",
            onConfirm: () {
              Navigator.of(context).pop(true);
              if (Platform.isAndroid) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            },
            onCancel: () => Navigator.of(context).pop(false),
          ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double safeBottom = mediaQuery.padding.bottom;
    final List<String> labels = [
      AppLocalizations.of(context)!.translate('home'),
      AppLocalizations.of(context)!.translate('bookmark'),
      AppLocalizations.of(context)!.translate('history'),
      AppLocalizations.of(context)!.translate('profile'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _onWillPop();
        if (shouldExit) {
          Navigator.of(context).pop();
        }
      },
      child: MediaQuery(
        data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          extendBody: true,
          body: _screens[_selectedIndex],

          bottomNavigationBar: Container(
            margin: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              Platform.isAndroid ? 20 + safeBottom : safeBottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gradientStart.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gradientStart.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (index) {
                final bool isSelected = _selectedIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    if (_selectedIndex == index) return;

                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: SizedBox(
                    height: 55,
                    width: isSelected ? null : 60,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 10 : 0,
                          vertical: 10,
                        ),
                        decoration:
                            isSelected
                                ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gradientStart,
                                      AppColors.gradientEnd,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gradientStart.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                )
                                : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icons[index],
                              size: 20,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.gradientStart,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Text(
                                labels[index],
                                style: FTextStyle.tabbarTextStyle1.copyWith(
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
