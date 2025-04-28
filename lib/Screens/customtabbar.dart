import '../Utils/app_imports.dart';

class CustomBottomNavBar extends StatefulWidget {
  @override
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

  final List<String> _labels = [
    "Home",
    "Bookmark",
    "History",
    "Profile",
  ];

  final List<Widget> _screens = [
    HomeScreen(),
    BookmarkScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(left: 20,right: 20,bottom: 20,top: 0),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.orangeAccent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_labels.length, (index) {
            bool isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 500),
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 0, vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart,AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(10),
                )
                    : null,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      isSelected ? _selectedImages[index] : _unselectedImages[index],
                      height: 16,
                      width: 16,
                    ),
                    if (isSelected) ...[
                      SizedBox(width: 8),
                      Text(
                        _labels[index],
                        style: FTextStyle.tabbarTextStyle
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
