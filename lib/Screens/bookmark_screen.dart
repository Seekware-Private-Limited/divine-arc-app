import 'dart:convert';
import 'dart:developer' as developer;

import 'package:divine_arc/Utils/app_imports.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<dynamic> allBookmarksChat = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    print("CHAT HISTORY: ${jsonEncode(PrefUtils.getChatHistory())}");
    BlocProvider.of<HomeFlowBloc>(context).add(GetAllBookmarksChat());
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
          child: BlocListener<HomeFlowBloc, HomeFlowState>(
            listener: (context, state) {
              if (state is GetAllBookmarksChatLoading) {
                setState(() {
                  isLoading = true;
                });
              } else if (state is GetAllBookmarksChatSuccess) {
                setState(() {
                  isLoading = false;
                  allBookmarksChat = state.successResponse;
                });
              } else if (state is GetAllBookmarksChatFailure) {
                setState(() {
                  isLoading = false;
                });
                CommonUtils.showErrorToast(state.failureResponse['message']);
              } else if (state is UnbookmarkChatSuccess) {
                final messageId = state.successResponse['data']['message_id'];
                debugPrint(
                  'UnbookmarkChatSuccess received for messageId: $messageId',
                );

                // Update local bookmarks list
                setState(() {
                  allBookmarksChat.removeWhere(
                    (chat) => chat['message_id'] == messageId,
                  );
                  debugPrint('Updated allBookmarksChat after removal.');
                });

                // Update chatHistory in PrefUtils
                List<Map<String, dynamic>> chatHistory =
                    PrefUtils.getChatHistory();
                debugPrint('Loaded chatHistory from PrefUtils: $chatHistory');

                // Print all messageIds in chatHistory for verification
                for (var chat in chatHistory) {
                  debugPrint('chatHistory messageId: ${chat['messageId']}');
                }

                final index = chatHistory.indexWhere(
                  (chat) => chat['messageId'] == messageId,
                );
                debugPrint('Found index: $index');

                if (index != -1) {
                  chatHistory[index]['isBookmarked'] = false;
                  PrefUtils.setChatHistory(chatHistory);
                  debugPrint('Updated chatHistory in PrefUtils: $chatHistory');
                } else {
                  debugPrint(
                    '❌ No matching messageId found in chatHistory. messageId: $messageId',
                  );
                }

                CommonUtils.showSuccessToast('Bookmark removed successfully!');
              } else if (state is UnbookmarkChatFailure) {
                setState(() {
                  isLoading = false;
                });
                CommonUtils.showErrorToast(state.failureResponse['message']);
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
                                  builder: (context) => const LoginScreen(),
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
                setState(() {
                  isLoading = false;
                });
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
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          150,
                                        ),
                                        child: Image.asset(
                                          'assets/images/errorImage.png',
                                          height: 250,
                                          width: 250,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.translate('noBookmarks'),
                                        textAlign: TextAlign.center,
                                        style: FTextStyle.defaultTextBold,
                                      ),
                                    ],
                                  ),
                                )
                                : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.gradientStart,
                                      width: 1.5,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: ListView.builder(
                                    itemCount: allBookmarksChat.length,
                                    itemBuilder: (context, index) {
                                      final chat = allBookmarksChat[index];
                                      final question = chat['question'] ?? '';
                                      final answer = chat['answer'] ?? '';
                                      final messageId =
                                          chat['message_id'] ?? '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.GlobalBG,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              dividerColor: Colors.transparent,
                                            ),
                                            child: ExpansionTile(
                                              iconColor:
                                                  AppColors.gradientStart,
                                              collapsedIconColor:
                                                  AppColors.gradientStart,
                                              backgroundColor:
                                                  Colors.transparent,
                                              collapsedBackgroundColor:
                                                  Colors.transparent,
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      question,
                                                      style:
                                                          FTextStyle
                                                              .defaultText,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (messageId
                                                          .isNotEmpty) {
                                                        setState(() {
                                                          allBookmarksChat
                                                              .removeAt(index);
                                                        });
                                                        BlocProvider.of<
                                                          HomeFlowBloc
                                                        >(context).add(
                                                          UnbookmarkChat(
                                                            messageId:
                                                                messageId,
                                                          ),
                                                        );
                                                      } else {
                                                        CommonUtils.showErrorToast(
                                                          'Cannot remove bookmark: Message ID is missing',
                                                        );
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
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: MarkdownBody(
                                                    data: answer,
                                                    styleSheet:
                                                        MarkdownStyleSheet.fromTheme(
                                                          Theme.of(context),
                                                        ).copyWith(
                                                          p:
                                                              FTextStyle
                                                                  .defaultText,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
      ),
    );
  }
}
