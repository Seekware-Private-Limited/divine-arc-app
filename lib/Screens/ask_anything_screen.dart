import 'package:divine_arc/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'dart:developer' as developer;

class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  final TextEditingController askAnythingController = TextEditingController();
  bool isLoading = false;

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
    // 🧹 Clear input on exit to maintain clean state
    askAnythingController.clear();
    askAnythingController.dispose();
    developer.log('Disposing AskAnythingScreen', name: 'DISPOSE');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Top 4 Trending Bhagavad Geeta Questions — Multilingual Support
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
                  setState(() => isLoading = false);
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
                if (mounted) {
                  setState(() => isLoading = false);
                }
                CommonUtils.showErrorToast(state.failureResponse['message']);
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
                        Stack(
                          children: [
                            Center(
                              child: Text(
                                AppLocalizations.of(context)!.translate('home'),
                                style: FTextStyle.homeText,
                              ),
                            ),
                            const Positioned(
                              right: 0,
                              top: 5,
                              child: LanguageDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 🪔 Main Card
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
                                    'assets/images/GitaGPTAppIcon.png',
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
                              // 📝 Input Section
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
                              // 🔸 Trending Question Grid
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
