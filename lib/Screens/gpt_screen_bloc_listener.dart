import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'gpt_screen_methods.dart';

extension GptScreenBlocListener on GptScreenMethods {
  Future<void> handleBlocState(
    BuildContext context,
    HomeFlowState state,
  ) async {
    try {
      if (state is InitiateChatSuccess) {
        _handleInitiateChatSuccess(state);
      } else if (state is InitiateChatFailure) {
        _handleInitiateChatFailure(state);
      } else if (state is StoreChatSuccess) {
        _handleStoreChatSuccess(context, state);
      } else if (state is StoreChatError) {
        _handleStoreChatError(state);
      } else if (state is SendAPIResponseFailure) {
        _handleSendAPIResponseFailure(state);
      } else if (state is SendRegenerateAPIResponseSuccess) {
        _handleSendRegenerateAPIResponseSuccess();
      } else if (state is ChatStreamingState) {
        _handleChatStreamingState(state);
      } else if (state is ChatLoadedState) {
        _handleChatLoadedState(context, state);
      } else if (state is ChatErrorState) {
        _handleChatErrorState(state);
      } else if (state is UploadFileSuccess) {
        await _handleUploadFileSuccess(context, state);
      } else if (state is UploadFileFailure) {
        _handleUploadFileFailure(state);
      } else if (state is VoiceConversationSuccess) {
        await _handleVoiceConversationSuccess(context, state);
      } else if (state is StoreEdittedChatSuccess) {
        _handleStoreEdittedChatSuccess(context, state);
      } else if (state is VoiceConversationFailure) {
        _handleVoiceConversationFailure(state);
      } else if (state is GetSingleChatHistorySuccess) {
        _handleGetSingleChatHistorySuccess(state);
      } else if (state is GetSingleChatHistoryFailure) {
        _handleGetSingleChatHistoryFailure(state);
      } else if (state is ReactOnChatSuccess) {
        _handleReactOnChatSuccess(context, state);
      } else if (state is ReactOnChatFailure) {
        _handleReactOnChatFailure(state);
      } else if (state is ChatFeedbackSuccess) {
        _handleChatFeedbackSuccess(state);
      } else if (state is ChatFeedbackFailure) {
        _handleChatFeedbackFailure(context, state);
      } else if (state is CheckNetworkConnectionHomeFlow) {
        _handleCheckNetworkConnectionHomeFlow();
      } else if (state is BookmarkChatSuccess) {
        _handleBookmarkChatSuccess(state);
      } else if (state is BookmarkChatFailure) {
        _handleBookmarkChatFailure(state);
      } else if (state is UnbookmarkChatSuccess) {
        _handleUnbookmarkChatSuccess(state);
      } else if (state is UnbookmarkChatFailure) {
        _handleUnbookmarkChatFailure(state);
      } else if (state is SessionExpiredStateHome) {
        _handleSessionExpiredStateHome(context, state);
      }
    } catch (e) {
      debugPrint('Error in bloc listener: $e');
      setState(() {
        isApiProcessing = false;
        isConvertingAudio = false;
      });
    }
  }

  void _handleInitiateChatSuccess(InitiateChatSuccess state) {
    final response = state.successResponse;
    final String chatID = response['id'];
    PrefUtils.setstoredChatID(chatID);
  }

  void _handleInitiateChatFailure(InitiateChatFailure state) {
    CommonUtils.showErrorToast(state.failureResponse['message']);
    setState(() => isApiProcessing = false);
  }

