import 'dart:developer' as developer;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gita_gpt/APIs/HomeFlow/home_flow_bloc.dart';
import 'package:gita_gpt/Utils/app_imports.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:gita_gpt/Utils/common_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GptScreen extends StatefulWidget {
  final String? searchQueryFromHomeScreen;
  const GptScreen({super.key, this.searchQueryFromHomeScreen});

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? audioPath;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<Map<String, String>> chatHistory = [];
  String currentResponse = "";
  String messageId = '';
  List<bool> _isExpandedList = List.generate(4, (index) => false);

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.searchQueryFromHomeScreen != null &&
        widget.searchQueryFromHomeScreen!.trim().isNotEmpty) {
      callAPI();
    }
  }

  void callAPI() {
    if (widget.searchQueryFromHomeScreen!.isNotEmpty) {
      setState(() {
        chatHistory.add({
          'question': widget.searchQueryFromHomeScreen!,
          'answer': '',
        });
        currentResponse = "";
      });
      BlocProvider.of<HomeFlowBloc>(context).add(
        ChatEvent(
          message: widget.searchQueryFromHomeScreen!,
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );
      inputController.clear();
      _scrollToBottom();
    }
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
      // Check for unsupported platforms
      if (Theme.of(context).platform == TargetPlatform.windows ||
          Theme.of(context).platform == TargetPlatform.linux ||
          Theme.of(context).platform == TargetPlatform.macOS) {
        CommonUtils.showErrorToast('Recording not supported on this platform');
        return;
      }

      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        CommonUtils.showErrorToast('Microphone permission denied');
        return;
      }

      // Get temporary directory to save recording
      final dir = await getTemporaryDirectory();
      audioPath = '${dir.path}/input.wav';

      // Start recording
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

      // Ensure audioPath is not null before proceeding
      if (audioPath != null) {
        final audioFile = File(audioPath!);

        // Dispatch event with audio file
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
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.all(20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.gradientStart),
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('feedback'),
                style: FTextStyle.defaultTextBold,
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(
                    context,
                  )?.translate('enterFeedbackHere'),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                ),
                onPressed: () {
                  final feedback = feedbackController.text.trim();
                  if (feedback.isNotEmpty) {
                    // Placeholder for feedback submission logic
                    print('Feedback submitted: $feedback');
                    CommonUtils.showSuccessToast('Feedback submitted');
                    Navigator.of(context).pop();
                  } else {
                    CommonUtils.showErrorToast('Please enter feedback');
                  }
                },
                child: Text(AppLocalizations.of(context)!.translate('submit')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    inputController.dispose();
    _scrollController.dispose();
    _animationController.stop();
    _animationController.dispose();
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.GlobalBG,
      body: SafeArea(
        child: BlocListener<HomeFlowBloc, HomeFlowState>(
          listener: (context, state) {
            if (state is InitiateChatSuccess) {
              final response = state.successResponse;
              final ChatID = response['id'];
              PrefUtils.setChatID(ChatID);
              // Access the question from chatHistory
              String? latestQuestion;
              if (chatHistory.isNotEmpty) {
                latestQuestion = chatHistory.last['question'];
                print(
                  'Latest Question in InitiateChatSuccess: $latestQuestion',
                );
              }

              // Store the chat event
              BlocProvider.of<HomeFlowBloc>(context).add(
                StoreChatEvent(
                  message: latestQuestion ?? '', // Use the latest question
                  modelName: 'Atlas',
                  searchEngine: 'Search',
                  edited: false,
                  sender: 'user',
                  chatId: ChatID,
                ),
              );
            } else if (state is InitiateChatFailure) {
              CommonUtils.showErrorToast(state.failureResponse['message']);
            } else if (state is StoreChatSuccess) {
              final response = state.successResponse;
              messageId = response['id'];
            } else if (state is StoreChatError) {
              CommonUtils.showErrorToast(state.failureResponse['message']);
            } else if (state is ChatStreamingState) {
              setState(() {
                if (chatHistory.isNotEmpty) {
                  currentResponse += state.response;
                  chatHistory[chatHistory.length - 1]['answer'] =
                      currentResponse;
                }
              });
              _scrollToBottom();
            } else if (state is ChatLoadedState) {
              setState(() {
                if (chatHistory.isNotEmpty) {
                  currentResponse = state.partialResponse;
                  chatHistory[chatHistory.length - 1]['answer'] =
                      currentResponse;
                }
              });
              // Access the question from chatHistory
              String? latestAnswer;
              if (chatHistory.isNotEmpty) {
                latestAnswer = chatHistory.last['answer'];
                BlocProvider.of<HomeFlowBloc>(context).add(
                  SendAPIResponseEvent(
                    messageId: messageId,
                    apiName: 'Atlas',
                    apiType: 'Chat',
                    apiResponse: latestAnswer!,
                    apiStatus: 'SUCCESS',
                    apiError: '',
                  ),
                );
              }

              _scrollToBottom();
            } else if (state is ChatErrorState) {
              CommonUtils.showErrorToast(state.error['message']);
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
                          AppLocalizations.of(context)!.translate('home'),
                          style: FTextStyle.homeText,
                        ),
                        const LanguageDropdown(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Visibility(
                        visible: chatHistory.isNotEmpty,
                        child: Container(
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
                                // Chat Messages
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: chatHistory.length,
                                  itemBuilder: (context, index) {
                                    final question =
                                        chatHistory[index]['question'] ?? '';
                                    final answer =
                                        chatHistory[index]['answer'] ?? '';
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12),
                                          margin: EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: AppColors.gradientStart,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      question,
                                                      style:
                                                          FTextStyle
                                                              .defaultTextBold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Image.asset(
                                                    'assets/images/edit.png',
                                                    height: 16,
                                                    width: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                answer,
                                                style: FTextStyle.defaultText,
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/images/refresh.png',
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.translate(
                                                          'regenerate',
                                                        ),
                                                        style:
                                                            FTextStyle
                                                                .selectedRadioColorText,
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Image.asset(
                                                        'assets/images/thumbsupunlike.png',
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      GestureDetector(
                                                        onTap:
                                                            () =>
                                                                _showFeedbackPopup(
                                                                  context,
                                                                ),
                                                        child: Image.asset(
                                                          'assets/images/thumbsdownunlike.png',
                                                          height: 16,
                                                          width: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Image.asset(
                                                        'assets/images/unsave.png',
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Image.asset(
                                                        'assets/images/unbookmark.png',
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Image.asset(
                                                        'assets/images/unshare.png',
                                                        height: 16,
                                                        width: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                // Related Searches
                                const SizedBox(height: 10),
                                // Row(
                                //   children: [
                                //     Image.asset(
                                //       'assets/images/Edit.png',
                                //       height: 17,
                                //       width: 17,
                                //     ),
                                //     SizedBox(width: 10),
                                //     Text(
                                //       AppLocalizations.of(
                                //         context,
                                //       )!.translate('relatedSearches'),
                                //       style: FTextStyle.defaultTextBold,
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(height: 10),
                                // Divider(color: Colors.black),
                                // ListView.builder(
                                //   shrinkWrap: true,
                                //   physics: NeverScrollableScrollPhysics(),
                                //   itemCount: 4,
                                //   itemBuilder: (context, index) {
                                //     return Column(
                                //       children: [
                                //         Row(
                                //           mainAxisAlignment:
                                //               MainAxisAlignment.spaceBetween,
                                //           children: [
                                //             Text(
                                //               AppLocalizations.of(
                                //                 context,
                                //               )!.translate('suggestions'),
                                //               style: FTextStyle.defaultText,
                                //             ),
                                //             IconButton(
                                //               icon: Icon(
                                //                 _isExpandedList[index]
                                //                     ? Icons.remove
                                //                     : Icons.add,
                                //               ),
                                //               onPressed: () {
                                //                 setState(() {
                                //                   _isExpandedList[index] =
                                //                       !_isExpandedList[index];
                                //                 });
                                //               },
                                //             ),
                                //           ],
                                //         ),
                                //       ],
                                //     );
                                //   },
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bottom Input
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                                hintText: AppLocalizations.of(
                                  context,
                                )!.translate('askAnything'),
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
                              // Ripple effect when recording
                              if (isRecording)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Container(
                                      height:
                                          35 + (_animationController.value * 5),
                                      width:
                                          35 + (_animationController.value * 5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green.withOpacity(
                                          0.3 *
                                              (1 - _animationController.value),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              // Main button with scale animation
                              ScaleTransition(
                                scale:
                                    isRecording
                                        ? _scaleAnimation
                                        : AlwaysStoppedAnimation(1.0),
                                child: Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isRecording
                                              ? Colors.white
                                              : AppColors.gradientStart,
                                    ),
                                    borderRadius: BorderRadius.circular(40),
                                    color:
                                        isRecording
                                            ? Colors.green
                                            : Colors.white,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.mic,
                                      size: 20,
                                      color:
                                          isRecording
                                              ? Colors.white
                                              : AppColors.gradientStart,
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
                                setState(() {
                                  chatHistory.add({
                                    'question': message,
                                    'answer': '',
                                  });
                                  currentResponse = "";
                                });
                                BlocProvider.of<HomeFlowBloc>(context).add(
                                  InitiateChatEvent(
                                    message: message,
                                    isGuest: PrefUtils.getIsGuest(),
                                    modelName: 'Atlas',
                                    searchEngine: 'Search',
                                    edited: false,
                                    sender: 'user',
                                    chatId: '',
                                  ),
                                );
                                BlocProvider.of<HomeFlowBloc>(context).add(
                                  ChatEvent(
                                    message: message,
                                    language: PrefUtils.getLanguage(),
                                    sessionId: PrefUtils.getSessionID(),
                                  ),
                                );
                                inputController.clear();
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
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
