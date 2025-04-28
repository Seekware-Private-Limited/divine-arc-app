import 'package:flutter/material.dart';
import 'package:gita_gpt/Utils/flutter_color_themes.dart';
import 'package:gita_gpt/Utils/flutter_font_style.dart';
class GptScreen extends StatefulWidget {
  const GptScreen({super.key});

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen> {
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

  void _showFeedbackPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.gradientStart),
            borderRadius: BorderRadius.circular(10),
          ),
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/thumbsupunlike.png', height: 20, width: 20, color: Colors.black),
                      const SizedBox(width: 10),
                      Image.asset('assets/images/thumbsdownunlike.png', height: 20, width: 20, color: Colors.black),
                      SizedBox(width: 16),
                      Text('Feedback', style: FTextStyle.boldText.copyWith(color: Colors.black)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Divider(),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    style: FTextStyle.defaultText,
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback here...',
                      hintStyle: FTextStyle.defaultText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 4,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 45,
                  width: double.infinity,
                  child: Center(child: Text('Submit', style: FTextStyle.buttonText)),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                        Row(
                          children: [
                            Expanded(child: Text('Lorem ipsum dolor sit amet, con sectetur, seo eut enim?',style: FTextStyle.defaultText)),
                           SizedBox(width: 16),
                           Image.asset('assets/images/edit.png',height: 20,width: 20)
                          ],
                        ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Image.asset('assets/images/infinite.png',height: 20,width: 20),
                          SizedBox(width: 10),
                          Text('Answer',style: FTextStyle.answerText,)
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',style: FTextStyle.defaultText),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/images/refresh.png',height: 16,width: 16),
                              SizedBox(width: 10),
                              Text('Regenerate',style: FTextStyle.selectedRadioColorText),
                            ],
                          ),
                          Row(
                            children: [
                              Image.asset('assets/images/thumbsupunlike.png',height: 20,width: 20),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  _showFeedbackPopup(context);
                                },
                                  child: Image.asset('assets/images/thumbsdownunlike.png',height: 20,width: 20)),
                              const SizedBox(width: 10),
                              Image.asset('assets/images/unsave.png',height: 20,width: 20),
                              const SizedBox(width: 10),
                              Image.asset('assets/images/unbookmark.png',height: 16,width: 16),
                              const SizedBox(width: 10),
                              Image.asset('assets/images/unshare.png',height: 20,width: 20),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Image.asset('assets/images/Edit.png',height: 17,width: 17),
                          const SizedBox(width: 10),
                          Text('Related Searches',style: FTextStyle.defaultTextBold),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Breaking news Israel attacks Iran',style: FTextStyle.defaultText),
                                Icon(Icons.add,size: 24),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
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
                                minLines: 1,
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
                      )

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