  void _handleStoreChatSuccess(BuildContext context, StoreChatSuccess state) {
    final response = state.successResponse;
    final newMessageId = response['id']?.toString() ?? '';

    if (currentResponseIndex != null &&
        currentResponseIndex! < chatHistory.length) {
      setState(() {
        final existingMessageId =
            chatHistory[currentResponseIndex!]['messageId']?.toString() ?? '';
        final bool isRegeneration =
            chatHistory[currentResponseIndex!]['isRegenerating'] == true;

        if (!isRegeneration && existingMessageId.isEmpty) {
          chatHistory[currentResponseIndex!]['messageId'] = newMessageId;
          PrefUtils.setEdittedMessageID(newMessageId);
        }

        if (currentUserAudioUrl != null) {
          chatHistory[currentResponseIndex!]['audio_url'] = currentUserAudioUrl;
          userAudioUrlMap[currentResponseIndex!] = currentUserAudioUrl!;
        }

        PrefUtils.setChatHistory(chatHistory);
      });
    }

    if (currentResponseIndex != null && chatHistory.isNotEmpty) {
      final latestAnswer = chatHistory[currentResponseIndex!]['answer'];
      final existingMessageId =
          chatHistory[currentResponseIndex!]['messageId']?.toString() ?? '';
      final bool isRegeneration =
          chatHistory[currentResponseIndex!]['isRegenerating'] == true;
      final messageIdToUse =
          isRegeneration && existingMessageId.isNotEmpty
              ? existingMessageId
              : newMessageId;

      final bool isUserAudio =
          chatHistory[currentResponseIndex!]['isUserAudio'] == true;

      if (messageIdToUse.isNotEmpty) {
        final String audioUrl =
            isUserAudio && currentUserAudioUrl != null
                ? currentUserAudioUrl!
                : '';

        BlocProvider.of<HomeFlowBloc>(context).add(
          SendAPIResponseEvent(
            messageId: messageIdToUse,
            apiName: 'Atlas',
            apiType: 'Chat',
            apiResponse: latestAnswer,
            apiStatus: 'SUCCESS',
            apiError: '',
            audioUrl: audioUrl,
          ),
        );
      }
    }
  }

  void _handleStoreChatError(StoreChatError state) {
    CommonUtils.showErrorToast(state.failureResponse['message']);
    setState(() => isApiProcessing = false);
  }

  void _handleSendAPIResponseFailure(SendAPIResponseFailure state) {
    CommonUtils.showErrorToast(state.failureResponse['message']);
    setState(() => isApiProcessing = false);
  }

  void _handleSendRegenerateAPIResponseSuccess() {
    chatHistory[currentResponseIndex!]['isRegenerating'] = false;
  }

  void _handleChatStreamingState(ChatStreamingState state) {
    setState(() {
      if (currentResponseIndex != null &&
          currentResponseIndex! < chatHistory.length) {
        String currentAnswer =
            chatHistory[currentResponseIndex!]['answer'] ?? '';
        currentAnswer += state.response;
        chatHistory[currentResponseIndex!]['answer'] = currentAnswer;
        PrefUtils.setChatHistory(chatHistory);
      }
    });
  }

  void _handleChatLoadedState(BuildContext context, ChatLoadedState state) {
    setState(() {
      if (currentResponseIndex != null &&
          currentResponseIndex! < chatHistory.length) {
        // Check if the response contains an error (400 or content filter)
        String responseText = state.partialResponse;

        // Check for error patterns indicating content filtering or 400 errors
        if (responseText.contains('Error code: 400') ||
            responseText.contains('content_filter') ||
            responseText.contains('ResponsibleAIPolicyViolation') ||
            responseText.startsWith('Error:')) {
          chatHistory[currentResponseIndex!]['answer'] = '';
          chatHistory[currentResponseIndex!]['hasError'] = true;
        } else {
          chatHistory[currentResponseIndex!]['answer'] = responseText;
          chatHistory[currentResponseIndex!]['hasError'] = false;
        }

        responseLoadingStates.remove(currentResponseIndex);
        isApiProcessing = false;
        PrefUtils.setChatHistory(chatHistory);
      }
    });

    if (currentResponseIndex != null &&
        currentResponseIndex! < chatHistory.length) {
      setState(() {
        chatHistory[currentResponseIndex!]['chatId'] = getCurrentChatId();
        PrefUtils.setChatHistory(chatHistory);
      });

      final latestQuestion = chatHistory[currentResponseIndex!]['question'];
      final bool isRegeneration =
          chatHistory[currentResponseIndex!]['isRegenerating'] == true;

      if (latestQuestion != null && latestQuestion.isNotEmpty) {
        isRegeneration
            ? BlocProvider.of<HomeFlowBloc>(context).add(
              StoreEdittedChatEvent(
                message: latestQuestion,
                modelName: 'Atlas',
                searchEngine: 'Search',
                edited: true,
                sender: 'user',
                chatId: getCurrentChatId(),
                messageId: PrefUtils.getEdittedMessageID(),
              ),
            )
            : BlocProvider.of<HomeFlowBloc>(context).add(
              StoreChatEvent(
                message: latestQuestion,
                modelName: 'Atlas',
                searchEngine: 'Search',
                edited: false,
                sender: 'user',
                chatId: getCurrentChatId(),
              ),
            );
      }
    }
  }

