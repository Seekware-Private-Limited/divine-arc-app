import 'package:gita_gpt/Utils/app_imports.dart';

class GptScreen extends StatefulWidget {
  const GptScreen({super.key});

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen> {
  List<bool> _isExpandedList = List.generate(4, (index) => false);
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
                      Image.asset(
                        'assets/images/thumbsupunlike.png',
                        height: 20,
                        width: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/thumbsdownunlike.png',
                        height: 20,
                        width: 20,
                        color: Colors.black,
                      ),
                      SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('feedback'),
                        style: FTextStyle.boldText.copyWith(
                          color: Colors.black,
                        ),
                      ),
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
            width:
                MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    style: FTextStyle.defaultText,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.translate('enterFeedbackHere'),
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
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('submit'),
                      style: FTextStyle.buttonText,
                    ),
                  ),
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
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
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
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate('home'),
                          style: FTextStyle.homeText,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 5,
                        child: const LanguageDropdown(),
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
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('loremQuestion'),
                                style: FTextStyle.defaultText,
                              ),
                            ),
                            SizedBox(width: 16),
                            Image.asset(
                              'assets/images/edit.png',
                              height: 20,
                              width: 20,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/infinite.png',
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.translate('answer'),
                              style: FTextStyle.answerText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.translate('loremAnswer'),
                          style: FTextStyle.defaultText,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/refresh.png',
                                  height: 16,
                                  width: 16,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('regenerate'),
                                  style: FTextStyle.selectedRadioColorText,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/thumbsupunlike.png',
                                  height: 20,
                                  width: 20,
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    _showFeedbackPopup(context);
                                  },
                                  child: Image.asset(
                                    'assets/images/thumbsdownunlike.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Image.asset(
                                  'assets/images/unsave.png',
                                  height: 20,
                                  width: 20,
                                ),
                                const SizedBox(width: 10),
                                Image.asset(
                                  'assets/images/unbookmark.png',
                                  height: 16,
                                  width: 16,
                                ),
                                const SizedBox(width: 10),
                                Image.asset(
                                  'assets/images/unshare.png',
                                  height: 20,
                                  width: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/Edit.png',
                              height: 17,
                              width: 17,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.translate('relatedSearches'),
                              style: FTextStyle.defaultTextBold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('suggestions'),
                                        style: FTextStyle.defaultText,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isExpandedList[index]
                                              ? Icons.remove
                                              : Icons.add,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isExpandedList[index] =
                                                !_isExpandedList[index];
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isExpandedList[index])
                                  Text(
                                    AppLocalizations.of(context)!.translate('dummyText'),
                                    style: FTextStyle.defaultText,
                                  ),
                              ],
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
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.translate('askAnything'),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
