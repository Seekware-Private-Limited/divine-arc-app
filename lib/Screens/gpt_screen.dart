import 'package:gita_gpt/Utils/app_imports.dart';

class GptScreen extends StatefulWidget {
  final String? searchQueryFromAskAnythingScreen;
  const GptScreen({super.key, this.searchQueryFromAskAnythingScreen});

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen> with SingleTickerProviderStateMixin {
  final TextEditingController inputController = TextEditingController();
  final TextEditingController feedbackTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? audioPath;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<Map<String, String>> chatHistory = [];
  String reactionId = '';
  int? _editingIndex;
  int? _currentResponseIndex;

  @override
  void initState() {
    super.initState();
    chatHistory = PrefUtils.getChatHistory();
    _initializeRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.searchQueryFromAskAnythingScreen != null &&
        widget.searchQueryFromAskAnythingScreen!.trim().isNotEmpty) {
      callAPI();
    }
  }

  void callAPI() {
    if (widget.searchQueryFromAskAnythingScreen!.isNotEmpty) {
      setState(() {
        chatHistory.add({
          'question': widget.searchQueryFromAskAnythingScreen!,
          'answer': '',
          'chatId': '',
          'messageId': '',
        });
        _currentResponseIndex = chatHistory.length - 1;
        PrefUtils.setChatHistory(chatHistory);
      });

      // Only call InitiateChatEvent if no chatId exists
      if (PrefUtils.getChatID().isEmpty) {
        BlocProvider.of<HomeFlowBloc>(context).add(
          InitiateChatEvent(
            message: widget.searchQueryFromAskAnythingScreen!,
            isGuest: PrefUtils.getIsGuest(),
            modelName: 'Atlas',
            searchEngine: 'Search',
            edited: false,
            sender: 'user',
            chatId: '',
          ),
        );
      }

      // Always call ChatEvent for the message
      BlocProvider.of<HomeFlowBloc>(context).add(
        ChatEvent(
          message: widget.searchQueryFromAskAnythingScreen!,
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
          insetPadding: EdgeInsets.all(20),
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
                      SizedBox(width: 16),
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
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Divider(),
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
                SizedBox(height: 16),
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
    inputController.dispose();
    feedbackTextController.dispose();
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
              final String ChatID = response['id'];
              PrefUtils.setChatID(ChatID);

            } else if (state is InitiateChatFailure) {
              CommonUtils.showErrorToast(state.failureResponse['message']);
            } else if (state is StoreChatSuccess) {
              final response = state.successResponse;
              final messageId = response['id'];
              if (_currentResponseIndex != null && _currentResponseIndex! < chatHistory.length) {
                setState(() {
                  chatHistory[_currentResponseIndex!]['messageId'] = messageId;
                  PrefUtils.setChatHistory(chatHistory);
                });
              }
              String? latestAnswer;
              if (_currentResponseIndex != null && chatHistory.isNotEmpty) {
                latestAnswer = chatHistory[_currentResponseIndex!]['answer'];
                final currentMessageId = chatHistory[_currentResponseIndex!]['messageId'] ?? '';
                BlocProvider.of<HomeFlowBloc>(context).add(
                  SendAPIResponseEvent(
                    messageId: currentMessageId,
                    apiName: 'Atlas',
                    apiType: 'Chat',
                    apiResponse: latestAnswer!,
                    apiStatus: 'SUCCESS',
                    apiError: '',
                  ),
                );
              }
            } else if (state is StoreChatError) {
              CommonUtils.showErrorToast(state.failureResponse['message']);
            }
            else if (state is SendAPIResponseFailure){
              CommonUtils.showErrorToast(state.failureResponse['message']);
            }
            else if (state is ChatStreamingState) {
              setState(() {
                if (_currentResponseIndex != null && _currentResponseIndex! < chatHistory.length) {
                  String currentAnswer = chatHistory[_currentResponseIndex!]['answer'] ?? '';
                  currentAnswer += state.response;
                  chatHistory[_currentResponseIndex!]['answer'] = currentAnswer;
                  PrefUtils.setChatHistory(chatHistory);
                }
              });
              _scrollToBottom();
            } else if (state is ChatLoadedState) {
              setState(() {
                if (_currentResponseIndex != null && _currentResponseIndex! < chatHistory.length) {
                  chatHistory[_currentResponseIndex!]['answer'] = state.partialResponse;
                  PrefUtils.setChatHistory(chatHistory);
                }
              });

              if (_currentResponseIndex != null && _currentResponseIndex! < chatHistory.length) {
                setState(() {
                  chatHistory[_currentResponseIndex!]['chatId'] = PrefUtils.getChatID();
                  PrefUtils.setChatHistory(chatHistory);
                });
                String? latestQuestion = chatHistory[_currentResponseIndex!]['question'];
                print('Latest Question in InitiateChatSuccess: $latestQuestion');
                BlocProvider.of<HomeFlowBloc>(context).add(
                  StoreChatEvent(
                    message: latestQuestion ?? '',
                    modelName: 'Atlas',
                    searchEngine: 'Search',
                    edited: false,
                    sender: 'user',
                    chatId: PrefUtils.getChatID(),
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
              CommonUtils.showSuccessToast(state.failureResponse['message']);
            } else if (state is ChatFeedbackSuccess) {
              final response = state.successResponse;
              CommonUtils.showSuccessToast(response['message']);
            } else if (state is ChatFeedbackFailure) {
              final response = state.failureResponse;
              Navigator.pop(context);
              CommonUtils.showErrorToast(response['message']);
            } else if (state is ShareChatSuccess) {
              final shareUrl = state.successResponse;
              if (shareUrl.isNotEmpty) {
                SharePlus.instance.share(ShareParams(text: shareUrl));
              } else {
                CommonUtils.showErrorToast('Failed to share: Invalid URL');
              }
            } else if (state is ShareChatFailure) {
              final response = state.failureResponse;
              CommonUtils.showErrorToast(response['message']);
            } else if (state is CheckNetworkConnection) {
              CommonUtils.showErrorToast('No Internet Connection!');
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: chatHistory.length,
                          itemBuilder: (context, index) {
                            final question = chatHistory[index]['question'] ?? '';
                            final answer = chatHistory[index]['answer'] ?? '';
                            final messageId = chatHistory[index]['messageId'] ?? '';
                            final chatId = chatHistory[index]['chatId'] ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  margin: EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.gradientStart),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
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
                                              setState(() {
                                                inputController.text = question;
                                                _editingIndex = index;
                                              });
                                            },
                                            child: Image.asset(
                                              'assets/images/edit.png',
                                              height: 16,
                                              width: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      answer.toString().trim().isEmpty
                                          ? Row(
                                        children: [
                                          SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: AppColors.gradientStart),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Loading...',
                                            style: FTextStyle.defaultText.copyWith(
                                                fontStyle: FontStyle.italic, color: Colors.grey),
                                          ),
                                        ],
                                      )
                                          : Text(
                                        answer,
                                        style: FTextStyle.defaultText,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                AppLocalizations.of(context)!.translate('regenerate'),
                                                style: FTextStyle.selectedRadioColorText,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  BlocProvider.of<HomeFlowBloc>(context).add(ReactOnChatEvent(
                                                    message_id: messageId,
                                                    is_guest: PrefUtils.getIsGuest(),
                                                    is_like: true,
                                                    type: 'MESSAGE',
                                                  ));
                                                },
                                                child: Image.asset(
                                                  'assets/images/thumbsupunlike.png',
                                                  height: 16,
                                                  width: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  BlocProvider.of<HomeFlowBloc>(context).add(ReactOnChatEvent(
                                                    message_id: messageId,
                                                    is_guest: PrefUtils.getIsGuest(),
                                                    is_like: false,
                                                    type: 'MESSAGE',
                                                  ));
                                                },
                                                child: Image.asset(
                                                  'assets/images/thumbsdownunlike.png',
                                                  height: 16,
                                                  width: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: answer));
                                                  CommonUtils.showSuccessToast('Response copied to clipboard!');
                                                },
                                                child: Image.asset(
                                                  'assets/images/unsave.png',
                                                  height: 16,
                                                  width: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Image.asset(
                                                'assets/images/unbookmark.png',
                                                height: 16,
                                                width: 16,
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  if (chatId.isNotEmpty) {
                                                    BlocProvider.of<HomeFlowBloc>(context).add(ShareChatEvent(chatId: chatId));
                                                  } else {
                                                    CommonUtils.showErrorToast('Cannot share: Chat ID is missing');
                                                  }
                                                },
                                                child: Image.asset(
                                                  'assets/images/unshare.png',
                                                  height: 16,
                                                  width: 16,
                                                ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
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
                        scale: isRecording ? _scaleAnimation : AlwaysStoppedAnimation(1.0),
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
                          if (_editingIndex != null) {
                            chatHistory[_editingIndex!]['question'] = message;
                            chatHistory[_editingIndex!]['answer'] = '';
                            _currentResponseIndex = _editingIndex;
                            chatId = chatHistory[_editingIndex!]['chatId'] ?? '';
                            isEdited = true;
                          } else {
                            chatHistory.add({
                              'question': message,
                              'answer': '',
                              'chatId': '',
                              'messageId': '',
                            });
                            _currentResponseIndex = chatHistory.length - 1;
                            chatId = PrefUtils.getChatID();
                            isEdited = false;
                          }
                          PrefUtils.setChatHistory(chatHistory);
                        });

                        // Only call InitiateChatEvent if no chatId exists
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

                        // Always call ChatEvent for the message
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