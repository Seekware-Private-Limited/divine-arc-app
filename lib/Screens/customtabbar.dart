import 'package:divine_arc/Utils/custompopup.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class CustomBottomNavBar extends StatefulWidget {
  const CustomBottomNavBar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 0;

  final List<String> _selectedImages = [
    'assets/images/homeSelected.svg',
    'assets/images/bookmarkSelected.svg',
    'assets/images/historySelected.svg',
    'assets/images/profileSelected.svg',
  ];

  final List<String> _unselectedImages = [
    'assets/images/homeUnselected.svg',
    'assets/images/bookmarkUnselected.svg',
    'assets/images/historyUnselected.svg',
    'assets/images/profileUnselected.svg',
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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          extendBody: true,
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            margin: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20,
              top: 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (index) {
                final bool isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 20 : 0,
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
                              borderRadius: BorderRadius.circular(10),
                            )
                            : null,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          isSelected
                              ? _selectedImages[index]
                              : _unselectedImages[index],
                          height: 16,
                          width: 16,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            labels[index],
                            style: FTextStyle.tabbarTextStyle,
                          ),
                        ],
                      ],
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