  void _handleChatErrorState(ChatErrorState state) {
    CommonUtils.showErrorToast(state.error['message']);
    if (currentResponseIndex != null) {
      responseLoadingStates.remove(currentResponseIndex);
    }
    setState(() => isApiProcessing = false);
  }

  Future<void> _handleUploadFileSuccess(
    BuildContext context,
    UploadFileSuccess state,
  ) async {
    final newUrl = state.successResponse['url'];
    final bool isResponseAudio = state.isResponseAudio ?? false;

    if (isResponseAudio) {
      currentResponseAudioUrl = newUrl;

      if (currentResponseIndex != null &&
          currentResponseIndex! < chatHistory.length) {
        setState(() {
          chatHistory[currentResponseIndex!]['hasAudioUrl'] = true;
          responseAudioUrlMap[currentResponseIndex!] = newUrl;

          if (chatHistory[currentResponseIndex!]['apiResponses'] == null) {
            chatHistory[currentResponseIndex!]['apiResponses'] = [];
          }

          final apiResponses =
              chatHistory[currentResponseIndex!]['apiResponses'] as List;
          if (apiResponses.isEmpty) {
            apiResponses.add({
              'audio_url': newUrl,
              'api_response': 'Audio Response',
            });
          } else {
            apiResponses[0]['audio_url'] = newUrl;
          }

          responseLoadingStates.remove(currentResponseIndex);
          isApiProcessing = false;
          isConvertingAudio = false;
          PrefUtils.setChatHistory(chatHistory);
        });

        final messageId =
            chatHistory[currentResponseIndex!]['messageId']?.toString() ?? '';
        final latestAnswer =
            chatHistory[currentResponseIndex!]['answer']?.toString() ?? '';

        if (messageId.isNotEmpty) {
          BlocProvider.of<HomeFlowBloc>(context).add(
            SendAPIResponseEvent(
              messageId: messageId,
              apiName: 'Atlas',
              apiType: 'Chat',
              apiResponse: latestAnswer,
              apiStatus: 'SUCCESS',
              apiError: '',
              audioUrl: newUrl,
            ),
          );
        }
      }
    } else {
      currentUserAudioUrl = newUrl;

      BlocProvider.of<HomeFlowBloc>(context).add(
        VoiceConversationEvent(
          audioFile: File(audioPath!),
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );
    }
  }

  void _handleUploadFileFailure(UploadFileFailure state) {
    CommonUtils.showErrorToast(state.failureResponse['message']);
    if (state.isResponseAudio == true) {
      setState(() {
        isConvertingAudio = false;
        if (currentResponseIndex != null) {
          responseLoadingStates.remove(currentResponseIndex);
          isApiProcessing = false;
        }
      });
    }
  }

  Future<void> _handleVoiceConversationSuccess(
    BuildContext context,
    VoiceConversationSuccess state,
  ) async {
    final response = state.successResponse;
    if (kDebugMode) {
      debugPrint("AUDIO RESPONSE RECEIVED :$response");
    }

    if (currentResponseIndex != null &&
        currentResponseIndex! < chatHistory.length) {
      await handleVoiceResponse(response, currentResponseIndex!);

      if (currentUserAudioUrl != null) {
        BlocProvider.of<HomeFlowBloc>(context).add(
          StoreChatEvent(
            message: 'Audio Recording',
            modelName: 'Atlas',
            searchEngine: 'Search',
            edited: false,
            sender: 'user',
            audioUrl: currentUserAudioUrl!,
            chatId: getCurrentChatId(),
          ),
        );
      }
    }
  }

  void _handleStoreEdittedChatSuccess(
    BuildContext context,
    StoreEdittedChatSuccess state,
  ) {
    final response = state.successResponse;
    final newMessageId = response['id']?.toString() ?? '';

    if (currentResponseIndex != null && chatHistory.isNotEmpty) {
      final latestAnswer = chatHistory[currentResponseIndex!]['answer'];
      final existingMessageId =
          chatHistory[currentResponseIndex!]['messageId']?.toString() ?? '';
      final bool isRegeneration =
          chatHistory[currentResponseIndex!]['isRegenerating'] == true;
      final messageIdToUse =
          isRegeneration && existingMessageId.isNotEmpty
              ? existingMessageId
              : newMessageId;

      if (messageIdToUse.isNotEmpty &&
          latestAnswer != null &&
          latestAnswer.isNotEmpty) {
        BlocProvider.of<HomeFlowBloc>(context).add(
          SendRegenerateAPIResponseEvent(
            messageId: messageIdToUse,
            apiName: 'Atlas',
            apiType: 'Chat',
            apiResponse: latestAnswer,
            apiStatus: 'SUCCESS',
            apiError: '',
          ),
        );
      }
    }
  }

  void _handleVoiceConversationFailure(VoiceConversationFailure state) {
    CommonUtils.showErrorToast(state.failureResponse);
    if (currentResponseIndex != null) {
      responseLoadingStates.remove(currentResponseIndex);
    }
    setState(() {
      isApiProcessing = false;
      isConvertingAudio = false;
    });
  }

  void _handleGetSingleChatHistorySuccess(GetSingleChatHistorySuccess state) {
    final response = state.successResponse;
    final String chatId = response['chat']['id']?.toString() ?? '';
    final List<dynamic> messages = response['messages'] as List<dynamic>;

    setState(() {
      final Map<String, Map<String, dynamic>> localChatMap = {
        for (var chat in chatHistory) chat['messageId']: chat,
      };

      chatHistory =
          messages.map<Map<String, dynamic>>((message) {
            final String messageId = message['id']?.toString() ?? '';
            final String question = message['message']?.toString() ?? '';
            final List<dynamic> apiResponses =
                message['apiResponses'] as List<dynamic>? ?? [];
            final String answer =
                apiResponses.isNotEmpty
                    ? apiResponses[0]['api_response']?.toString() ?? ''
                    : '';
            final String audioUrl =
                apiResponses.isNotEmpty
                    ? apiResponses[0]['audio_url']?.toString() ?? ''
                    : '';
            final String userAudioUrl = message['audio_url']?.toString() ?? '';
            final bool is_bookmarked = message['is_bookmarked'] ?? false;
            final bool isLiked = message['isLiked'] ?? false;
            final bool isDisliked = message['isDisliked'] ?? false;
            final localChat = localChatMap[messageId] ?? {};

            final bool isUserAudio =
                question == 'Audio Recording' &&
                (userAudioUrl.isNotEmpty || localChat['isUserAudio'] == true);

            final Map<String, dynamic> chatItem = {
              'question': question,
              'answer': answer,
              'chatId': chatId,
              'messageId': messageId,
              'is_bookmarked':
                  is_bookmarked || localChat['is_bookmarked'] == true,
              'isLiked': isLiked || localChat['isLiked'] == true,
              'isDisliked': isDisliked || localChat['isDisliked'] == true,
              'isUserAudio': isUserAudio,
              'hasAudioUrl': audioUrl.isNotEmpty,
              'audio_url': userAudioUrl,
              'apiResponses': apiResponses,
              'hasError': false,
            };

            final index = chatHistory.length;
            if (userAudioUrl.isNotEmpty) {
              userAudioUrlMap[index] = userAudioUrl;
            }
            if (audioUrl.isNotEmpty) {
              responseAudioUrlMap[index] = audioUrl;
            }

            return chatItem;
          }).toList();

      PrefUtils.setChatHistory(chatHistory);
    });

    initialLoadCompleter?.complete();
  }

  void _handleGetSingleChatHistoryFailure(GetSingleChatHistoryFailure state) {
    CommonUtils.showErrorToast(state.failureResponse['message']);
    initialLoadCompleter?.complete();
  }

  void _handleReactOnChatSuccess(
    BuildContext context,
    ReactOnChatSuccess state,
  ) {
    final response = state.successResponse;
    reactionId = response['data']['id'];
    final messageId = response['data']['message_id'] ?? '';
    final bool isLike = response['data']['is_like'] ?? false;

    setState(() {
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        chatHistory[index]['isLiked'] = isLike;
        chatHistory[index]['isDisliked'] = !isLike;
        PrefUtils.setChatHistory(chatHistory);
      }
    });

    showFeedbackPopup(context);
    CommonUtils.showSuccessToast(response['message']);
  }

