import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:gita_gpt/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class GetSingleChatConversationHistory extends StatefulWidget {
  final String chatId;
  const GetSingleChatConversationHistory({super.key, required this.chatId});

  @override
  State<GetSingleChatConversationHistory> createState() => _GetSingleChatConversationHistoryState();
}

class _GetSingleChatConversationHistoryState extends State<GetSingleChatConversationHistory> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  String question = '';
  List<dynamic> messages = [];
  List<Map<String, String>> chatHistory = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  final TextEditingController feedbackTextController = TextEditingController();
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? audioPath;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _editingIndex;
  int? _currentResponseIndex;
  String reactionId = '';

  @override
  void initState() {
    super.initState();
    BlocProvider.of<HomeFlowBloc>(context).add(GetSingleChatHistoryEvent(chatId: widget.chatId));
    _initializeRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    try {
      await recorder.openRecorder();
    } catch (e) {
      print('Failed to initialize recorder: $e');
      CommonUtils.showErrorToast('Failed to initialize recorder: $e');
    }
  }

  Future<void> startRecording() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.windows ||
          Theme.of(context).platform == TargetPlatform.linux ||
          Theme.of(context).platform == TargetPlatform.macOS) {
        CommonUtils.showErrorToast('Recording not supported on this platform');
        return;
      }

      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        CommonUtils.showErrorToast('Microphone permission denied');
        return;
      }

      final dir = await getTemporaryDirectory();
      audioPath = '${dir.path}/input.wav';

      await recorder.startRecorder(toFile: audioPath, codec: Codec.pcm16WAV);

      setState(() {
        isRecording = true;
      });

      print('Recording started... Path: $audioPath');
    } catch (e) {
      print('Error starting recording: $e');
      CommonUtils.showErrorToast('Failed to start recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      await recorder.stopRecorder();

      setState(() {
        isRecording = false;
      });

      print('Recording stopped. File: $audioPath');

      if (audioPath != null) {
        final audioFile = File(audioPath!);

        BlocProvider.of<HomeFlowBloc>(context).add(
          VoiceConversationEvent(
            audioFile: audioFile,
            language: PrefUtils.getLanguage(),
            sessionId: PrefUtils.getSessionID(),
          ),
        );
      } else {
        CommonUtils.showErrorToast('No recording file found');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      CommonUtils.showErrorToast('Failed to stop recording: $e');
    }
  }

  void _showFeedbackPopup(BuildContext context) {
    feedbackTextController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.gradientStart),
            borderRadius: BorderRadius.circular(10),
          ),
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/thumbsupunlike.png',
                        height: 20,
                        width: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/thumbsdownunlike.png',
                        height: 20,
                        width: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('feedback'),
                        style: FTextStyle.boldText.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    controller: feedbackTextController,
                    style: FTextStyle.defaultText,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.translate('enterFeedbackHere'),
                      hintStyle: FTextStyle.defaultText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    final feedbackText = feedbackTextController.text.trim();
                    if (feedbackText.isNotEmpty) {
                      Navigator.pop(context);
                      BlocProvider.of<HomeFlowBloc>(context).add(ChatFeedbackEvent(
                        reactionId: reactionId,
                        feedbackText: feedbackText,
                      ));
                      CommonUtils.showSuccessToast('Feedback submitted successfully!.');
                    } else {
                      CommonUtils.showErrorToast('Please enter feedback');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: 45,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.translate('submit'),
                        style: FTextStyle.buttonText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    inputController.dispose();
    feedbackTextController.dispose();
    _animationController.stop();
    _animationController.dispose();
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                if (state is GetSingleChatHistoryLoading) {
                  setState(() {
                    isLoading = true;
                  });
                } else if (state is GetSingleChatHistorySuccess) {
                  setState(() {
                    isLoading = false;
                    final response = state.successResponse;
                    messages = response['messages'] ?? [];
                    question = response['chat']?['question'] ?? '';
                  });
                  _scrollToBottom();
                } else if (state is GetSingleChatHistoryFailure) {
                  setState(() {
                    isLoading = false;
                  });
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is InitiateChatSuccess) {
                  final response = state.successResponse;
                  final String chatId = response['id'];
                  PrefUtils.setChatID(chatId);
                  setState(() {
                    if (_currentResponseIndex != null && _currentResponseIndex! < messages.length) {
                      messages[_currentResponseIndex!] = {
                        ...messages[_currentResponseIndex!],
                        'chatId': chatId,
                      };
                    }
                  });
                } else if (state is InitiateChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is StoreChatSuccess) {
                  final response = state.successResponse;
                  final messageId = response['id'];
                  setState(() {
                    if (_currentResponseIndex != null && _currentResponseIndex! < messages.length) {
                      messages[_currentResponseIndex!] = {
                        ...messages[_currentResponseIndex!],
                        'messageId': messageId,
                      };
                    }
                  });
                  String? latestAnswer = messages[_currentResponseIndex!]['apiResponses']?.isNotEmpty == true
                      ? messages[_currentResponseIndex!]['apiResponses'][0]['api_response']
                      : null;
                  if (latestAnswer != null) {
                    BlocProvider.of<HomeFlowBloc>(context).add(
                      SendAPIResponseEvent(
                        messageId: messageId,
                        apiName: 'Atlas',
                        apiType: 'Chat',
                        apiResponse: latestAnswer,
                        apiStatus: 'SUCCESS',
                        apiError: '',
                      ),
                    );
                  }
                } else if (state is StoreChatError) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is SendAPIResponseFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is ChatStreamingState) {
                  setState(() {
                    if (_currentResponseIndex != null && _currentResponseIndex! < messages.length) {
                      var currentMessage = messages[_currentResponseIndex!];
                      String currentAnswer = currentMessage['apiResponses']?.isNotEmpty == true
                          ? currentMessage['apiResponses'][0]['api_response'] ?? ''
                          : '';
                      currentAnswer += state.response;
                      messages[_currentResponseIndex!] = {
                        ...currentMessage,
                        'apiResponses': [
                          {'api_response': currentAnswer}
                        ],
                      };
                    }
                  });
                  _scrollToBottom();
                } else if (state is ChatLoadedState) {
                  setState(() {
                    if (_currentResponseIndex != null && _currentResponseIndex! < messages.length) {
                      messages[_currentResponseIndex!] = {
                        ...messages[_currentResponseIndex!],
                        'apiResponses': [
                          {'api_response': state.partialResponse}
                        ],
                      };
                    }
                  });
                  if (_currentResponseIndex != null && _currentResponseIndex! < messages.length) {
                    setState(() {
                      messages[_currentResponseIndex!] = {
                        ...messages[_currentResponseIndex!],
                        'chatId': PrefUtils.getChatID(),
                      };
                    });
                    String? latestQuestion = messages[_currentResponseIndex!]['message'];
                    BlocProvider.of<HomeFlowBloc>(context).add(
                      StoreChatEvent(
                        message: latestQuestion ?? '',
                        modelName: 'Atlas',
                        searchEngine: 'Search',
                        edited: false,
                        sender: 'user',
                        chatId: widget.chatId
                      ),
                    );
                  }
                  _scrollToBottom();
                } else if (state is ChatErrorState) {
                  CommonUtils.showErrorToast(state.error['message']);
                } else if (state is ReactOnChatSuccess) {
                  final response = state.successResponse;
                  reactionId = response['data']['id'];
                  _showFeedbackPopup(context);
                  CommonUtils.showSuccessToast(response['message']);
                } else if (state is ReactOnChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is ChatFeedbackSuccess) {
                  final response = state.successResponse;
                  CommonUtils.showSuccessToast(response['message']);
                } else if (state is ChatFeedbackFailure) {
                  Navigator.pop(context);
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is ShareChatSuccess) {
                  final shareUrl = state.successResponse;
                  if (shareUrl.isNotEmpty) {
                    SharePlus.instance.share(ShareParams(text: shareUrl));
                  } else {
                    CommonUtils.showErrorToast('Failed to share: Invalid URL');
                  }
                } else if (state is ShareChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('history'),
                          style: FTextStyle.homeText,
                        ),
                        const LanguageDropdown(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: isLoading
                          ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: AppColors.gradientStart,
                          size: 50,
                        ),
                      )
                          : messages.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/images/errorImage.png',
                                height: 200,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)!.translate('noMessages'),
                              style: FTextStyle.defaultTextBold,
                            ),
                          ],
                        ),
                      )
                          : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gradientStart),
                          color: Colors.white,
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final question = message['message'] ?? '';
                            final answer = (message['apiResponses'] != null &&
                                message['apiResponses'].isNotEmpty &&
                                message['apiResponses'][0]['api_response'] != null)
                                ? message['apiResponses'][0]['api_response']
                                : 'Loading...';
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
                                          color: answer == 'No response yet' ? Colors.grey : Colors.black,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.gradientStart),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: inputController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.translate('askAnything'),
                                border: InputBorder.none,
                              ),
                              style: FTextStyle.defaultText,
                              minLines: 1,
                              maxLines: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isRecording)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Container(
                                      height: 35 + (_animationController.value * 5),
                                      width: 35 + (_animationController.value * 5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green.withOpacity(0.3 * (1 - _animationController.value)),
                                      ),
                                    );
                                  },
                                ),
                              ScaleTransition(
                                scale: isRecording ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                                child: Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isRecording ? Colors.white : AppColors.gradientStart,
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    color: isRecording ? Colors.green : Colors.white,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.mic,
                                      size: 20,
                                      color: isRecording ? Colors.white : AppColors.gradientStart,
                                    ),
                                    onPressed: () async {
                                      if (isRecording) {
                                        await stopRecording();
                                      } else {
                                        await startRecording();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final message = inputController.text.trim();
                              if (message.isNotEmpty) {
                                String chatId = '';
                                bool isEdited = false;
                                setState(() {
                                  if (_editingIndex != null && _editingIndex! < messages.length) {
                                    // Update existing message
                                    messages[_editingIndex!] = {
                                      ...messages[_editingIndex!],
                                      'message': message,
                                      'apiResponses': [],
                                      'chatId': messages[_editingIndex!]['chatId'] ?? '',
                                      'messageId': messages[_editingIndex!]['messageId'] ?? '',
                                    };
                                    _currentResponseIndex = _editingIndex;
                                    chatId = messages[_editingIndex!]['chatId'] ?? '';
                                    isEdited = true;
                                  } else {
                                    // Add new message
                                    messages.add({
                                      'message': message,
                                      'apiResponses': [],
                                      'chatId': '',
                                      'messageId': '',
                                    });
                                    _currentResponseIndex = messages.length - 1;
                                    chatId = PrefUtils.getChatID();
                                    isEdited = false;
                                  }
                                  // Update chatHistory for local storage
                                  if (_editingIndex != null && _editingIndex! < chatHistory.length) {
                                    chatHistory[_editingIndex!] = {
                                      'question': message,
                                      'answer': '',
                                      'chatId': chatId,
                                      'messageId': '',
                                    };
                                  } else {
                                    chatHistory.add({
                                      'question': message,
                                      'answer': '',
                                      'chatId': chatId,
                                      'messageId': '',
                                    });
                                  }
                                  PrefUtils.setChatHistory(chatHistory);
                                });

                                if (PrefUtils.getChatID().isEmpty) {
                                  BlocProvider.of<HomeFlowBloc>(context).add(
                                    InitiateChatEvent(
                                      message: message,
                                      isGuest: PrefUtils.getIsGuest(),
                                      modelName: 'Atlas',
                                      searchEngine: 'Search',
                                      edited: isEdited,
                                      sender: 'user',
                                      chatId: chatId,
                                    ),
                                  );
                                }

                                BlocProvider.of<HomeFlowBloc>(context).add(
                                  ChatEvent(
                                    message: message,
                                    language: PrefUtils.getLanguage(),
                                    sessionId: PrefUtils.getSessionID(),
                                  ),
                                );
                                inputController.clear();
                                _editingIndex = null;
                                _scrollToBottom();
                              }
                            },
                            child: Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
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
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}