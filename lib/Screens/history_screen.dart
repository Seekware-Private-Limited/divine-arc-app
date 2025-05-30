import 'package:gita_gpt/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:gita_gpt/Utils/common_utils.dart';

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
        body: SafeArea(
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
                                          'No Chat history found',
                                          style: FTextStyle.defaultTextBold,
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: allChatHistory.length,
                                    itemBuilder: (context, index) {
                                      final chat = allChatHistory[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppColors.GlobalBG,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            chat['question'] ?? 'No question',
                                            style: FTextStyle.defaultText,
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
            ],
          ),
        ),
      ),
    );
  }
}