  void _handleReactOnChatFailure(ReactOnChatFailure state) {
    final messageId = state.failureResponse['message_id'] ?? '';
    final bool wasLike = state.failureResponse['is_like'] ?? false;

    setState(() {
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        chatHistory[index]['isLiked'] =
            wasLike ? false : chatHistory[index]['isLiked'];
        chatHistory[index]['isDisliked'] =
            !wasLike ? false : chatHistory[index]['isDisliked'];
        PrefUtils.setChatHistory(chatHistory);
      }
    });

    CommonUtils.showErrorToast(state.failureResponse['message']);
  }

  void _handleChatFeedbackSuccess(ChatFeedbackSuccess state) {
    CommonUtils.showSuccessToast(state.successResponse['message']);
  }

  void _handleChatFeedbackFailure(
    BuildContext context,
    ChatFeedbackFailure state,
  ) {
    Navigator.pop(context);
    CommonUtils.showErrorToast(state.failureResponse['message']);
  }

  void _handleCheckNetworkConnectionHomeFlow() {
    CommonUtils.showErrorToast('No Internet Connection!');
    setState(() => isApiProcessing = false);
  }

  void _handleBookmarkChatSuccess(BookmarkChatSuccess state) {
    final response = state.successResponse;
    // FIX: The message ID is in response['data']['id'], not response['data']['message_id']
    final messageId = response['data']['id']?.toString() ?? '';

    if (kDebugMode) {
      debugPrint('✅ Bookmark Success - Message ID: $messageId');
      debugPrint('📊 Full response: $response');
    }

    setState(() {
      // Find the chat item with this messageId
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        if (kDebugMode) {
          debugPrint('📌 Updating bookmark for index $index to TRUE');
          debugPrint('📋 Chat item found: ${chatHistory[index]}');
        }
        chatHistory[index]['is_bookmarked'] = true;
        PrefUtils.setChatHistory(chatHistory);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Could not find chat with messageId: $messageId');
          debugPrint(
            '🔍 Available messageIds: ${chatHistory.map((c) => c['messageId']).toList()}',
          );
        }
      }
    });

    CommonUtils.showSuccessToast(
      AppLocalizations.of(context)!.translate('chatbookmarkedsuccessfully'),
    );
  }

  void _handleBookmarkChatFailure(BookmarkChatFailure state) {
    // FIX: Check if the response structure matches
    final failureResponse = state.failureResponse;
    final messageId =
        failureResponse['message_id']?.toString() ??
        failureResponse['id']?.toString() ??
        '';

    if (kDebugMode) {
      debugPrint('❌ Bookmark Failed - Message ID: $messageId');
      debugPrint('📊 Failure response: $failureResponse');
    }

    setState(() {
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        // Revert the bookmark state on failure
        chatHistory[index]['is_bookmarked'] = false;
        PrefUtils.setChatHistory(chatHistory);
      }
    });
    CommonUtils.showErrorToast(state.failureResponse['message']);
  }

  void _handleUnbookmarkChatFailure(UnbookmarkChatFailure state) {
    final failureResponse = state.failureResponse;
    final messageId =
        failureResponse['message_id']?.toString() ??
        failureResponse['id']?.toString() ??
        '';

    if (kDebugMode) {
      debugPrint('❌ Unbookmark Failed - Message ID: $messageId');
    }

    setState(() {
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        // Revert the bookmark state on failure
        chatHistory[index]['is_bookmarked'] = true;
        PrefUtils.setChatHistory(chatHistory);
      }
    });
    CommonUtils.showErrorToast(state.failureResponse['message']);
  }

  void _handleUnbookmarkChatSuccess(UnbookmarkChatSuccess state) {
    final response = state.successResponse;
    // FIX: Same issue here
    final messageId = response['data']['id']?.toString() ?? '';

    if (kDebugMode) {
      debugPrint('✅ Unbookmark Success - Message ID: $messageId');
    }

    setState(() {
      final index = chatHistory.indexWhere(
        (chat) => chat['messageId'] == messageId,
      );
      if (index != -1) {
        if (kDebugMode) {
          debugPrint('📌 Updating bookmark for index $index to FALSE');
        }
        chatHistory[index]['is_bookmarked'] = false;
        PrefUtils.setChatHistory(chatHistory);
      }
    });

    CommonUtils.showSuccessToast(
      AppLocalizations.of(context)!.translate('chatunbookmarkedsuccessfully'),
    );
  }

  void _handleSessionExpiredStateHome(
    BuildContext context,
    SessionExpiredStateHome state,
  ) {
    SessionExpiredSnackBar.show(context: context, message: state.message);
  }
}
