import 'package:gita_gpt/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:gita_gpt/Utils/app_imports.dart';

class AskAnythingScreen extends StatefulWidget {
  const AskAnythingScreen({super.key});

  @override
  State<AskAnythingScreen> createState() => _AskAnythingScreenState();
}

class _AskAnythingScreenState extends State<AskAnythingScreen> {
  final TextEditingController askAnythingController = TextEditingController();
  bool isLoading= false;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(CreateSessionEvent(language: PrefUtils.getLanguage()));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> geetaList = List.generate(
      4,
      (index) => {
        'title': AppLocalizations.of(context)!.translate('bhagwatGeeta'),
        'subtitle': AppLocalizations.of(context)!.translate('loremipsumLong'),
        'image': 'assets/images/bhagwatGeeta.png',
      },
    );
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: SafeArea(
          child: BlocListener<HomeFlowBloc, HomeFlowState>(
  listener: (context, state) {
    if (state is InitiateChatLoading)
    {
      setState(() {
        isLoading = true;
      });
    }
    else if (state is InitiateChatSuccess) {
      setState(() {
        isLoading = false;
      });
      final response = state.successResponse;
      final ChatID = response['id'];
      PrefUtils.setChatID(ChatID);
      // Navigate to GPTScreen with the search query
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => BlocProvider(
            create: (context) => HomeFlowBloc(),
            child: GptScreen(
              searchQueryFromAskAnythingScreen:
              askAnythingController.text.trim(),
            ),
          ),
        ),
      );
    }
    else if (state is InitiateChatFailure) {
      setState(() {
        isLoading = false;
      });
      CommonUtils.showErrorToast(
        state.failureResponse['message'],
      );
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
                            ClipOval(
                              child: Image.asset(
                                'assets/images/bhagwatGeeta.png',
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
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
                                    padding: const EdgeInsets.only(right: 80),
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
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 35,
                                          width: 35,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.gradientStart,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
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
                                                final query = askAnythingController.text.trim();

                                                if (query.isEmpty || query.length < 3) {
                                                  CommonUtils.showErrorToast(
                                                    AppLocalizations.of(context)!.translate('shortQuestionError'),
                                                  );
                                                  return;
                                                }

                                                final existingChatId = PrefUtils.getChatID();

                                                if (existingChatId.isNotEmpty) {
                                                  // 🔁 Navigate directly to GPTScreen with existing chat ID
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => GptScreen(searchQueryFromAskAnythingScreen: askAnythingController.text.trim())
                                                    ),
                                                  );
                                                  return;
                                                }

                                                // ✅ No existing chat – trigger API
                                                BlocProvider.of<HomeFlowBloc>(context).add(
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
                                              }


                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // GRID VIEW for cards
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: geetaList.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemBuilder: (context, index) {
                                return Container(
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
                                        geetaList[index]['subtitle']!,
                                        style: FTextStyle.defaultText,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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
