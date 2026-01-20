import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Screens/CustomAudioPlayer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'dart:developer' as developer;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

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
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool isRecording = false;
  bool isPlaying = false;
  bool isPlayingResponse = false;
  bool isSending = false;
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
  bool _isInitialLoading = false;
  Completer<void>? _initialLoadCompleter;
  bool _isApiProcessing = false;

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
      if (mounted) {
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
      }
    });

    _initializeChatHistory();
  }

  Future<void> _initializeChatHistory() async {
    try {
      if (widget.chatId != null && widget.chatId!.isNotEmpty) {
        _isInitialLoading = true;
        _initialLoadCompleter = Completer<void>();

        // Load chat history from preferences first
        final savedHistory = PrefUtils.getChatHistory();
        chatHistory =
            savedHistory
                .where((chat) => chat['chatId'] == widget.chatId)
                .toList();

        // Then fetch from API
        BlocProvider.of<HomeFlowBloc>(
          context,
        ).add(GetSingleChatHistoryEvent(chatId: widget.chatId!));

        await _initialLoadCompleter?.future;
      } else {
        chatHistory = PrefUtils.getChatHistory();
      }

      if (widget.searchQueryFromAskAnythingScreen != null &&
          widget.searchQueryFromAskAnythingScreen!.trim().isNotEmpty) {
        _handleInitialQuery();
      }
    } catch (e) {
      developer.log('Error initializing chat history: $e', name: 'INIT_ERROR');
      CommonUtils.showErrorToast('Failed to load chat history');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _handleInitialQuery() {
    final query = widget.searchQueryFromAskAnythingScreen!.trim();
    if (query.isNotEmpty) {
      // Check if this query already exists in chat history
      final existingIndex = chatHistory.indexWhere(
        (chat) =>
            chat['question'] == query &&
            chat['answer']?.toString().trim().isEmpty == true,
      );

      if (existingIndex == -1) {
        // Add new query
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

        if (mounted) {
          setState(() {
            chatHistory.add(newChatItem);
            _currentResponseIndex = chatHistory.length - 1;
            _responseLoadingStates[_currentResponseIndex!] = true;
            _isApiProcessing = true; // Set API processing state
            PrefUtils.setChatHistory(chatHistory);
          });
        }

        _sendMessageToAPI(query);
      }
    }
  }

  String _getCurrentChatId() {
    // Use widget.chatId if it exists (when coming from history),
    // otherwise use PrefUtils.getChatID() for new chats
    return widget.chatId ?? PrefUtils.getChatID();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    developer.log('Disposing GptScreen', name: 'DISPOSE');

    // Stop animations
    _animationController.stop();
    _animationController.dispose();

    // Cancel subscription
    _playerStateSubscription?.cancel();

    // Cancel timers
    _scrollTimer?.cancel();

    // Complete completer ONLY if it hasn't been completed yet
    if (_initialLoadCompleter != null && !_initialLoadCompleter!.isCompleted) {
      _initialLoadCompleter!.complete();
    }
    _initialLoadCompleter = null;

    // Stop audio if playing
    if (isPlaying || isPlayingResponse) {
      _audioPlayer.stop().catchError((e) {
        developer.log('Error stopping player on dispose: $e', name: 'DISPOSE');
      });
    }

    // Stop recorder if recording
    if (isRecording) {
      _audioRecorder.stop().catchError((e) {
        developer.log(
          'Error stopping recorder on dispose: $e',
          name: 'DISPOSE',
        );
      });
    }

    // Dispose controllers
    inputController.dispose();
    feedbackTextController.dispose();
    _scrollController.dispose();

    // Dispose audio objects
    _audioRecorder.dispose();
    _audioPlayer.dispose();

    // Clean up temporary files
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
      // Stop any ongoing playback
      await _audioPlayer.stop();

      // Also pause in case stop doesn't work
      await _audioPlayer.pause();

      // Release resources
      await _audioPlayer.release();

      if (mounted) {
        setState(() {
          isPlaying = false;
          isPlayingResponse = false;
          _currentPlayingPath = null;
        });
      }
    } catch (e) {
      developer.log('Error stopping audio: $e', name: 'AUDIO_STOP');

      // Force reset state even if there's an error
      if (mounted) {
        setState(() {
          isPlaying = false;
          isPlayingResponse = false;
          _currentPlayingPath = null;
        });
      }
    }
  }

  void _stopAllAudioSync() {
    try {
      // Stop the player synchronously
      _audioPlayer.stop();
      if (mounted) {
        setState(() {
          isPlaying = false;
          isPlayingResponse = false;
          _currentPlayingPath = null;
        });
      }
    } catch (e) {
      developer.log('Error in synchronous audio stop: $e', name: 'AUDIO_STOP');
    }
  }

  void _onWillPop(bool didPop, Object? result) async {
    if (!didPop) {
      // Stop audio immediately when back is pressed
      await _stopAllAudio();

      // Add a small delay to ensure audio stops completely
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        Navigator.of(context).pop(result);
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
      developer.log('Error deleting audio files: $e', name: 'FILE_CLEANUP');
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
        });
      }
    } catch (e) {
      developer.log('Error starting recording: $e', name: 'RECORDING');
      CommonUtils.showErrorToast('Failed to start recording');
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          isRecording = false;
          _audioPath = path;
          _isApiProcessing = true;
        });
      }
      if (_audioPath != null) {
        await _sendAudioToApi();
      } else {
        CommonUtils.showErrorToast('No recording file found');
        if (mounted) {
          setState(() {
            _isApiProcessing = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error stopping recording: $e', name: 'RECORDING');
      CommonUtils.showErrorToast('Failed to stop recording');
      if (mounted) {
        setState(() {
          isRecording = false;
          _isApiProcessing = false;
        });
      }
    }
  }

  Future<void> _sendAudioToApi() async {
    if (_audioPath == null) return;

    if (mounted) {
      setState(() {
        isSending = true;
        _isApiProcessing = true; // Set API processing state
      });
    }

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

      if (mounted) {
        setState(() {
          chatHistory.add(newChatItem);
          _currentResponseIndex = chatHistory.length - 1;
          _responseLoadingStates[_currentResponseIndex!] = true;
          PrefUtils.setChatHistory(chatHistory);
        });
      }

      BlocProvider.of<HomeFlowBloc>(context).add(
        VoiceConversationEvent(
          audioFile: audioFile,
          language: PrefUtils.getLanguage(),
          sessionId: PrefUtils.getSessionID(),
        ),
      );

      _scrollToBottom();
    } catch (e) {
      developer.log('Error sending audio: $e', name: 'AUDIO_API');
      CommonUtils.showErrorToast('Error sending audio');
      // Remove the loading state if there's an error
      if (mounted && _currentResponseIndex != null) {
        setState(() {
          _responseLoadingStates.remove(_currentResponseIndex);
          _isApiProcessing = false; // Reset on error
          if (chatHistory.isNotEmpty &&
              _currentResponseIndex! < chatHistory.length) {
            chatHistory.removeAt(_currentResponseIndex!);
            PrefUtils.setChatHistory(chatHistory);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) return;

    try {
      if (_currentPlayingPath == _audioPath && isPlaying) {
        // Currently playing this recording → pause it
        await _audioPlayer.pause();
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      } else {
        // Either not playing, or playing something else → start this one
        await _audioPlayer.stop(); // Stop any current playback
        if (mounted) {
          setState(() {
            _currentPlayingPath = _audioPath;
            isPlaying = true;
            isPlayingResponse = false;
          });
        }
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
    } catch (e) {
      developer.log('Error playing recording: $e', name: 'PLAYBACK');
      CommonUtils.showErrorToast('Failed to play recording');
    }
  }

  Future<void> _playResponseAudio() async {
    if (_responseAudioPath == null || !File(_responseAudioPath!).existsSync())
      return;

    try {
      if (_currentPlayingPath == _responseAudioPath && isPlayingResponse) {
        // Currently playing response audio → pause it
        await _audioPlayer.pause();
        if (mounted) {
          setState(() {
            isPlayingResponse = false;
          });
        }
      } else {
        // Start playing response audio
        await _audioPlayer.stop();
        if (mounted) {
          setState(() {
            _currentPlayingPath = _responseAudioPath;
            isPlayingResponse = true;
            isPlaying = false;
          });
        }
        await _audioPlayer.play(DeviceFileSource(_responseAudioPath!));
      }
    } catch (e) {
      developer.log('Error playing response audio: $e', name: 'PLAYBACK');
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
      if (mounted) {
        setState(() {
          _isApiProcessing = true; // Set API processing state
        });
      }

      if (PrefUtils.getChatID().isEmpty && widget.chatId == null) {
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
      developer.log('Error sending message to API: $e', name: 'API_ERROR');
      CommonUtils.showErrorToast('Failed to send message');
      // Clear loading state on error
      if (_currentResponseIndex != null) {
        _responseLoadingStates.remove(_currentResponseIndex);
      }

      if (mounted) {
        setState(() {
          _isApiProcessing = false; // Reset on error
        });
      }
    }
  }

  void _handleUserMessage() {
    final message = inputController.text.trim();
    if (message.isEmpty) return;

    try {
      String chatId = _getCurrentChatId();
      bool isEdited = false;

      if (mounted) {
        setState(() {
          if (_editingIndex != null) {
            // Editing existing message
            chatHistory[_editingIndex!]['question'] = message;
            chatHistory[_editingIndex!]['answer'] = '';
            _currentResponseIndex = _editingIndex;
            _responseLoadingStates[_currentResponseIndex!] = true;
            isEdited = true;
          } else {
            // New message
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
          _isApiProcessing = true; // Set API processing state
          PrefUtils.setChatHistory(chatHistory);
        });
      }

      if (PrefUtils.getChatID().isEmpty && widget.chatId == null) {
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
      developer.log('Error handling user message: $e', name: 'USER_INPUT');
      CommonUtils.showErrorToast('Failed to send message');
      // Clear loading state on error
      if (_currentResponseIndex != null) {
        _responseLoadingStates.remove(_currentResponseIndex);
      }

      if (mounted) {
        setState(() {
          _isApiProcessing = false; // Reset on error
        });
      }
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
    try {
      if (mounted) {
        setState(() {
          chatHistory[index]['answer'] = response.toString();
          _responseLoadingStates.remove(index);
          _isApiProcessing = false; // Reset API processing state
          PrefUtils.setChatHistory(chatHistory);
        });
      }
    } catch (e) {
      developer.log(
        'Error handling chat response: $e',
        name: 'RESPONSE_HANDLER',
      );
      if (mounted) {
        setState(() {
          _isApiProcessing = false; // Reset on error
        });
      }
    }
  }

  void _handleVoiceResponse(dynamic response, int index) {
    try {
      if (response is Map<String, dynamic> && response.containsKey('audio')) {
        final hexString = response['audio'];
        if (_isValidHex(hexString)) {
          final bytes = _hexToBytes(hexString);
          _writeResponseFile(bytes)
              .then((path) {
                if (mounted) {
                  setState(() {
                    _responseAudioPath = path;
                    chatHistory[index]['answer'] = 'Audio Response';
                    _responseLoadingStates.remove(index);
                    _isApiProcessing = false; // Reset API processing state
                    PrefUtils.setChatHistory(chatHistory);
                  });
                }
              })
              .catchError((e) {
                developer.log(
                  'Error writing response file: $e',
                  name: 'VOICE_RESPONSE',
                );
                _handleChatResponse(response, index);
              });
        } else {
          _handleChatResponse(response, index);
        }
      } else if (response is List<int>) {
        _writeResponseFile(response)
            .then((path) {
              if (mounted) {
                setState(() {
                  _responseAudioPath = path;
                  chatHistory[index]['answer'] = 'Audio Response';
                  _responseLoadingStates.remove(index);
                  _isApiProcessing = false; // Reset API processing state
                  PrefUtils.setChatHistory(chatHistory);
                });
              }
            })
            .catchError((e) {
              developer.log(
                'Error writing response file: $e',
                name: 'VOICE_RESPONSE',
              );
              _handleChatResponse({'error': 'Failed to process audio'}, index);
            });
      } else {
        _handleChatResponse(response, index);
      }
    } catch (e) {
      developer.log(
        'Error handling voice response: $e',
        name: 'VOICE_RESPONSE',
      );
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

          if (mounted) {
            // Clear the route
            Navigator.of(context).pop();
          }
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
                  PrefUtils.setChatID(chatID);
                } else if (state is InitiateChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on error
                    });
                  }
                } else if (state is StoreChatSuccess) {
                  final response = state.successResponse;
                  final messageId = response['id'];
                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length &&
                      mounted) {
                    setState(() {
                      chatHistory[_currentResponseIndex!]['messageId'] =
                          messageId;
                      PrefUtils.setChatHistory(chatHistory);
                    });
                  }
                  String? latestAnswer;
                  if (_currentResponseIndex != null && chatHistory.isNotEmpty) {
                    latestAnswer =
                        chatHistory[_currentResponseIndex!]['answer'];
                    final currentMessageId =
                        chatHistory[_currentResponseIndex!]['messageId'] ?? '';
                    if (currentMessageId.isNotEmpty &&
                        latestAnswer != null &&
                        latestAnswer.isNotEmpty) {
                      BlocProvider.of<HomeFlowBloc>(context).add(
                        SendAPIResponseEvent(
                          messageId: currentMessageId,
                          apiName: 'Atlas',
                          apiType: 'Chat',
                          apiResponse: latestAnswer,
                          apiStatus: 'SUCCESS',
                          apiError: '',
                        ),
                      );
                    }
                  }
                } else if (state is StoreChatError) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on error
                    });
                  }
                } else if (state is SendAPIResponseFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on error
                    });
                  }
                } else if (state is ChatStreamingState) {
                  if (mounted) {
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
                  }
                } else if (state is ChatLoadedState) {
                  if (mounted) {
                    setState(() {
                      if (_currentResponseIndex != null &&
                          _currentResponseIndex! < chatHistory.length) {
                        chatHistory[_currentResponseIndex!]['answer'] =
                            state.partialResponse;
                        _responseLoadingStates.remove(_currentResponseIndex);
                        _isApiProcessing =
                            false; // Reset when response is loaded
                        PrefUtils.setChatHistory(chatHistory);
                      }
                    });
                  }
                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    if (mounted) {
                      setState(() {
                        chatHistory[_currentResponseIndex!]['chatId'] =
                            _getCurrentChatId();
                        PrefUtils.setChatHistory(chatHistory);
                      });
                    }
                    String? latestQuestion =
                        chatHistory[_currentResponseIndex!]['question'];
                    if (latestQuestion != null && latestQuestion.isNotEmpty) {
                      BlocProvider.of<HomeFlowBloc>(context).add(
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
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on error
                    });
                  }
                } else if (state is VoiceConversationSuccess) {
                  final response = state.successResponse;
                  if (_currentResponseIndex != null &&
                      _currentResponseIndex! < chatHistory.length) {
                    _handleVoiceResponse(response, _currentResponseIndex!);
                  }
                } else if (state is VoiceConversationFailure) {
                  CommonUtils.showErrorToast(state.failureResponse);
                  if (_currentResponseIndex != null) {
                    _responseLoadingStates.remove(_currentResponseIndex);
                  }
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on error
                    });
                  }
                } else if (state is GetSingleChatHistorySuccess) {
                  final response = state.successResponse;
                  final String chatId =
                      response['chat']['id']?.toString() ?? '';
                  final List<dynamic> messages =
                      response['messages'] as List<dynamic>;

                  if (mounted) {
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
                            final String answer =
                                message['apiResponses']?.isNotEmpty == true
                                    ? message['apiResponses'][0]['api_response']
                                            ?.toString() ??
                                        ''
                                    : '';
                            final bool isBookmarked =
                                message['isBookmarked'] ?? false;
                            final bool isLiked = message['isLiked'] ?? false;
                            final bool isDisliked =
                                message['isDisliked'] ?? false;
                            final localChat = localChatMap[messageId] ?? {};
                            return {
                              'question': question,
                              'answer': answer,
                              'chatId': chatId,
                              'messageId': messageId,
                              'isBookmarked':
                                  isBookmarked ||
                                  localChat['isBookmarked'] == true,
                              'isLiked':
                                  isLiked || localChat['isLiked'] == true,
                              'isDisliked':
                                  isDisliked || localChat['isDisliked'] == true,
                              'isUserAudio': localChat['isUserAudio'] ?? false,
                            };
                          }).toList();
                      PrefUtils.setChatHistory(chatHistory);
                    });
                  }
                  _initialLoadCompleter?.complete();
                } else if (state is GetSingleChatHistoryFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                  _initialLoadCompleter?.complete();
                } else if (state is ReactOnChatSuccess) {
                  final response = state.successResponse;
                  reactionId = response['data']['id'];
                  final messageId = response['data']['message_id'] ?? '';
                  final bool isLike = response['data']['is_like'] ?? false;
                  if (mounted) {
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
                  }
                  _showFeedbackPopup(context);
                  CommonUtils.showSuccessToast(response['message']);
                } else if (state is ReactOnChatFailure) {
                  final messageId = state.failureResponse['message_id'] ?? '';
                  final bool wasLike =
                      state.failureResponse['is_like'] ?? false;
                  if (mounted) {
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
                  }
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is ChatFeedbackSuccess) {
                  CommonUtils.showSuccessToast(
                    state.successResponse['message'],
                  );
                } else if (state is ChatFeedbackFailure) {
                  Navigator.pop(context);
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is ShareChatSuccess) {
                  final shareUrl = state.successResponse;
                  if (shareUrl.isNotEmpty) {
                    Share.share(shareUrl);
                  } else {
                    CommonUtils.showErrorToast('Failed to share: Invalid URL');
                  }
                } else if (state is ShareChatFailure) {
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is CheckNetworkConnectionHomeFlow) {
                  CommonUtils.showErrorToast('No Internet Connection!');
                  if (mounted) {
                    setState(() {
                      _isApiProcessing = false; // Reset on network error
                    });
                  }
                } else if (state is BookmarkChatSuccess) {
                  final messageId = state.successResponse['messageId'];
                  if (mounted) {
                    setState(() {
                      final index = chatHistory.indexWhere(
                        (chat) => chat['messageId'] == messageId,
                      );
                      if (index != -1) {
                        chatHistory[index]['isBookmarked'] = true;
                        PrefUtils.setChatHistory(chatHistory);
                      }
                    });
                  }
                  CommonUtils.showSuccessToast(
                    AppLocalizations.of(
                      context,
                    )!.translate('chatbookmarkedsuccessfully'),
                  );
                } else if (state is BookmarkChatFailure) {
                  final messageId = state.failureResponse['messageId'] ?? '';
                  if (mounted) {
                    setState(() {
                      final index = chatHistory.indexWhere(
                        (chat) => chat['messageId'] == messageId,
                      );
                      if (index != -1) {
                        chatHistory[index]['isBookmarked'] = false;
                        PrefUtils.setChatHistory(chatHistory);
                      }
                    });
                  }
                  CommonUtils.showErrorToast(state.failureResponse['message']);
                } else if (state is UnbookmarkChatSuccess) {
                  final messageId = state.successResponse['messageId'];
                  if (mounted) {
                    setState(() {
                      final index = chatHistory.indexWhere(
                        (chat) => chat['messageId'] == messageId,
                      );
                      if (index != -1) {
                        chatHistory[index]['isBookmarked'] = false;
                        PrefUtils.setChatHistory(chatHistory);
                      }
                    });
                  }
                  CommonUtils.showSuccessToast(
                    AppLocalizations.of(
                      context,
                    )!.translate('chatunbookmarkedsuccessfully'),
                  );
                } else if (state is UnbookmarkChatFailure) {
                  final messageId = state.failureResponse['messageId'] ?? '';
                  if (mounted) {
                    setState(() {
                      final index = chatHistory.indexWhere(
                        (chat) => chat['messageId'] == messageId,
                      );
                      if (index != -1) {
                        chatHistory[index]['isBookmarked'] = true;
                        PrefUtils.setChatHistory(chatHistory);
                      }
                    });
                  }
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
                developer.log(
                  'Error in bloc listener: $e',
                  name: 'BLOC_LISTENER',
                );
                if (mounted) {
                  setState(() {
                    _isApiProcessing = false; // Reset on any error
                  });
                }
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
                                              final chatId =
                                                  chatHistory[index]['chatId']
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

                                              // Skip empty questions
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
                                                                if (mounted) {
                                                                  setState(() {
                                                                    inputController
                                                                            .text =
                                                                        question;
                                                                    _editingIndex =
                                                                        index;
                                                                  });
                                                                }
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
                                                        if (isLoading &&
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
                                                                'Loading...',
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
                                                            .isNotEmpty)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
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
                                                            answer.isEmpty)
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
                                                              Row(
                                                                children: [
                                                                  Image.asset(
                                                                    'assets/images/refresh.png',
                                                                    height: 16,
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
                                                              Row(
                                                                children: [
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      if (messageId
                                                                          .isNotEmpty) {
                                                                        if (mounted) {
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
                                                                        }
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
                                                                        if (mounted) {
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
                                                                        }
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
                                                                        if (mounted) {
                                                                          setState(() {
                                                                            chatHistory[index]['isBookmarked'] =
                                                                                !isBookmarked;
                                                                            PrefUtils.setChatHistory(
                                                                              chatHistory,
                                                                            );
                                                                          });
                                                                        }
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
                                                                      if (chatId
                                                                          .isNotEmpty) {
                                                                        BlocProvider.of<
                                                                          HomeFlowBloc
                                                                        >(
                                                                          context,
                                                                        ).add(
                                                                          ShareChatEvent(
                                                                            chatId:
                                                                                chatId,
                                                                          ),
                                                                        );
                                                                      } else {
                                                                        CommonUtils.showErrorToast(
                                                                          'Cannot share: Chat ID is missing',
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
                                          (isSending)
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
