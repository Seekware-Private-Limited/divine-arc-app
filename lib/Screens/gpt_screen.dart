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

  // Audio state variables
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
  bool _isConvertingAudio = false;

  // File paths
  String? _audioPath;
  String? _responseAudioPath;
  String? _apiResponse;
  String? _currentPlayingPath;
  String reactionId = '';

  // Chat state
  int? _editingIndex;
  int? _currentResponseIndex;
  List<Map<String, dynamic>> chatHistory = [];
  Timer? _scrollTimer;
  Map<int, bool> _responseLoadingStates = {};
  Completer<void>? _initialLoadCompleter;

  // Audio URL tracking
  Map<int, String> _userAudioUrlMap = {}; // Track user audio URLs by index
  Map<int, String> _responseAudioUrlMap =
      {}; // Track response audio URLs by index

  // For tracking current voice conversation
  String? _currentUserAudioUrl;
  String? _currentResponseAudioUrl;

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
        // Load audio URLs from saved history
        _loadAudioUrlsFromHistory();
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

  void _loadAudioUrlsFromHistory() {
    for (int i = 0; i < chatHistory.length; i++) {
      final chat = chatHistory[i];
      if (chat['audio_url'] != null &&
          chat['audio_url'].toString().isNotEmpty) {
        _userAudioUrlMap[i] = chat['audio_url'];
      }

      // Load response audio URLs from API responses
      if (chat['apiResponses'] != null && chat['apiResponses'] is List) {
        final apiResponses = chat['apiResponses'] as List;
        if (apiResponses.isNotEmpty) {
          final response = apiResponses[0];
          if (response['audio_url'] != null &&
              response['audio_url'].toString().isNotEmpty) {
            _responseAudioUrlMap[i] = response['audio_url'];
          }
        }
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
          _currentUserAudioUrl = null;
          _currentResponseAudioUrl = null;
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

      // STEP 1: First upload the user's recording to get userinputurl
      BlocProvider.of<HomeFlowBloc>(
        context,
      ).add(UploadFile(file: _audioPath!, isResponseAudio: false));

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

  Future<String?> _convertWavToMp3(File wavFile) async {
    try {
      // Note: In a real app, you would use a proper audio conversion library like ffmpeg
      // This is a placeholder - implement proper conversion in production
      final dir = await getTemporaryDirectory();
      final mp3Path = '${dir.path}/${_generateRandomId()}_converted.mp3';

      // For now, copy the file with mp3 extension
      // In production, implement proper WAV to MP3 conversion
      final bytes = await wavFile.readAsBytes();
      final mp3File = File(mp3Path);
      await mp3File.writeAsBytes(bytes);

      return mp3Path;
    } catch (e) {
      debugPrint('Error converting WAV to MP3: $e');
      return null;
    }
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
        _currentUserAudioUrl = null;
        _currentResponseAudioUrl = null;
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

    // Don't allow regenerating audio chats
    final bool isUserAudio = chatItem['isUserAudio'] == true;
    if (isUserAudio) {
      CommonUtils.showErrorToast('Cannot regenerate audio messages');
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

  Future<void> _handleVoiceResponse(dynamic response, int index) async {
    try {
      if (response is Map<String, dynamic> && response.containsKey('audio')) {
        final hexString = response['audio'];
        if (_isValidHex(hexString)) {
          final bytes = _hexToBytes(hexString);

          // Write WAV file
          final wavPath = await _writeResponseFile(bytes);
          final wavFile = File(wavPath);

          // Convert WAV to MP3
          setState(() => _isConvertingAudio = true);
          final mp3Path = await _convertWavToMp3(wavFile);

          if (mp3Path != null) {
            final mp3File = File(mp3Path);

            // STEP 4: Upload that MP3 to get useroutputurl
            BlocProvider.of<HomeFlowBloc>(
              context,
            ).add(UploadFile(file: mp3Path, isResponseAudio: true));

            // Store the WAV path for local playback
            setState(() {
              _responseAudioPath = wavPath;
              chatHistory[index]['answer'] = 'Audio Response';
              PrefUtils.setChatHistory(chatHistory);
            });
          } else {
            // Fallback to WAV if conversion fails
            _writeResponseFile(bytes)
                .then((path) {
                  setState(() {
                    _responseAudioPath = path;
                    chatHistory[index]['answer'] = 'Audio Response';
                    _responseLoadingStates.remove(index);
                    _isApiProcessing = false;
                    _isConvertingAudio = false;
                    PrefUtils.setChatHistory(chatHistory);
                  });
                })
                .catchError((e) {
                  _handleChatResponse(response, index);
                  setState(() => _isConvertingAudio = false);
                });
          }
        } else {
          _handleChatResponse(response, index);
          setState(() => _isConvertingAudio = false);
        }
      } else if (response is List<int>) {
        // Handle direct byte array response
        final wavPath = await _writeResponseFile(response);
        final wavFile = File(wavPath);

        // Convert WAV to MP3
        setState(() => _isConvertingAudio = true);
        final mp3Path = await _convertWavToMp3(wavFile);

        if (mp3Path != null) {
          final mp3File = File(mp3Path);

          // STEP 4: Upload that MP3 to get useroutputurl
          BlocProvider.of<HomeFlowBloc>(
            context,
          ).add(UploadFile(file: mp3Path, isResponseAudio: true));

          // Store the WAV path for local playback
          setState(() {
            _responseAudioPath = wavPath;
            chatHistory[index]['answer'] = 'Audio Response';
            PrefUtils.setChatHistory(chatHistory);
          });
        } else {
          // Fallback to WAV if conversion fails
          setState(() {
            _responseAudioPath = wavPath;
            chatHistory[index]['answer'] = 'Audio Response';
            _responseLoadingStates.remove(index);
            _isApiProcessing = false;
            _isConvertingAudio = false;
            PrefUtils.setChatHistory(chatHistory);
          });
        }
      } else {
        _handleChatResponse(response, index);
        setState(() => _isConvertingAudio = false);
      }
    } catch (e) {
      debugPrint('Error handling voice response: $e');
      _handleChatResponse({'error': 'Failed to process response'}, index);
      setState(() => _isConvertingAudio = false);
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
            listener: (context, state) async {
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

                      // Store user audio URL if available
                      if (_currentUserAudioUrl != null) {
                        chatHistory[_currentResponseIndex!]['audio_url'] =
                            _currentUserAudioUrl;
                        _userAudioUrlMap[_currentResponseIndex!] =
                            _currentUserAudioUrl!;
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
                      final String audioUrl =
                          isUserAudio && _currentUserAudioUrl != null
                              ? _currentUserAudioUrl!
                              : '';

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
                } else if (state is UploadFileSuccess) {
                  final newUrl = state.successResponse['url'];
                  final bool isResponseAudio = state.isResponseAudio ?? false;

                  if (isResponseAudio) {
                    // This is the response audio URL (useroutputurl)
                    _currentResponseAudioUrl = newUrl;

                    // Update chat history with response audio URL
                    if (_currentResponseIndex != null &&
                        _currentResponseIndex! < chatHistory.length) {
                      setState(() {
                        chatHistory[_currentResponseIndex!]['hasAudioUrl'] =
                            true;
                        // Store response audio URL
                        _responseAudioUrlMap[_currentResponseIndex!] = newUrl;

                        // Add to apiResponses structure to match API format
                        if (chatHistory[_currentResponseIndex!]['apiResponses'] ==
                            null) {
                          chatHistory[_currentResponseIndex!]['apiResponses'] =
                              [];
                        }

                        final apiResponses =
                            chatHistory[_currentResponseIndex!]['apiResponses']
                                as List;
                        if (apiResponses.isEmpty) {
                          apiResponses.add({
                            'audio_url': newUrl,
                            'api_response': 'Audio Response',
                          });
                        } else {
                          apiResponses[0]['audio_url'] = newUrl;
                        }

                        _responseLoadingStates.remove(_currentResponseIndex);
                        _isApiProcessing = false;
                        _isConvertingAudio = false;
                        PrefUtils.setChatHistory(chatHistory);
                      });

                      // STEP 6: Use useroutputurl in SendAPIResponseEvent
                      final messageId =
                          chatHistory[_currentResponseIndex!]['messageId']
                              ?.toString() ??
                          '';
                      final latestAnswer =
                          chatHistory[_currentResponseIndex!]['answer']
                              ?.toString() ??
                          '';

                      if (messageId.isNotEmpty) {
                        BlocProvider.of<HomeFlowBloc>(context).add(
                          SendAPIResponseEvent(
                            messageId: messageId,
                            apiName: 'Atlas',
                            apiType: 'Chat',
                            apiResponse: latestAnswer,
                            apiStatus: 'SUCCESS',
                            apiError: '',
                            audioUrl: newUrl, // Send response audio URL
                          ),
                        );
                      }
                    }
                  } else {
                    // This is the user audio URL (userinputurl)
                    _currentUserAudioUrl = newUrl;

                    // STEP 2: When that's done, send the VoiceConversationEvent
                    BlocProvider.of<HomeFlowBloc>(context).add(
                      VoiceConversationEvent(
                        audioFile: File(_audioPath!),
                        language: PrefUtils.getLanguage(),
                        sessionId: PrefUtils.getSessionID(),
                      ),
                    );
                  }
                } else if (state is UploadFileFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  if (state.isResponseAudio == true) {
                    setState(() {
                      _isConvertingAudio = false;
                      if (_currentResponseIndex != null) {
                        _responseLoadingStates.remove(_currentResponseIndex);
                        _isApiProcessing = false;
                      }
                    });
                  }
                } else if (state is VoiceConversationSuccess) {
                  final response = state.successResponse;
                  if (kDebugMode) {
                    debugPrint("AUDIO RESPONSE RECEIVED :${response}");
                  }

                  // STEP 3: When VoiceConversationSuccess is received, convert the response to MP3
                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    await _handleVoiceResponse(
                      response,
                      _currentResponseIndex!,
                    );

                    // STEP 5: Use userinputurl in StoreChatEvent
                    if (_currentUserAudioUrl != null) {
                      BlocProvider.of<HomeFlowBloc>(context).add(
                        StoreChatEvent(
                          message: 'Audio Recording',
                          modelName: 'Atlas',
                          searchEngine: 'Search',
                          edited: false,
                          sender: 'user',
                          audioUrl: _currentUserAudioUrl!, // Use userinputurl
                          chatId: _getCurrentChatId(),
                        ),
                      );
                    }
                  }
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
                  setState(() {
                    _isApiProcessing = false;
                    _isConvertingAudio = false;
                  });
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
                          final String userAudioUrl =
                              message['audio_url']?.toString() ?? '';
                          final bool isBookmarked =
                              message['isBookmarked'] ?? false;
                          final bool isLiked = message['isLiked'] ?? false;
                          final bool isDisliked =
                              message['isDisliked'] ?? false;
                          final localChat = localChatMap[messageId] ?? {};

                          // Check if this is a user audio message
                          final bool isUserAudio =
                              question == 'Audio Recording' &&
                              (userAudioUrl.isNotEmpty ||
                                  localChat['isUserAudio'] == true);

                          final Map<String, dynamic> chatItem = {
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
                            'isUserAudio': isUserAudio,
                            'hasAudioUrl': audioUrl.isNotEmpty,
                            'audio_url': userAudioUrl,
                            'apiResponses': apiResponses,
                          };

                          // Store audio URLs
                          final index = chatHistory.length;
                          if (userAudioUrl.isNotEmpty) {
                            _userAudioUrlMap[index] = userAudioUrl;
                          }
                          if (audioUrl.isNotEmpty) {
                            _responseAudioUrlMap[index] = audioUrl;
                          }

                          return chatItem;
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
                debugPrint('Error in bloc listener: $e');
                setState(() {
                  _isApiProcessing = false;
                  _isConvertingAudio = false;
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

                                              // Get user audio URL
                                              final String userAudioUrl =
                                                  _userAudioUrlMap[index] ??
                                                  chatHistory[index]['audio_url']
                                                      ?.toString() ??
                                                  '';

                                              // Get response audio URL
                                              final String
                                              responseAudioUrl =
                                                  _responseAudioUrlMap[index] ??
                                                  ((chatHistory[index]['apiResponses'] !=
                                                              null &&
                                                          chatHistory[index]['apiResponses']
                                                              is List &&
                                                          (chatHistory[index]['apiResponses']
                                                                  as List)
                                                              .isNotEmpty)
                                                      ? (chatHistory[index]['apiResponses']
                                                                  as List)[0]['audio_url']
                                                              ?.toString() ??
                                                          ''
                                                      : '');

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
                                                            // Show edit icon only for non-audio chats
                                                            if (!isUserAudio)
                                                              const SizedBox(
                                                                width: 16,
                                                              ),
                                                            if (!isUserAudio)
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
                                                            hasAudioUrl ||
                                                            userAudioUrl
                                                                .isNotEmpty)
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
                                                              // Show user audio player for user's recording
                                                              if (isUserAudio &&
                                                                  userAudioUrl
                                                                      .isNotEmpty)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.only(
                                                                      top: 8.0,
                                                                      bottom:
                                                                          8.0,
                                                                    ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .end,
                                                                      children: [
                                                                        Text(
                                                                          'Your Recording:',
                                                                          style: FTextStyle.defaultText.copyWith(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.grey,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        CustomAudioPlayer(
                                                                          audioPath:
                                                                              userAudioUrl,
                                                                          isPlaying:
                                                                              _currentPlayingPath ==
                                                                                  userAudioUrl &&
                                                                              isPlaying,
                                                                          onPlayPause:
                                                                              () => _playResponseAudioFromUrl(
                                                                                userAudioUrl,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              // Show AI response audio player
                                                              if (responseAudioUrl
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
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          'AI Response:',
                                                                          style: FTextStyle.defaultText.copyWith(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.grey,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        CustomAudioPlayer(
                                                                          audioPath:
                                                                              responseAudioUrl,
                                                                          isPlaying:
                                                                              _currentPlayingPath ==
                                                                                  responseAudioUrl &&
                                                                              isPlayingResponse,
                                                                          onPlayPause:
                                                                              () => _playResponseAudioFromUrl(
                                                                                responseAudioUrl,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              // Show local audio players for current recording/response
                                                              if (index ==
                                                                      _currentResponseIndex &&
                                                                  _audioPath !=
                                                                      null &&
                                                                  !isRecording &&
                                                                  isUserAudio &&
                                                                  userAudioUrl
                                                                      .isEmpty)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerRight,
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      Text(
                                                                        'Your Recording:',
                                                                        style: FTextStyle.defaultText.copyWith(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                      CustomAudioPlayer(
                                                                        audioPath:
                                                                            _audioPath!,
                                                                        isPlaying:
                                                                            isPlaying,
                                                                        onPlayPause:
                                                                            _playRecording,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              if (index ==
                                                                      _currentResponseIndex &&
                                                                  _responseAudioPath !=
                                                                      null &&
                                                                  responseAudioUrl
                                                                      .isEmpty)
                                                                Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        'AI Response:',
                                                                        style: FTextStyle.defaultText.copyWith(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            4,
                                                                      ),
                                                                      CustomAudioPlayer(
                                                                        audioPath:
                                                                            _responseAudioPath!,
                                                                        isPlaying:
                                                                            isPlayingResponse,
                                                                        onPlayPause:
                                                                            _playResponseAudio,
                                                                      ),
                                                                    ],
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
                                                            !hasAudioUrl &&
                                                            !isUserAudio)
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
                                                        // Show action buttons only for non-audio chats
                                                        if (!isUserAudio &&
                                                            (answer.isNotEmpty ||
                                                                messageId
                                                                    .isNotEmpty ||
                                                                isUserAudio))
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
                      // if (_isConvertingAudio)
                      //   Padding(
                      //     padding: const EdgeInsets.only(bottom: 8.0),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         SizedBox(
                      //           height: 16,
                      //           width: 16,
                      //           child: CircularProgressIndicator(
                      //             strokeWidth: 2,
                      //             color: AppColors.gradientStart,
                      //           ),
                      //         ),
                      //         const SizedBox(width: 10),
                      //         Text(
                      //           'Converting audio to MP3...',
                      //           style: FTextStyle.defaultText.copyWith(
                      //             color: AppColors.gradientStart,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
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
                                  (_isApiProcessing ||
                                          isSending ||
                                          isRecording ||
                                          _isConvertingAudio)
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
                                              isRecording ||
                                              _isConvertingAudio)
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
