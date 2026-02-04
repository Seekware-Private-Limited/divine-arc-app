import 'package:divine_arc/Utils/app_imports.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  final TextEditingController askAnythingController = TextEditingController();
  bool isLoading = false;
  bool isTrendingQuestionsLoading = false;
  bool commonserverfailure = false;

  // Changed to List<Map<String, dynamic>> for better type safety
  List<Map<String, dynamic>> geetaList = [];

  @override
  void initState() {
    super.initState();
    askAnythingController.clear();

    // Add dummy data immediately (will be replaced when real data arrives)
    _setDummyTrendingQuestions();

    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(CreateSessionEvent(language: PrefUtils.getLanguage()));
    BlocProvider.of<HomeFlowBloc>(context).add(FetchAllTrendingQuestionEvent());
  }

  void _setDummyTrendingQuestions() {
    geetaList = [
      {
        "id": "dummy1",
        "title": "Why did Lord Krishna deliver the Geeta on the battlefield?",
        "hindi_title":
            "भगवान श्रीकृष्ण ने गीता का उपदेश युद्धभूमि पर क्यों दिया?",
        "image": "https://gitagpt-prod.s3.ap-south-1.amazonaws.com/swastik.png",
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z",
      },
      {
        "id": "dummy2",
        "title": "What is the core message of the Bhagavad Gita?",
        "hindi_title": "भगवद गीता का मुख्य संदेश क्या है?",
        "image": "https://gitagpt-prod.s3.ap-south-1.amazonaws.com/swastik.png",
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z",
      },
      {
        "id": "dummy3",
        "title": "How does Karma Yoga help in daily life?",
        "hindi_title": "कर्म योग दैनिक जीवन में कैसे मदद करता है?",
        "image": "https://gitagpt-prod.s3.ap-south-1.amazonaws.com/swastik.png",
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z",
      },
      {
        "id": "dummy4",
        "title": "What is the importance of Bhakti Yoga in the Gita?",
        "hindi_title": "गीता में भक्ति योग का क्या महत्व है?",
        "image": "https://gitagpt-prod.s3.ap-south-1.amazonaws.com/swastik.png",
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z",
      },
    ];
  }

  @override
  void dispose() {
    askAnythingController.clear();
    askAnythingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: Scaffold(
          backgroundColor: AppColors.GlobalBG,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bgGitaGPT.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: BlocListener<HomeFlowBloc, HomeFlowState>(
                  listener: (context, state) {
                    if (state is InitiateChatLoading) {
                      if (mounted) setState(() => isLoading = true);
                    } else if (state is InitiateChatSuccess) {
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                          commonserverfailure = false;
                        });
                      }
                      final response = state.successResponse;
                      final chatId = response['id'];
                      PrefUtils.setstoredChatID(chatId);
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
                      if (mounted) setState(() => isLoading = false);
                      CommonUtils.showErrorToast(
                        state.failureResponse['message'],
                      );
                    } else if (state is TrendingQuestionsLoading) {
                      if (mounted) {
                        setState(() => isTrendingQuestionsLoading = true);
                      }
                    } else if (state is TrendingQuestionsLoaded) {
                      if (mounted) {
                        setState(() {
                          isTrendingQuestionsLoading = true;
                          geetaList = List<Map<String, dynamic>>.from(
                            (state.successResponse['data'] ?? []),
                          );
                        });
                      }
                    } else if (state is TrendingQuestionsFailure) {
                      if (mounted) {
                        setState(() => isTrendingQuestionsLoading = false);
                      }
                      CommonUtils.showErrorToast(
                        state.failureResponse['message'],
                      );
                    } else if (state is SessionExpiredStateHome) {
                      if (mounted) setState(() => isLoading = false);

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          content: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFFC7902), Color(0xFFC62E00)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    PrefUtils.clearAll();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (state is CheckNetworkConnectionHomeFlow) {
                      if (mounted) setState(() => isLoading = false);
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
                  child: Padding(
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
                                onTap: () => Navigator.of(context).pop(),
                                child: const Icon(
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

                                // Input field
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
                                        padding: const EdgeInsets.only(
                                          right: 60,
                                        ),
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
                                                  PrefUtils.getstoredChatID();

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
                                                  isGuest:
                                                      PrefUtils.getIsGuest(),
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

                                // Trending Questions Section
                                if (isTrendingQuestionsLoading)
                                  Center(
                                    child: Container(
                                      width: double.infinity,
                                      height: 300,
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child:
                                            LoadingAnimationWidget.staggeredDotsWave(
                                              color: AppColors.gradientStart,
                                              size: 50,
                                            ),
                                      ),
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: geetaList.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.85,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemBuilder: (context, index) {
                                      final item = geetaList[index];

                                      final String question;
                                      final languageCode =
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode;

                                      if (languageCode == 'hi') {
                                        question =
                                            item['hindi_title']?.toString() ??
                                            item['title']?.toString() ??
                                            'Question not available';
                                      } else {
                                        question =
                                            item['title']?.toString() ??
                                            item['hindi_title']?.toString() ??
                                            'Question not available';
                                      }

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              askAnythingController.text =
                                                  question;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.GlobalBG,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.network(
                                                item['image']?.toString() ??
                                                    'https://gitagpt-prod.s3.ap-south-1.amazonaws.com/swastik.png',
                                                height: 30,
                                                width: 30,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Image.asset(
                                                    'assets/images/swastik.png',
                                                    height: 30,
                                                    width: 30,
                                                  );
                                                },
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
