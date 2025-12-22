import 'package:divine_arc/Utils/app_imports.dart';

class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  final TextEditingController askAnythingController = TextEditingController();
  bool isLoading = false;
  bool commonserverfailure = false;

  @override
  void initState() {
    super.initState();
    askAnythingController.clear();
    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(CreateSessionEvent(language: PrefUtils.getLanguage()));
  }

  @override
  void dispose() {
    askAnythingController.clear();
    askAnythingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> geetaList = [
      {
        'en': 'What is the core message of the Bhagavad Geeta?',
        'hi': 'भगवद गीता का मुख्य संदेश क्या है?',
      },
      {
        'en': 'Why did Lord Krishna deliver the Geeta on the battlefield?',
        'hi': 'भगवान श्रीकृष्ण ने गीता का उपदेश युद्धभूमि पर क्यों दिया?',
      },
      {
        'en': 'How can the Geeta help in modern daily life?',
        'hi': 'गीता आधुनिक दैनिक जीवन में कैसे सहायक हो सकती है?',
      },
      {
        'en': 'What is the significance of Karma Yoga in the Geeta?',
        'hi': 'गीता में कर्म योग का क्या महत्व है?',
      },
    ];

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: SafeArea(
          child: BlocListener<HomeFlowBloc, HomeFlowState>(
            listener: (context, state) {
              if (state is InitiateChatLoading) {
                if (mounted) {
                  setState(() => isLoading = true);
                }
              } else if (state is InitiateChatSuccess) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                    commonserverfailure = false;
                  });
                }
                final response = state.successResponse;
                final chatId = response['id'];
                PrefUtils.setChatID(chatId);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GptScreen(
                          searchQueryFromAskAnythingScreen:
                              askAnythingController.text.trim(),
                        ),
                  ),
                );
              } else if (state is InitiateChatFailure) {
                print('Chat failure: ${state.failureResponse}');
                if (mounted) {
                  setState(() => isLoading = false);
                }
                CommonUtils.showErrorToast(state.failureResponse['message']);
              } else if (state is SessionExpiredStateHome) {
                CommonUtils.showErrorToast(state.message);
                PrefUtils.clearAll();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else if (state is CheckNetworkConnectionHomeFlow) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              } else if (state is CommonServerFailureHome) {
                print('Server failure detected');
                if (mounted) {
                  setState(() {
                    isLoading = false;
                    commonserverfailure = true;
                  });
                }
              }
            },
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            const LanguageDropdown(),
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
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/DivineArcLogo.png',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.translate('bhagwatGeeta'),
                                style: FTextStyle.boldText,
                              ),
                              const SizedBox(height: 16),
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
                                      padding: const EdgeInsets.only(right: 60),
                                      child: TextFormField(
                                        controller: askAnythingController,
                                        style: FTextStyle.defaultText,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(
                                            context,
                                          )!.translate('askAnything'),
                                          hintStyle: FTextStyle.defaultText,
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                        ),
                                        maxLines: 5,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
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
                                            final query =
                                                askAnythingController.text
                                                    .trim();

                                            if (query.isEmpty ||
                                                query.length < 3) {
                                              CommonUtils.showErrorToast(
                                                AppLocalizations.of(
                                                  context,
                                                )!.translate(
                                                  'shortQuestionError',
                                                ),
                                              );
                                              return;
                                            }

                                            if (commonserverfailure) {
                                              CommonUtils.showErrorToast(
                                                'Something went wrong. Please try again later.',
                                              );
                                              return;
                                            }

                                            final existingChatId =
                                                PrefUtils.getChatID();

                                            if (existingChatId.isNotEmpty) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => GptScreen(
                                                        searchQueryFromAskAnythingScreen:
                                                            query,
                                                      ),
                                                ),
                                              );
                                              return;
                                            }

                                            BlocProvider.of<HomeFlowBloc>(
                                              context,
                                            ).add(
                                              InitiateChatEvent(
                                                message: query,
                                                isGuest: PrefUtils.getIsGuest(),
                                                modelName: 'Atlas',
                                                searchEngine: 'Search',
                                                edited: false,
                                                sender: 'user',
                                                chatId: '',
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: geetaList.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.85,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemBuilder: (context, index) {
                                  final languageCode =
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode;
                                  final question =
                                      geetaList[index][languageCode] ??
                                      geetaList[index]['en']!;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          askAnythingController.text = question;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.GlobalBG,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Image.asset(
                                            'assets/images/swastik.png',
                                            height: 30,
                                            width: 30,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            question,
                                            style: FTextStyle.defaultText,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator()),
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
