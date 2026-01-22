import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Screens/CustomAudioPlayer.dart';
import 'package:record/record.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class GptScreen extends StatefulWidget {
  final String? searchQueryFromAskAnythingScreen;
  final String? chatId;

  const GptScreen({
    super.key,
    this.searchQueryFromAskAnythingScreen,
    this.chatId,
  });

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController inputController = TextEditingController();
  final TextEditingController feedbackTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? audioUrlForCurrentChat;
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool isRecording = false;
  bool isPlaying = false;
  bool isPlayingResponse = false;
  bool isSending = false;
  bool _isInitialLoading = false;
  bool _isApiProcessing = false;

  String? _audioPath;
  String? _responseAudioPath;
  String? _apiResponse;
  String? _currentPlayingPath;
  String reactionId = '';

  int? _editingIndex;
  int? _currentResponseIndex;

  List<Map<String, dynamic>> chatHistory = [];
  Timer? _scrollTimer;
  Map<int, bool> _responseLoadingStates = {};
  Completer<void>? _initialLoadCompleter;

  // Add this map to track audio URLs for each chat item
  Map<String, String> _audioUrlMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (!mounted) return;

      setState(() {
        if (_currentPlayingPath == _audioPath) {
          isPlaying = state == PlayerState.playing;
          isPlayingResponse = false;
        } else if (_currentPlayingPath == _responseAudioPath) {
          isPlayingResponse = state == PlayerState.playing;
          isPlaying = false;
        } else {
          isPlaying = false;
          isPlayingResponse = false;
        }
      });
    });

    _initializeChatHistory();
  }

  Future<void> _initializeChatHistory() async {
    try {
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _isInitialLoading = true;
        _initialLoadCompleter = Completer<void>();

        final savedHistory = PrefUtils.getChatHistory();
        chatHistory =
            savedHistory
                .where((chat) => chat['chatId'] == widget.chatId)
                .toList();

        BlocProvider.of<HomeFlowBloc>(
          context,
        ).add(GetSingleChatHistoryEvent(chatId: widget.chatId!));

        await _initialLoadCompleter?.future;
      } else {
        chatHistory = PrefUtils.getChatHistory();
      }

      if (widget.searchQueryFromAskAnythingScreen?.trim().isNotEmpty == true) {
        _handleInitialQuery();
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to load chat history');
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _handleInitialQuery() {
    final query = widget.searchQueryFromAskAnythingScreen!.trim();
    if (query.isEmpty) return;

    final existingIndex = chatHistory.indexWhere(
      (chat) =>
          chat['question'] == query &&
          chat['answer']?.toString().trim().isEmpty == true,
    );

    if (existingIndex == -1) {
      final newChatItem = {
        'question': query,
        'answer': '',
        'chatId': _getCurrentChatId(),
        'messageId': '',
        'isBookmarked': false,
        'isLiked': false,
        'isDisliked': false,
        'isUserAudio': false,
      };

      setState(() {
        chatHistory.add(newChatItem);
        _currentResponseIndex = chatHistory.length - 1;
        _responseLoadingStates[_currentResponseIndex!] = true;
        _isApiProcessing = true;
        PrefUtils.setChatHistory(chatHistory);
      });

      _sendMessageToAPI(query);
    }
  }

  String _getCurrentChatId() {
    return widget.chatId ?? PrefUtils.getstoredChatID();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _animationController.stop();
    _animationController.dispose();

    _playerStateSubscription?.cancel();
    _scrollTimer?.cancel();

    if (_initialLoadCompleter?.isCompleted == false) {
      _initialLoadCompleter?.complete();
    }

    if (isPlaying || isPlayingResponse) {
      _audioPlayer.stop();
    }

    if (isRecording) {
      _audioRecorder.stop();
    }

    inputController.dispose();
    feedbackTextController.dispose();
    _scrollController.dispose();

    _audioRecorder.dispose();
    _audioPlayer.dispose();

    _cleanupTemporaryFiles();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopAllAudio();
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.pause();
      await _audioPlayer.release();

      if (mounted) {
        setState(() {
          isPlaying = false;
          isPlayingResponse = false;
          _currentPlayingPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          isPlayingResponse = false;
          _currentPlayingPath = null;
        });
      }
    }
  }

  void _cleanupTemporaryFiles() {
    try {
      if (_audioPath != null && File(_audioPath!).existsSync()) {
        File(_audioPath!).deleteSync();
      }
      if (_responseAudioPath != null &&
          File(_responseAudioPath!).existsSync()) {
        File(_responseAudioPath!).deleteSync();
      }
    } catch (e) {
      // Silent cleanup failure
    }
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
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
      _audioPath = '${dir.path}/${_generateRandomId()}.wav';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: _audioPath!,
      );

      if (mounted) {
        setState(() {
          isRecording = true;
          _responseAudioPath = null;
          _apiResponse = null;
          audioUrlForCurrentChat = null; // Reset audio URL for new recording
        });
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to start recording');
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        isRecording = false;
        _audioPath = path;
        _isApiProcessing = true;
      });

      if (_audioPath != null) {
        await _sendAudioToApi();
      } else {
        CommonUtils.showErrorToast('No recording file found');
        setState(() => _isApiProcessing = false);
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to stop recording');
      setState(() {
        isRecording = false;
        _isApiProcessing = false;
      });
    }
  }

  Future<void> _sendAudioToApi() async {
    if (_audioPath == null) return;

    setState(() {
      isSending = true;
      _isApiProcessing = true;
    });

    try {
      final audioFile = File(_audioPath!);
      if (!audioFile.existsSync()) {
        throw Exception('Audio file not found');
      }

      final newChatItem = {
        'question': 'Audio Recording',
        'answer': '',
        'chatId': _getCurrentChatId(),
        'messageId': '',
        'isBookmarked': false,
        'isLiked': false,
        'isDisliked': false,
        'isUserAudio': true,
      };

      setState(() {
        chatHistory.add(newChatItem);
        _currentResponseIndex = chatHistory.length - 1;
        _responseLoadingStates[_currentResponseIndex!] = true;
        PrefUtils.setChatHistory(chatHistory);
      });

      BlocProvider.of<HomeFlowBloc>(context).add(
        VoiceConversationEvent(
          audioFile: audioFile,
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );
      BlocProvider.of<HomeFlowBloc>(context).add(UploadFile(file: _audioPath!));

      _scrollToBottom();
    } catch (e) {
      CommonUtils.showErrorToast('Error sending audio');
      if (_currentResponseIndex != null) {
        setState(() {
          _responseLoadingStates.remove(_currentResponseIndex);
          _isApiProcessing = false;
          if (chatHistory.isNotEmpty &&
              _currentResponseIndex! < chatHistory.length) {
            chatHistory.removeAt(_currentResponseIndex!);
            PrefUtils.setChatHistory(chatHistory);
          }
        });
      }
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) return;

    try {
      if (_currentPlayingPath == _audioPath && isPlaying) {
        await _audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentPlayingPath = _audioPath;
          isPlaying = true;
          isPlayingResponse = false;
        });
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to play recording');
    }
  }

  Future<void> _playResponseAudioFromUrl(String audioUrl) async {
    if (audioUrl.isEmpty) return;

    try {
      if (_currentPlayingPath == audioUrl && isPlayingResponse) {
        await _audioPlayer.pause();
        setState(() => isPlayingResponse = false);
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentPlayingPath = audioUrl;
          isPlayingResponse = true;
          isPlaying = false;
        });
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to play audio response');
    }
  }

  Future<void> _playResponseAudio() async {
    if (_responseAudioPath == null || !File(_responseAudioPath!).existsSync())
      return;

    try {
      if (_currentPlayingPath == _responseAudioPath && isPlayingResponse) {
        await _audioPlayer.pause();
        setState(() => isPlayingResponse = false);
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentPlayingPath = _responseAudioPath;
          isPlayingResponse = true;
          isPlaying = false;
        });
        await _audioPlayer.play(DeviceFileSource(_responseAudioPath!));
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to play response');
    }
  }

  Future<String> _writeResponseFile(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_generateRandomId()}_response.wav';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  bool _isValidHex(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean) && clean.length % 2 == 0;
  }

  List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s+'), '');
    return [
      for (int i = 0; i < clean.length; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ];
  }

  void _sendMessageToAPI(String message) {
    try {
      setState(() => _isApiProcessing = true);

      if (PrefUtils.getstoredChatID().isEmpty && widget.chatId == null) {
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
      }

      BlocProvider.of<HomeFlowBloc>(context).add(
        ChatEvent(
          message: message,
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );

      _scrollToBottom();
    } catch (e) {
      CommonUtils.showErrorToast('Failed to send message');
      if (_currentResponseIndex != null) {
        _responseLoadingStates.remove(_currentResponseIndex);
      }
      setState(() => _isApiProcessing = false);
    }
  }

  void _handleUserMessage() {
    final message = inputController.text.trim();
    if (message.isEmpty) return;

    try {
      final chatId = _getCurrentChatId();
      bool isEdited = false;

      setState(() {
        if (_editingIndex != null) {
          chatHistory[_editingIndex!]['question'] = message;
          chatHistory[_editingIndex!]['answer'] = '';
          _currentResponseIndex = _editingIndex;
          _responseLoadingStates[_currentResponseIndex!] = true;
          isEdited = true;
        } else {
          final newChatItem = {
            'question': message,
            'answer': '',
            'chatId': chatId,
            'messageId': '',
            'isBookmarked': false,
            'isLiked': false,
            'isDisliked': false,
            'isUserAudio': false,
          };
          chatHistory.add(newChatItem);
          _currentResponseIndex = chatHistory.length - 1;
          _responseLoadingStates[_currentResponseIndex!] = true;
          isEdited = false;
        }
        _isApiProcessing = true;
        audioUrlForCurrentChat = null;
        PrefUtils.setChatHistory(chatHistory);
      });

      if (PrefUtils.getstoredChatID().isEmpty && widget.chatId == null) {
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
    } catch (e) {
      CommonUtils.showErrorToast('Failed to send message');
      if (_currentResponseIndex != null) {
        _responseLoadingStates.remove(_currentResponseIndex);
      }
      setState(() => _isApiProcessing = false);
    }
  }

  void _handleRegenerate(int index) {
    final chatItem = chatHistory[index];
    final String question = chatItem['question']?.trim() ?? '';

    if (question.isEmpty) {
      CommonUtils.showErrorToast('Cannot regenerate: No question found');
      return;
    }

    setState(() {
      chatHistory[index]['answer'] = '';
      chatHistory[index]['isRegenerating'] = true;
      _responseLoadingStates[index] = true;
      _currentResponseIndex = index;
      _isApiProcessing = true;
      PrefUtils.setChatHistory(chatHistory);
    });

    _scrollToBottom();

    try {
      BlocProvider.of<HomeFlowBloc>(context).add(
        ChatEvent(
          message: question,
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );
    } catch (e) {
      CommonUtils.showErrorToast('Failed to regenerate');
      setState(() {
        chatHistory[index]['isRegenerating'] = false;
        _responseLoadingStates.remove(index);
        _isApiProcessing = false;
      });
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
            side: const BorderSide(color: AppColors.gradientStart),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
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
                      hintText: AppLocalizations.of(
                        context,
                      )!.translate('enterFeedbackHere'),
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
                      BlocProvider.of<HomeFlowBloc>(context).add(
                        ChatFeedbackEvent(
                          reactionId: reactionId,
                          feedbackText: feedbackText,
                        ),
                      );
                      CommonUtils.showSuccessToast(
                        AppLocalizations.of(
                          context,
                        )!.translate('feedsubmittedsuccessfully'),
                      );
                    } else {
                      CommonUtils.showErrorToast(
                        AppLocalizations.of(
                          context,
                        )!.translate('pleaseenterfeedback'),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
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

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleChatResponse(Map<String, dynamic> response, int index) {
    setState(() {
      chatHistory[index]['answer'] = response.toString();
      _responseLoadingStates.remove(index);
      _isApiProcessing = false;
      PrefUtils.setChatHistory(chatHistory);
    });
  }

  void _handleVoiceResponse(dynamic response, int index) {
    try {
      if (response is Map<String, dynamic> && response.containsKey('audio')) {
        final hexString = response['audio'];
        if (_isValidHex(hexString)) {
          final bytes = _hexToBytes(hexString);
          _writeResponseFile(bytes)
              .then((path) {
                setState(() {
                  _responseAudioPath = path;
                  chatHistory[index]['answer'] = 'Audio Response';
                  _responseLoadingStates.remove(index);
                  _isApiProcessing = false;
                  PrefUtils.setChatHistory(chatHistory);
                });
              })
              .catchError((e) {
                _handleChatResponse(response, index);
              });
        } else {
          _handleChatResponse(response, index);
        }
      } else if (response is List<int>) {
        _writeResponseFile(response)
            .then((path) {
              setState(() {
                _responseAudioPath = path;
                chatHistory[index]['answer'] = 'Audio Response';
                _responseLoadingStates.remove(index);
                _isApiProcessing = false;
                PrefUtils.setChatHistory(chatHistory);
              });
            })
            .catchError((e) {
              _handleChatResponse({'error': 'Failed to process audio'}, index);
            });
      } else {
        _handleChatResponse(response, index);
      }
    } catch (e) {
      _handleChatResponse({'error': 'Failed to process response'}, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _stopAllAudio();
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.GlobalBG,
        body: SafeArea(
          child: BlocListener<HomeFlowBloc, HomeFlowState>(
            listener: (context, state) {
              try {
                if (state is InitiateChatSuccess) {
                  final response = state.successResponse;
                  final String chatID = response['id'];
                  PrefUtils.setstoredChatID(chatID);
                } else if (state is InitiateChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  setState(() => _isApiProcessing = false);
                } else if (state is StoreChatSuccess) {
                  final response = state.successResponse;
                  final newMessageId = response['id']?.toString() ?? '';

                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    setState(() {
                      final existingMessageId =
                          chatHistory[_currentResponseIndex!]['messageId']
                              ?.toString() ??
                          '';
                      final bool isRegeneration =
                          chatHistory[_currentResponseIndex!]['isRegenerating'] ==
                          true;

                      if (!isRegeneration && existingMessageId.isEmpty) {
                        chatHistory[_currentResponseIndex!]['messageId'] =
                            newMessageId;
                        PrefUtils.setEdittedMessageID(newMessageId);
                      }

                      PrefUtils.setChatHistory(chatHistory);
                    });
                  }

                  if (_currentResponseIndex != null && chatHistory.isNotEmpty) {
                    final latestAnswer =
                        chatHistory[_currentResponseIndex!]['answer'];
                    final existingMessageId =
                        chatHistory[_currentResponseIndex!]['messageId']
                            ?.toString() ??
                        '';
                    final bool isRegeneration =
                        chatHistory[_currentResponseIndex!]['isRegenerating'] ==
                        true;
                    final messageIdToUse =
                        isRegeneration && existingMessageId.isNotEmpty
                            ? existingMessageId
                            : newMessageId;

                    // Check if this is an audio chat (user audio message)
                    final bool isUserAudio =
                        chatHistory[_currentResponseIndex!]['isUserAudio'] ==
                        true;

                    if (messageIdToUse.isNotEmpty) {
                      // Get the audio URL if it's an audio chat
                      final audioUrl =
                          isUserAudio
                              ? audioUrlForCurrentChat ??
                                  '' // Use the stored audio URL
                              : ''; // Empty string for text chats

                      BlocProvider.of<HomeFlowBloc>(context).add(
                        SendAPIResponseEvent(
                          messageId: messageIdToUse,
                          apiName: 'Atlas',
                          apiType: 'Chat',
                          apiResponse: latestAnswer,
                          apiStatus: 'SUCCESS',
                          apiError: '',
                          audioUrl: audioUrl, // Send audio URL for audio chats
                        ),
                      );
                    }
                  }
                } else if (state is StoreChatError) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  setState(() => _isApiProcessing = false);
                } else if (state is SendAPIResponseFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  setState(() => _isApiProcessing = false);
                } else if (state is SendRegenerateAPIResponseSuccess) {
                  chatHistory[_currentResponseIndex!]['isRegenerating'] = false;
                } else if (state is ChatStreamingState) {
                  setState(() {
                    if (_currentResponseIndex != null &&
                        _currentResponseIndex! < chatHistory.length) {
                      String currentAnswer =
                          chatHistory[_currentResponseIndex!]['answer'] ?? '';
                      currentAnswer += state.response;
                      chatHistory[_currentResponseIndex!]['answer'] =
                          currentAnswer;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });
                } else if (state is ChatLoadedState) {
                  setState(() {
                    if (_currentResponseIndex != null &&
                        _currentResponseIndex! < chatHistory.length) {
                      chatHistory[_currentResponseIndex!]['answer'] =
                          state.partialResponse;
                      _responseLoadingStates.remove(_currentResponseIndex);
                      _isApiProcessing = false;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });

                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    setState(() {
                      chatHistory[_currentResponseIndex!]['chatId'] =
                          _getCurrentChatId();
                      PrefUtils.setChatHistory(chatHistory);
                    });

                    final latestQuestion =
                        chatHistory[_currentResponseIndex!]['question'];
                    final bool isRegeneration =
                        chatHistory[_currentResponseIndex!]['isRegenerating'] ==
                        true;

                    if (latestQuestion != null && latestQuestion.isNotEmpty) {
                      isRegeneration
                          ? BlocProvider.of<HomeFlowBloc>(context).add(
                            StoreEdittedChatEvent(
                              message: latestQuestion,
                              modelName: 'Atlas',
                              searchEngine: 'Search',
                              edited: true,
                              sender: 'user',
                              chatId: _getCurrentChatId(),
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
                              chatId: _getCurrentChatId(),
                            ),
                          );
                    }
                  }
                } else if (state is ChatErrorState) {
                  CommonUtils.showErrorToast(state.error['message']);
                  if (_currentResponseIndex != null) {
                    _responseLoadingStates.remove(_currentResponseIndex);
                  }
                  setState(() => _isApiProcessing = false);
                } else if (state is VoiceConversationSuccess) {
                  final response = state.successResponse;
                  if (kDebugMode) {
                    debugPrint("AUDIO RESPONSE RECEIVED :${response}");
                  }
                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    _handleVoiceResponse(response, _currentResponseIndex!);
                  }
                } else if (state is UploadFileSuccess) {
                  final newUrl = state.successResponse['url'];
                  audioUrlForCurrentChat = newUrl;
                  BlocProvider.of<HomeFlowBloc>(context).add(
                    StoreChatEvent(
                      message: 'Audio Response',
                      modelName: 'Atlas',
                      searchEngine: 'Search',
                      edited: false,
                      sender: 'user',
                      audioUrl: newUrl,
                      chatId: _getCurrentChatId(),
                    ),
                  );
                } else if (state is UploadFileFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is StoreEdittedChatSuccess) {
                  final response = state.successResponse;
                  final newMessageId = response['id']?.toString() ?? '';

                  if (_currentResponseIndex != null && chatHistory.isNotEmpty) {
                    final latestAnswer =
                        chatHistory[_currentResponseIndex!]['answer'];
                    final existingMessageId =
                        chatHistory[_currentResponseIndex!]['messageId']
                            ?.toString() ??
                        '';
                    final bool isRegeneration =
                        chatHistory[_currentResponseIndex!]['isRegenerating'] ==
                        true;
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
                } else if (state is VoiceConversationFailure) {
                  CommonUtils.showErrorToast(state.failureResponse);
                  if (_currentResponseIndex != null) {
                    _responseLoadingStates.remove(_currentResponseIndex);
                  }
                  setState(() => _isApiProcessing = false);
                } else if (state is GetSingleChatHistorySuccess) {
                  final response = state.successResponse;
                  final String chatId =
                      response['chat']['id']?.toString() ?? '';
                  final List<dynamic> messages =
                      response['messages'] as List<dynamic>;

                  setState(() {
                    final Map<String, Map<String, dynamic>> localChatMap = {
                      for (var chat in chatHistory) chat['messageId']: chat,
                    };

                    chatHistory =
                        messages.map<Map<String, dynamic>>((message) {
                          final String messageId =
                              message['id']?.toString() ?? '';
                          final String question =
                              message['message']?.toString() ?? '';
                          final List<dynamic> apiResponses =
                              message['apiResponses'] as List<dynamic>? ?? [];
                          final String answer =
                              apiResponses.isNotEmpty
                                  ? apiResponses[0]['api_response']
                                          ?.toString() ??
                                      ''
                                  : '';
                          final String audioUrl =
                              apiResponses.isNotEmpty
                                  ? apiResponses[0]['audio_url']?.toString() ??
                                      ''
                                  : '';
                          final bool isBookmarked =
                              message['isBookmarked'] ?? false;
                          final bool isLiked = message['isLiked'] ?? false;
                          final bool isDisliked =
                              message['isDisliked'] ?? false;
                          final localChat = localChatMap[messageId] ?? {};

                          // Store audio URL in the map
                          if (audioUrl.isNotEmpty) {
                            _audioUrlMap[messageId] = audioUrl;
                          }

                          return {
                            'question': question,
                            'answer': answer,
                            'chatId': chatId,
                            'messageId': messageId,
                            'isBookmarked':
                                isBookmarked ||
                                localChat['isBookmarked'] == true,
                            'isLiked': isLiked || localChat['isLiked'] == true,
                            'isDisliked':
                                isDisliked || localChat['isDisliked'] == true,
                            'isUserAudio': localChat['isUserAudio'] ?? false,
                            'hasAudioUrl': audioUrl.isNotEmpty,
                          };
                        }).toList();

                    PrefUtils.setChatHistory(chatHistory);
                  });

                  _initialLoadCompleter?.complete();
                } else if (state is GetSingleChatHistoryFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  _initialLoadCompleter?.complete();
                } else if (state is ReactOnChatSuccess) {
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

                  _showFeedbackPopup(context);
                  CommonUtils.showSuccessToast(response['message']);
                } else if (state is ReactOnChatFailure) {
                  final messageId = state.failureResponse['message_id'] ?? '';
                  final bool wasLike =
                      state.failureResponse['is_like'] ?? false;

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
                } else if (state is ChatFeedbackSuccess) {
                  CommonUtils.showSuccessToast(
                    state.successResponse['message'],
                  );
                } else if (state is ChatFeedbackFailure) {
                  Navigator.pop(context);
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is CheckNetworkConnectionHomeFlow) {
                  CommonUtils.showErrorToast('No Internet Connection!');
                  setState(() => _isApiProcessing = false);
                } else if (state is BookmarkChatSuccess) {
                  final messageId = state.successResponse['messageId'];
                  setState(() {
                    final index = chatHistory.indexWhere(
                      (chat) => chat['messageId'] == messageId,
                    );
                    if (index != -1) {
                      chatHistory[index]['isBookmarked'] = true;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });
                  CommonUtils.showSuccessToast(
                    AppLocalizations.of(
                      context,
                    )!.translate('chatbookmarkedsuccessfully'),
                  );
                } else if (state is BookmarkChatFailure) {
                  final messageId = state.failureResponse['messageId'] ?? '';
                  setState(() {
                    final index = chatHistory.indexWhere(
                      (chat) => chat['messageId'] == messageId,
                    );
                    if (index != -1) {
                      chatHistory[index]['isBookmarked'] = false;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is UnbookmarkChatSuccess) {
                  final messageId = state.successResponse['messageId'];
                  setState(() {
                    final index = chatHistory.indexWhere(
                      (chat) => chat['messageId'] == messageId,
                    );
                    if (index != -1) {
                      chatHistory[index]['isBookmarked'] = false;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });
                  CommonUtils.showSuccessToast(
                    AppLocalizations.of(
                      context,
                    )!.translate('chatunbookmarkedsuccessfully'),
                  );
                } else if (state is UnbookmarkChatFailure) {
                  final messageId = state.failureResponse['messageId'] ?? '';
                  setState(() {
                    final index = chatHistory.indexWhere(
                      (chat) => chat['messageId'] == messageId,
                    );
                    if (index != -1) {
                      chatHistory[index]['isBookmarked'] = true;
                      PrefUtils.setChatHistory(chatHistory);
                    }
                  });
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is SessionExpiredStateHome) {
                  CommonUtils.showErrorToast(state.message);
                  PrefUtils.clearAll();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                setState(() => _isApiProcessing = false);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          const LanguageDropdown(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child:
                            _isInitialLoading
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      LoadingAnimationWidget.staggeredDotsWave(
                                        color: AppColors.gradientStart,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Loading...',
                                        style: FTextStyle.defaultText.copyWith(
                                          color: AppColors.gradientStart,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Visibility(
                                  visible: chatHistory.isNotEmpty,
                                  replacement: Center(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.translate('nochathistory'),
                                      style: FTextStyle.defaultText.copyWith(
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.gradientStart,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      child: Column(
                                        children: [
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: chatHistory.length,
                                            itemBuilder: (context, index) {
                                              final question =
                                                  chatHistory[index]['question']
                                                      ?.toString()
                                                      .trim() ??
                                                  '';
                                              final answer =
                                                  chatHistory[index]['answer']
                                                      ?.toString()
                                                      .trim() ??
                                                  '';
                                              final messageId =
                                                  chatHistory[index]['messageId']
                                                      ?.toString()
                                                      .trim() ??
                                                  '';
                                              final bool isBookmarked =
                                                  chatHistory[index]['isBookmarked'] ??
                                                  false;
                                              final bool isLiked =
                                                  chatHistory[index]['isLiked'] ??
                                                  false;
                                              final bool isDisliked =
                                                  chatHistory[index]['isDisliked'] ??
                                                  false;
                                              final bool isUserAudio =
                                                  chatHistory[index]['isUserAudio'] ??
                                                  false;
                                              final bool isLoading =
                                                  _responseLoadingStates[index] ??
                                                  false;
                                              final bool hasAudioUrl =
                                                  chatHistory[index]['hasAudioUrl'] ??
                                                  false;
                                              final String audioUrl =
                                                  _audioUrlMap[messageId] ?? '';

                                              if (question.isEmpty)
                                                return const SizedBox();

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 20,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(
                                                        color:
                                                            AppColors
                                                                .gradientStart,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
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
                                                            const SizedBox(
                                                              width: 16,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  inputController
                                                                          .text =
                                                                      question;
                                                                  _editingIndex =
                                                                      index;
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
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        if (_responseLoadingStates[index] ==
                                                                true &&
                                                            answer.isEmpty)
                                                          Row(
                                                            children: [
                                                              SizedBox(
                                                                height: 16,
                                                                width: 16,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color:
                                                                      AppColors
                                                                          .gradientStart,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Text(
                                                                (chatHistory[index]['isRegenerating']
                                                                            as bool? ??
                                                                        false)
                                                                    ? 'Regenerating...'
                                                                    : 'Loading...',
                                                                style: FTextStyle
                                                                    .defaultText
                                                                    .copyWith(
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic,
                                                                      color:
                                                                          Colors
                                                                              .grey,
                                                                    ),
                                                              ),
                                                            ],
                                                          )
                                                        else if (answer
                                                                .isNotEmpty ||
                                                            hasAudioUrl)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              if (answer
                                                                      .trim()
                                                                      .isNotEmpty &&
                                                                  answer !=
                                                                      'Audio Response')
                                                                MarkdownBody(
                                                                  data: answer,
                                                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                                                    Theme.of(
                                                                      context,
                                                                    ),
                                                                  ).copyWith(
                                                                    p:
                                                                        FTextStyle
                                                                            .defaultText,
                                                                  ),
                                                                ),
                                                              // Show audio player for API audio responses
                                                              if (hasAudioUrl &&
                                                                  audioUrl
                                                                      .isNotEmpty)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          top:
                                                                              8.0,
                                                                        ),
                                                                    child: CustomAudioPlayer(
                                                                      audioPath:
                                                                          audioUrl,
                                                                      isPlaying:
                                                                          _currentPlayingPath ==
                                                                              audioUrl &&
                                                                          isPlayingResponse,
                                                                      onPlayPause:
                                                                          () => _playResponseAudioFromUrl(
                                                                            audioUrl,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (index ==
                                                                      _currentResponseIndex &&
                                                                  _audioPath !=
                                                                      null &&
                                                                  !isRecording &&
                                                                  isUserAudio)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child: CustomAudioPlayer(
                                                                    audioPath:
                                                                        _audioPath!,
                                                                    isPlaying:
                                                                        isPlaying,
                                                                    onPlayPause:
                                                                        _playRecording,
                                                                  ),
                                                                ),
                                                              if (index ==
                                                                      _currentResponseIndex &&
                                                                  _responseAudioPath !=
                                                                      null)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: CustomAudioPlayer(
                                                                    audioPath:
                                                                        _responseAudioPath!,
                                                                    isPlaying:
                                                                        isPlayingResponse,
                                                                    onPlayPause:
                                                                        _playResponseAudio,
                                                                  ),
                                                                ),
                                                              if (index ==
                                                                      _currentResponseIndex &&
                                                                  _apiResponse !=
                                                                      null)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top:
                                                                            8.0,
                                                                      ),
                                                                  child: Text(
                                                                    _apiResponse!,
                                                                    style: const TextStyle(
                                                                      color:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                    maxLines: 5,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                            ],
                                                          )
                                                        else if (!isLoading &&
                                                            answer.isEmpty &&
                                                            !hasAudioUrl)
                                                          Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.translate(
                                                              'noresponsereceived',
                                                            ),
                                                            style: FTextStyle
                                                                .defaultText
                                                                .copyWith(
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                          ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        if (answer.isNotEmpty ||
                                                            messageId
                                                                .isNotEmpty)
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              GestureDetector(
                                                                onTap:
                                                                    () =>
                                                                        _handleRegenerate(
                                                                          index,
                                                                        ),
                                                                child: Row(
                                                                  children: [
                                                                    Image.asset(
                                                                      'assets/images/refresh.png',
                                                                      height:
                                                                          16,
                                                                      width: 16,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 10,
                                                                    ),
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
                                                              ),
                                                              Row(
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (messageId
                                                                          .isNotEmpty) {
                                                                        setState(() {
                                                                          chatHistory[index]['isLiked'] =
                                                                              !isLiked;
                                                                          if (chatHistory[index]['isLiked'] ==
                                                                              true) {
                                                                            chatHistory[index]['isDisliked'] =
                                                                                false;
                                                                          }
                                                                          PrefUtils.setChatHistory(
                                                                            chatHistory,
                                                                          );
                                                                        });
                                                                        BlocProvider.of<
                                                                          HomeFlowBloc
                                                                        >(
                                                                          context,
                                                                        ).add(
                                                                          ReactOnChatEvent(
                                                                            message_id:
                                                                                messageId,
                                                                            is_guest:
                                                                                PrefUtils.getIsGuest(),
                                                                            is_like:
                                                                                !isLiked,
                                                                            type:
                                                                                'MESSAGE',
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        CommonUtils.showErrorToast(
                                                                          'Cannot like: Message ID is missing',
                                                                        );
                                                                      }
                                                                    },
                                                                    child: Image.asset(
                                                                      isLiked
                                                                          ? 'assets/images/thumbsuplike.png'
                                                                          : 'assets/images/thumbsupunlike.png',
                                                                      height:
                                                                          16,
                                                                      width: 16,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (messageId
                                                                          .isNotEmpty) {
                                                                        setState(() {
                                                                          chatHistory[index]['isDisliked'] =
                                                                              !isDisliked;
                                                                          if (chatHistory[index]['isDisliked'] ==
                                                                              true) {
                                                                            chatHistory[index]['isLiked'] =
                                                                                false;
                                                                          }
                                                                          PrefUtils.setChatHistory(
                                                                            chatHistory,
                                                                          );
                                                                        });
                                                                        BlocProvider.of<
                                                                          HomeFlowBloc
                                                                        >(
                                                                          context,
                                                                        ).add(
                                                                          ReactOnChatEvent(
                                                                            message_id:
                                                                                messageId,
                                                                            is_guest:
                                                                                PrefUtils.getIsGuest(),
                                                                            is_like:
                                                                                isDisliked,
                                                                            type:
                                                                                'MESSAGE',
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        CommonUtils.showErrorToast(
                                                                          'Cannot dislike: Message ID is missing',
                                                                        );
                                                                      }
                                                                    },
                                                                    child: Image.asset(
                                                                      isDisliked
                                                                          ? 'assets/images/thumbsdownlike.png'
                                                                          : 'assets/images/thumbsdownunlike.png',
                                                                      height:
                                                                          16,
                                                                      width: 16,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (answer
                                                                          .isNotEmpty) {
                                                                        Clipboard.setData(
                                                                          ClipboardData(
                                                                            text:
                                                                                answer,
                                                                          ),
                                                                        );
                                                                        CommonUtils.showSuccessToast(
                                                                          AppLocalizations.of(
                                                                            context,
                                                                          )!.translate(
                                                                            'responsecopied',
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                    child: Image.asset(
                                                                      'assets/images/unsave.png',
                                                                      height:
                                                                          16,
                                                                      width: 16,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (messageId
                                                                          .isNotEmpty) {
                                                                        setState(() {
                                                                          chatHistory[index]['isBookmarked'] =
                                                                              !isBookmarked;
                                                                          PrefUtils.setChatHistory(
                                                                            chatHistory,
                                                                          );
                                                                        });
                                                                        BlocProvider.of<
                                                                          HomeFlowBloc
                                                                        >(
                                                                          context,
                                                                        ).add(
                                                                          isBookmarked
                                                                              ? UnbookmarkChat(
                                                                                messageId:
                                                                                    messageId,
                                                                              )
                                                                              : BookmarkChat(
                                                                                messageId:
                                                                                    messageId,
                                                                              ),
                                                                        );
                                                                      } else {
                                                                        CommonUtils.showErrorToast(
                                                                          'Cannot bookmark: Message ID is missing',
                                                                        );
                                                                      }
                                                                    },
                                                                    child: Image.asset(
                                                                      isBookmarked
                                                                          ? 'assets/images/bookmark.png'
                                                                          : 'assets/images/unbookmark.png',
                                                                      height:
                                                                          16,
                                                                      width: 16,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (question
                                                                              .isNotEmpty &&
                                                                          answer
                                                                              .isNotEmpty) {
                                                                        final shareText =
                                                                            '''Question: $question

Answer: $answer''';
                                                                        Share.share(
                                                                          shareText,
                                                                        );
                                                                        CommonUtils.showSuccessToast(
                                                                          'Sharing conversation...',
                                                                        );
                                                                      } else if (question
                                                                              .isNotEmpty &&
                                                                          answer
                                                                              .isEmpty) {
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
                                                                      height:
                                                                          16,
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
                                if (isRecording)
                                  AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Container(
                                        height:
                                            35 +
                                            (_animationController.value * 5),
                                        width:
                                            35 +
                                            (_animationController.value * 5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.gradientStart
                                                  .withOpacity(
                                                    0.3 *
                                                        (1 -
                                                            _animationController
                                                                .value),
                                                  ),
                                              AppColors.gradientEnd.withOpacity(
                                                0.3 *
                                                    (1 -
                                                        _animationController
                                                            .value),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ScaleTransition(
                                  scale:
                                      isRecording
                                          ? _scaleAnimation
                                          : const AlwaysStoppedAnimation(1.0),
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
                                      gradient:
                                          isRecording
                                              ? LinearGradient(
                                                colors: [
                                                  AppColors.gradientStart,
                                                  AppColors.gradientEnd,
                                                ],
                                              )
                                              : null,
                                      color: isRecording ? null : Colors.white,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        isRecording ? Icons.stop : Icons.mic,
                                        size: 20,
                                        color:
                                            isRecording
                                                ? Colors.white
                                                : AppColors.gradientStart,
                                      ),
                                      onPressed:
                                          isSending
                                              ? null
                                              : () async {
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
                              onTap:
                                  (_isApiProcessing || isSending || isRecording)
                                      ? null
                                      : _handleUserMessage,
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
                                  color:
                                      (_isApiProcessing ||
                                              isSending ||
                                              isRecording)
                                          ? Colors.grey
                                          : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSending)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.gradientStart,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sending to API...',
                                style: FTextStyle.defaultText.copyWith(
                                  color: AppColors.gradientStart,
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
      ),
    );
  }
}
