import 'package:gita_gpt/Utils/app_imports.dart';

class GetSingleChatConversationHistory extends StatefulWidget {
  final String chatId;
  const GetSingleChatConversationHistory({super.key, required this.chatId});

  @override
  State<GetSingleChatConversationHistory> createState() => _GetSingleChatConversationHistoryState();
}

class _GetSingleChatConversationHistoryState extends State<GetSingleChatConversationHistory> {
  bool isLoading = false;
  String question = '';
  List<dynamic> messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetSingleChatHistoryEvent(chatId: widget.chatId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.GlobalBG,
      body: SafeArea(
        child: BlocListener<HomeFlowBloc, HomeFlowState>(
          listener: (context, state) {
            if (state is GetSingleChatHistoryLoading) {
              setState(() {
                isLoading = true;
              });
            } else if (state is GetSingleChatHistorySuccess) {
              setState(() {
                isLoading = false;
                final response = state.successResponse;
                messages = response['messages'] ?? [];
                question = response['chat']?['question'] ?? ''; // Store initial question if needed
              });
            } else if (state is GetSingleChatHistoryFailure) {
              setState(() {
                isLoading = false;
              });
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
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
                    const SizedBox(height: 30),
                    Expanded(
                      child: isLoading
                          ? Center(
                        child:
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: AppColors.gradientStart,
                          size: 50,
                        ),
                      )
                          : messages.isEmpty
                          ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate('noMessages'),
                          style: FTextStyle.defaultText,
                        ),
                      )
                          : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gradientStart),
                          color: Colors.white,
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final question = message['message'] ?? '';
                                  // Safely access apiResponses
                                  final answer = (message['apiResponses'] != null &&
                                      message['apiResponses'].isNotEmpty &&
                                      message['apiResponses'][0]['api_response'] != null)
                                      ? message['apiResponses'][0]['api_response']
                                      : 'No response yet';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: AppColors.gradientStart),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              question,
                                              style: FTextStyle.defaultTextBold,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              answer,
                                              style: FTextStyle.defaultText.copyWith(
                                                color: answer == 'No response yet'
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
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