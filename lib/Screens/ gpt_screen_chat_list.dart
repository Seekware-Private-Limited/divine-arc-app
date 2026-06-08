import 'package:divine_arc/Screens/CustomAudioPlayer.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class GptScreenChatList extends StatelessWidget {
  final String? chatId;
  final List<Map<String, dynamic>> chatHistory;
  final ScrollController scrollController;
  final Map<int, bool> responseLoadingStates;
  final Map<int, String> userAudioUrlMap;
  final Map<int, String> responseAudioUrlMap;
  final int? currentResponseIndex;
  final String? audioPath;
  final String? responseAudioPath;
  final String? apiResponse;
  final bool isRecording;
  final int? currentlyPlayingIndex;
  final String? currentlyPlayingUrl;
  final bool isPlaying;
  final Function(int index, String question) onEdit;
  final Function(int index) onRegenerate;
  final Function(String audioUrl, int index, bool isUserAudio)
  onPlayAudioFromUrl;
  final Function(String filePath, int index) onPlayLocalAudio;
  final Function(String messageId, int index) onLike;
  final Function(String messageId, int index) onDislike;
  final Function(String messageId, int index, bool is_bookmarked) onBookmark;

  const GptScreenChatList({
    super.key,
    required this.chatId,
    required this.chatHistory,
    required this.scrollController,
    required this.responseLoadingStates,
    required this.userAudioUrlMap,
    required this.responseAudioUrlMap,
    required this.currentResponseIndex,
    required this.audioPath,
    required this.responseAudioPath,
    required this.apiResponse,
    required this.isRecording,
    required this.currentlyPlayingIndex,
    required this.currentlyPlayingUrl,
    required this.isPlaying,
    required this.onEdit,
    required this.onRegenerate,
    required this.onPlayAudioFromUrl,
    required this.onPlayLocalAudio,
    required this.onLike,
    required this.onDislike,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: chatHistory.isNotEmpty,
      replacement: Center(
        child: Text(
          AppLocalizations.of(context)!.translate('nochathistory'),
          style: FTextStyle.defaultText.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chatHistory.length,
          itemBuilder: (context, index) {
            return _buildChatItem(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, int index) {
    final question = chatHistory[index]['question']?.toString().trim() ?? '';
    final answer = chatHistory[index]['answer']?.toString().trim() ?? '';
    final messageId = chatHistory[index]['messageId']?.toString().trim() ?? '';
    final bool is_bookmarked = chatHistory[index]['is_bookmarked'] ?? false;
    final bool isLiked = chatHistory[index]['isLiked'] ?? false;
    final bool isDisliked = chatHistory[index]['isDisliked'] ?? false;
    final bool isUserAudio = chatHistory[index]['isUserAudio'] ?? false;
    final bool isLoading = responseLoadingStates[index] ?? false;
    final bool hasAudioUrl = chatHistory[index]['hasAudioUrl'] ?? false;
    final bool hasError = chatHistory[index]['hasError'] ?? false;

    final String userAudioUrl =
        userAudioUrlMap[index] ??
        chatHistory[index]['audio_url']?.toString() ??
        '';

    final String responseAudioUrl =
        responseAudioUrlMap[index] ??
        ((chatHistory[index]['apiResponses'] != null &&
                chatHistory[index]['apiResponses'] is List &&
                (chatHistory[index]['apiResponses'] as List).isNotEmpty)
            ? (chatHistory[index]['apiResponses'] as List)[0]['audio_url']
                    ?.toString() ??
                ''
            : '');

    if (question.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.gradientStart),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionHeader(context, index, question, isUserAudio),
              const SizedBox(height: 16),
              _buildAnswerSection(
                context,
                index,
                answer,
                isLoading,
                hasAudioUrl,
                userAudioUrl,
                responseAudioUrl,
                isUserAudio,
                hasError,
              ),
              const SizedBox(height: 16),
              // Only show action buttons when response is complete and not loading
              if (!isUserAudio &&
                  !isLoading &&
                  (answer.isNotEmpty || messageId.isNotEmpty) &&
                  responseLoadingStates[index] != true &&
                  !hasError)
                _buildActionButtons(
                  context,
                  index,
                  answer,
                  messageId,
                  is_bookmarked,
                  isLiked,
                  isDisliked,
                  question,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionHeader(
    BuildContext context,
    int index,
    String question,
    bool isUserAudio,
  ) {
    return Row(
      children: [
        Expanded(child: Text(question, style: FTextStyle.defaultTextBold)),
        if (!isUserAudio) const SizedBox(width: 16),
        if (!isUserAudio)
          GestureDetector(
            onTap: () => onEdit(index, question),
            child: Image.asset('assets/images/edit.png', height: 16, width: 16),
          ),
      ],
    );
  }

  Widget _buildAnswerSection(
    BuildContext context,
    int index,
    String answer,
    bool isLoading,
    bool hasAudioUrl,
    String userAudioUrl,
    String responseAudioUrl,
    bool isUserAudio,
    bool hasError,
  ) {
    // Check if this is the current response being processed
    final bool isCurrentResponse = index == currentResponseIndex;

    if (responseLoadingStates[index] == true && answer.isEmpty) {
      return Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gradientStart,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            (chatHistory[index]['isRegenerating'] as bool? ?? false)
                ? 'Regenerating...'
                : 'Loading...',
            style: FTextStyle.defaultText.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      );
    } else if (hasError) {
      // Display "No Response Received" for error cases
      return Text(
        AppLocalizations.of(context)!.translate('noresponsereceived'),
        style: FTextStyle.defaultText.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    } else if (answer.isNotEmpty || hasAudioUrl || userAudioUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show text answer if it's not "Audio Response" and not empty
          if (answer.trim().isNotEmpty && answer != 'Audio Response')
            MarkdownBody(
              data: answer,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context),
              ).copyWith(p: FTextStyle.defaultText),
            ),

          // Only show user audio player if this is an audio chat AND has audio URL
          if (isUserAudio && userAudioUrl.isNotEmpty)
            _buildUserAudioPlayer(index, userAudioUrl),

          // Only show response audio if this chat has audio response URL
          if (responseAudioUrl.isNotEmpty)
            _buildResponseAudioPlayer(index, responseAudioUrl),

          // Only show local audio if this is the CURRENT response being processed
          // AND it's an audio chat AND we have a local audio path
          if (isCurrentResponse &&
              isUserAudio &&
              audioPath != null &&
              !isRecording &&
              userAudioUrl.isEmpty)
            _buildLocalUserAudioPlayer(index),

          // Only show local response audio if this is the CURRENT response being processed
          // AND we have a local response audio path
          if (isCurrentResponse &&
              responseAudioPath != null &&
              responseAudioUrl.isEmpty)
            _buildLocalResponseAudioPlayer(index),

          // Only show API response error if this is the CURRENT response
          // AND we have an API response error
          if (isCurrentResponse && apiResponse != null)
            _buildApiResponseError(),
        ],
      );
    } else if (!isLoading && answer.isEmpty && !hasAudioUrl && !isUserAudio) {
      return Text(
        AppLocalizations.of(context)!.translate('noresponsereceived'),
        style: FTextStyle.defaultText.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildUserAudioPlayer(int index, String userAudioUrl) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Your Recording:',
              style: FTextStyle.defaultText.copyWith(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            CustomAudioPlayer(
              audioPath: userAudioUrl,
              isPlaying:
                  currentlyPlayingIndex == index &&
                  currentlyPlayingUrl == userAudioUrl &&
                  isPlaying,
              onPlayPause: () => onPlayAudioFromUrl(userAudioUrl, index, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseAudioPlayer(int index, String responseAudioUrl) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Response:',
              style: FTextStyle.defaultText.copyWith(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            CustomAudioPlayer(
              audioPath: responseAudioUrl,
              isPlaying:
                  currentlyPlayingIndex == index &&
                  currentlyPlayingUrl == responseAudioUrl &&
                  isPlaying,
              onPlayPause:
                  () => onPlayAudioFromUrl(responseAudioUrl, index, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalUserAudioPlayer(int index) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Your Recording:',
            style: FTextStyle.defaultText.copyWith(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          CustomAudioPlayer(
            audioPath: audioPath!,
            isPlaying:
                currentlyPlayingIndex == index &&
                currentlyPlayingUrl == audioPath! &&
                isPlaying,
            onPlayPause: () => onPlayLocalAudio(audioPath!, index),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalResponseAudioPlayer(int index) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Response:',
            style: FTextStyle.defaultText.copyWith(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          CustomAudioPlayer(
            audioPath: responseAudioPath!,
            isPlaying:
                currentlyPlayingIndex == index &&
                currentlyPlayingUrl == responseAudioPath! &&
                isPlaying,
            onPlayPause: () => onPlayLocalAudio(responseAudioPath!, index),
          ),
        ],
      ),
    );
  }

  Widget _buildApiResponseError() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        apiResponse!,
        style: const TextStyle(color: Colors.red),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    int index,
    String answer,
    String messageId,
    bool is_bookmarked,
    bool isLiked,
    bool isDisliked,
    String question,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRegenerateButton(context, index),
        Row(
          children: [
            _buildLikeButton(messageId, isLiked, isDisliked, index),
            const SizedBox(width: 10),
            _buildDislikeButton(messageId, isLiked, isDisliked, index),
            const SizedBox(width: 10),
            _buildCopyButton(context, answer),
            const SizedBox(width: 10),
            _buildBookmarkButton(messageId, is_bookmarked, index),
            const SizedBox(width: 10),
            _buildShareButton(context, index, question, answer),
          ],
        ),
      ],
    );
  }

  Widget _buildRegenerateButton(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onRegenerate(index),
      child: Row(
        children: [
          Image.asset('assets/images/refresh.png', height: 14, width: 14),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.translate('regenerate'),
            style: FTextStyle.selectedRadioColorText,
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(
    String messageId,
    bool isLiked,
    bool isDisliked,
    int index,
  ) {
    return GestureDetector(
      onTap:
          (isLiked || isDisliked)
              ? null
              : () {
                if (messageId.isNotEmpty) {
                  onLike(messageId, index);
                } else {
                  CommonUtils.showErrorToast(
                    'Cannot like: Message ID is missing',
                  );
                }
              },
      child: Opacity(
        opacity: (isLiked || isDisliked) ? 0.5 : 1.0,
        child: Image.asset(
          isLiked
              ? 'assets/images/thumbsuplike.png'
              : 'assets/images/thumbsupunlike.png',
          height: 16,
          width: 16,
        ),
      ),
    );
  }

  Widget _buildDislikeButton(
    String messageId,
    bool isLiked,
    bool isDisliked,
    int index,
  ) {
    final double iconSize = isDisliked ? 15 : 17;

    return GestureDetector(
      onTap:
          (isLiked || isDisliked)
              ? null
              : () {
                if (messageId.isNotEmpty) {
                  onDislike(messageId, index);
                } else {
                  CommonUtils.showErrorToast(
                    'Cannot dislike: Message ID is missing',
                  );
                }
              },
      child: Opacity(
        opacity: (isLiked || isDisliked) ? 0.5 : 1.0,
        child: Image.asset(
          isDisliked
              ? 'assets/images/thumbsdownlike.png'
              : 'assets/images/thumbsdownunlike.png',
          height: iconSize,
          width: iconSize,
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String answer) {
    return GestureDetector(
      onTap: () {
        if (answer.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: answer));
          CommonUtils.showSuccessToast(
            AppLocalizations.of(context)!.translate('responsecopied'),
          );
        }
      },
      child: Image.asset('assets/images/unsave.png', height: 16, width: 16),
    );
  }

  Widget _buildBookmarkButton(String messageId, bool is_bookmarked, int index) {
    // if (kDebugMode) {
    //   debugPrint('📚 Bookmark Button Debug:');
    //   debugPrint('  - Index: $index');
    //   debugPrint('  - Message ID: $messageId');
    //   debugPrint('  - is_bookmarked: $is_bookmarked');
    // }

    return GestureDetector(
      onTap: () {
        if (messageId.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '🎯 Bookmark tapped: ${is_bookmarked ? 'UNBOOKMARK' : 'BOOKMARK'}',
            );
          }
          // Don't change state optimistically - let the API response handle it
          onBookmark(messageId, index, is_bookmarked);
        } else {
          if (kDebugMode) {
            debugPrint('❌ Cannot bookmark: Message ID is missing');
          }
          CommonUtils.showErrorToast('Cannot bookmark: Message ID is missing');
        }
      },
      child: Image.asset(
        is_bookmarked
            ? 'assets/images/bookmark.png'
            : 'assets/images/unbookmark.png',
        height: 14,
        width: 14,
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context,
    int index,
    String question,
    String answer,
  ) {
    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () async {
            if (question.isNotEmpty && answer.isNotEmpty) {
              final String chatSessionId =
                  (chatHistory[index]['chatId']?.toString().trim().isNotEmpty ==
                          true
                      ? chatHistory[index]['chatId']?.toString().trim()
                      : chatId?.trim()) ??
                  '';
              if (chatSessionId.isEmpty) {
                CommonUtils.showErrorToast(
                  'Cannot share: Chat ID is unavailable',
                );
                return;
              }

              final deepLink = 'https://divinearc.in/chat/$chatSessionId';
              final playStoreUrl =
                  'https://play.google.com/store/apps/details?id=com.divinearc.app';
              final appStoreUrl =
                  'https://apps.apple.com/us/app/divine-arc/id6758439307';
              final shareText =
                  '''Open this chat in Divine ARC App : \n$deepLink\n\nIf the app is not installed, install it here : \n\nAndroid :  $playStoreUrl\n\niOS :  $appStoreUrl''';

              final box = context.findRenderObject() as RenderBox?;
              final Rect? sharePositionOrigin =
                  box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;

              SharePlus.instance.share(
                ShareParams(
                  text: shareText,
                  sharePositionOrigin: sharePositionOrigin,
                ),
              );
              CommonUtils.showSuccessToast('Sharing conversation...');
            } else if (question.isNotEmpty && answer.isEmpty) {
              CommonUtils.showErrorToast(
                'Cannot share: No response available yet',
              );
            } else {
              CommonUtils.showErrorToast(
                'Cannot share: Conversation is incomplete',
              );
            }
          },
          child: Image.asset(
            'assets/images/unshare.png',
            height: 14,
            width: 14,
          ),
        );
      },
    );
  }
}
