import 'package:divine_arc/Utils/app_imports.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = false;
  List<Map<String, dynamic>> allChatHistory = [];

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetChatHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('history'),
                          style: FTextStyle.homeText,
                        ),
                        const LanguageDropdown(),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Scrollable List
                    BlocListener<HomeFlowBloc, HomeFlowState>(
                      listener: (context, state) {
                        if (state is GetChatHistoryLoading) {
                          setState(() {
                            isLoading = true;
                          });
                        } else if (state is GetChatHistorySuccess) {
                          final chats = state.successResponse['chats'] as List;
                          setState(() {
                            isLoading = false;
                            allChatHistory =
                                chats
                                    .map<Map<String, dynamic>>(
                                      (item) => item as Map<String, dynamic>,
                                    )
                                    .toList();
                          });
                        } else if (state is GetChatHistoryFailure) {
                          setState(() {
                            isLoading = false;
                          });
                          CommonUtils.showErrorToast(
                            state.failureResponse['message'],
                          );
                        } else if (state is CheckNetworkConnectionHomeFlow) {
                          setState(() {
                            isLoading = false;
                          });
                        } else if (state is SessionExpiredStateHome) {
                          setState(() {
                            isLoading = false;
                          });

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
                                    colors: [
                                      Color(0xFFFC7902), // gradientStart
                                      Color(0xFFC62E00), // gradientEnd
                                    ],
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
                                                (context) =>
                                                    const LoginScreen(),
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
                        }
                      },
                      child: Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.gradientStart,
                              width: 1.5,
                            ),
                            color: Colors.white,
                          ),
                          child:
                              isLoading
                                  ? Center(
                                    child:
                                        LoadingAnimationWidget.staggeredDotsWave(
                                          color: AppColors.gradientStart,
                                          size: 50,
                                        ),
                                  )
                                  : allChatHistory.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ClipOval(
                                          child: Image.asset(
                                            'assets/images/errorImage.png', // Replace with your image path
                                            height: 200,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.translate('noChatHistory'),
                                          style: FTextStyle.defaultTextBold,
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: allChatHistory.length,
                                    itemBuilder: (context, index) {
                                      final chat = allChatHistory[index];
                                      final ChatID = chat['id'];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => GptScreen(
                                                      chatId: ChatID,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: AppColors.GlobalBG,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              chat['question'] ?? 'No question',
                                              style: FTextStyle.defaultText,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
