import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<dynamic> allBookmarksChat = [];
  bool isLoading = false;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnBookmarkScreen');
    if (!mounted) return;
    context.read<HomeFlowBloc>().add(GetAllBookmarksChat());
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
              child: BlocListener<HomeFlowBloc, HomeFlowState>(
                listener: (context, state) {
                  if (state is GetAllBookmarksChatLoading) {
                    setState(() => isLoading = true);
                  } else if (state is GetAllBookmarksChatSuccess) {
                    setState(() {
                      isLoading = false;
                      allBookmarksChat = state.successResponse;
                    });
                  } else if (state is GetAllBookmarksChatFailure) {
                    setState(() => isLoading = false);
                    CommonUtils.showErrorToast(
                      state.failureResponse['message'],
                    );
                  }
                  /// ✅ FIXED UNBOOKMARK SUCCESS
                  else if (state is UnbookmarkChatSuccess) {
                    final messageId = state.successResponse['data']['id'];

                    setState(() {
                      allBookmarksChat.removeWhere(
                        (chat) => chat['id'] == messageId,
                      );
                    });

                    /// Update PrefUtils
                    List<Map<String, dynamic>> chatHistory =
                        PrefUtils.getChatHistory();

                    final index = chatHistory.indexWhere(
                      (chat) => chat['messageId'] == messageId,
                    );

                    if (index != -1) {
                      chatHistory[index]['is_bookmarked'] = false;
                      PrefUtils.setChatHistory(chatHistory);
                    }

                    CommonUtils.showSuccessToast(
                      'Bookmark removed successfully!',
                    );
                  } else if (state is UnbookmarkChatFailure) {
                    setState(() => isLoading = false);
                    CommonUtils.showErrorToast(
                      state.failureResponse['message'],
                    );
                  } else if (state is SessionExpiredStateHome) {
                    setState(() => isLoading = false);

                    SessionExpiredSnackBar.show(
                      context: context,
                      message: state.message,
                    );
                  } else if (state is CheckNetworkConnectionHomeFlow) {
                    setState(() => isLoading = false);
                  }
                },

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('bookmark'),
                            style: FTextStyle.homeText,
                          ),
                          const LanguageDropdown(),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child:
                            isLoading
                                ? Center(
                                  child:
                                      LoadingAnimationWidget.staggeredDotsWave(
                                        color: AppColors.gradientStart,
                                        size: 50,
                                      ),
                                )
                                : allBookmarksChat.isEmpty
                                ? _buildEmptyState(context)
                                : _buildBookmarksList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(150),
            child: Image.asset(
              'assets/images/errorImage.png',
              height: 250,
              width: 250,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.translate('noBookmarks'),
            textAlign: TextAlign.center,
            style: FTextStyle.defaultTextBold,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gradientStart, width: 1.5),
        color: Colors.white,
      ),
      child: ListView.builder(
        itemCount: allBookmarksChat.length,
        itemBuilder: (context, index) {
          final chat = allBookmarksChat[index];

          final question = chat['message'] ?? '';

          final answer =
              (chat['apiResponses'] != null && chat['apiResponses'].isNotEmpty)
                  ? chat['apiResponses'][0]['api_response'] ?? ''
                  : '';

          final messageId = chat['id'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.GlobalBG,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey(messageId),

                  iconColor: AppColors.gradientStart,
                  collapsedIconColor: AppColors.gradientStart,

                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: FTextStyle.defaultTextBold,
                        ),
                      ),
                      const SizedBox(width: 16),

                      GestureDetector(
                        onTap: () {
                          if (messageId.isNotEmpty) {
                            BlocProvider.of<HomeFlowBloc>(
                              context,
                            ).add(UnbookmarkChat(messageId: messageId));
                          } else {
                            CommonUtils.showErrorToast('Message ID missing');
                          }
                        },
                        child: Image.asset(
                          'assets/images/bookmark.png',
                          height: 18,
                          width: 18,
                        ),
                      ),
                    ],
                  ),

                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(
                        data: answer,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ).copyWith(p: FTextStyle.defaultText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
