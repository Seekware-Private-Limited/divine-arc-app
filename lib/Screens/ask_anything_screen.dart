import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  final TextEditingController askAnythingController = TextEditingController();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool isLoading = false;
  bool isTrendingQuestionsLoading = false;
  bool commonserverfailure = false;

  List<Map<String, dynamic>> trendingQuestions = [];

  @override
  void initState() {
    super.initState();
    _initialize();
    askAnythingController.clear();

    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(CreateSessionEvent(language: PrefUtils.getLanguage()));
    BlocProvider.of<HomeFlowBloc>(context).add(FetchAllTrendingQuestionEvent());
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnAskAnythingScreen');
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
                          isTrendingQuestionsLoading = false;
                          trendingQuestions = List<Map<String, dynamic>>.from(
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
                      setState(() {
                        isLoading = false;
                      });

                      SessionExpiredSnackBar.show(
                        context: context,
                        message: state.message,
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
                                          maxLines: 3,
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
                                                Navigator.pushReplacement(
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

                                if (isTrendingQuestionsLoading)
                                  Center(
                                    child: Container(
                                      width: double.infinity,
                                      height: 340,
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
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: trendingQuestions.length,
                                    itemBuilder: (context, index) {
                                      final item = trendingQuestions[index];
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
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                askAnythingController.text =
                                                    question;
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.GlobalBG,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
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
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    question,
                                                    style:
                                                        FTextStyle.defaultText,
                                                  ),
                                                ),
                                              ],
                                            ),
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
