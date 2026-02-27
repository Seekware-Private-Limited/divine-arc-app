import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:record/record.dart';

mixin GptScreenMethods<T extends StatefulWidget> on State<T> {
  // These getters must be implemented by the state class
  TextEditingController get inputController;
  TextEditingController get feedbackTextController;
  ScrollController get scrollController;

  dynamic get audioRecorder;
  dynamic get audioPlayer;

  bool get isRecording;
  set isRecording(bool value);

  bool get isApiProcessing;
  set isApiProcessing(bool value);

  bool get isConvertingAudio;
  set isConvertingAudio(bool value);

  bool get isInitialLoading;
  set isInitialLoading(bool value);

  String? get audioPath;
  set audioPath(String? value);

  String? get responseAudioPath;
  set responseAudioPath(String? value);

  String? get apiResponse;
  set apiResponse(String? value);

  String get reactionId;
  set reactionId(String value);

  int? get editingIndex;
  set editingIndex(int? value);

  int? get currentResponseIndex;
  set currentResponseIndex(int? value);

  List<Map<String, dynamic>> get chatHistory;
  set chatHistory(List<Map<String, dynamic>> value);

  Timer? get scrollTimer;
  set scrollTimer(Timer? value);

  Map<int, bool> get responseLoadingStates;
  Completer<void>? get initialLoadCompleter;
  set initialLoadCompleter(Completer<void>? value);

  Map<int, String> get userAudioUrlMap;
  Map<int, String> get responseAudioUrlMap;

  String? get currentUserAudioUrl;
  set currentUserAudioUrl(String? value);

  String? get currentResponseAudioUrl;
  set currentResponseAudioUrl(String? value);

  int? get currentlyPlayingIndex;
  set currentlyPlayingIndex(int? value);

  String? get currentlyPlayingUrl;
  set currentlyPlayingUrl(String? value);

  bool get isPlaying;
  set isPlaying(bool value);

  // Widget properties that need to be accessed
  String? get searchQueryFromAskAnythingScreen;
  String? get chatId;

  // NEW: Method to reset audio state
  void _resetAudioState() {
    if (mounted) {
      setState(() {
        responseAudioPath = null;
        apiResponse = null;
        // Don't reset audioPath here - it's needed for current recording
        // Don't reset currentUserAudioUrl/currentResponseAudioUrl - they're per chat
      });
    }
  }

  // Methods
  Future<void> initializeChatHistory() async {
    try {
      if (chatId != null && chatId!.isNotEmpty) {
        isInitialLoading = true;
        initialLoadCompleter = Completer<void>();

        final savedHistory = PrefUtils.getChatHistory();
        chatHistory =
            savedHistory.where((chat) => chat['chatId'] == chatId).toList();

        BlocProvider.of<HomeFlowBloc>(
          context,
        ).add(GetSingleChatHistoryEvent(chatId: chatId!));

        await initialLoadCompleter?.future;
      } else {
        chatHistory = PrefUtils.getChatHistory();
        loadAudioUrlsFromHistory();
      }

      if (searchQueryFromAskAnythingScreen?.trim().isNotEmpty == true) {
        handleInitialQuery();
      }
    } catch (e) {
      CommonUtils.showErrorToast('Failed to load chat history');
    } finally {
      if (mounted) {
        setState(() => isInitialLoading = false);
      }
    }
  }

  void loadAudioUrlsFromHistory() {
    for (int i = 0; i < chatHistory.length; i++) {
      final chat = chatHistory[i];
      if (chat['audio_url'] != null &&
          chat['audio_url'].toString().isNotEmpty) {
        userAudioUrlMap[i] = chat['audio_url'];
      }

      if (chat['apiResponses'] != null && chat['apiResponses'] is List) {
        final apiResponses = chat['apiResponses'] as List;
        if (apiResponses.isNotEmpty) {
          final response = apiResponses[0];
          if (response['audio_url'] != null &&
              response['audio_url'].toString().isNotEmpty) {
            responseAudioUrlMap[i] = response['audio_url'];
          }
        }
      }
    }
  }

  void handleInitialQuery() {
    final query = searchQueryFromAskAnythingScreen!.trim();
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
        'chatId': getCurrentChatId(),
        'messageId': '',
        'is_bookmarked': false,
        'isLiked': false,
        'isDisliked': false,
        'isUserAudio': false,
        'hasError': false,
      };

      setState(() {
        chatHistory.add(newChatItem);
        currentResponseIndex = chatHistory.length - 1;
        responseLoadingStates[currentResponseIndex!] = true;
        isApiProcessing = true;
        PrefUtils.setChatHistory(chatHistory);
      });

      sendMessageToAPI(query);
    }
  }

  String getCurrentChatId() {
    return chatId ?? PrefUtils.getstoredChatID();
  }

  Future<void> stopAllAudio() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.pause();
      await audioPlayer.release();

      if (mounted) {
        setState(() {
          isPlaying = false;
          currentlyPlayingIndex = null;
          currentlyPlayingUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          currentlyPlayingIndex = null;
          currentlyPlayingUrl = null;
        });
      }
    }
  }

  void cleanupTemporaryFiles() {
    try {
      if (audioPath != null && File(audioPath!).existsSync()) {
        File(audioPath!).deleteSync();
      }
      if (responseAudioPath != null && File(responseAudioPath!).existsSync()) {
        File(responseAudioPath!).deleteSync();
      }
    } catch (e) {
      // Silent cleanup failure
    }
  }

  String generateRandomId() {
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
      audioPath = '${dir.path}/${generateRandomId()}.wav';

      final startFuture = audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: audioPath!,
      );

      await startFuture.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Recording start timeout');
        },
      );

      if (mounted) {
        setState(() {
          isRecording = true;
          // Clear previous response audio state
          responseAudioPath = null;
          apiResponse = null;
          currentResponseAudioUrl = null;
          // Keep currentUserAudioUrl as it will be set after recording
        });
      }
    } on TimeoutException {
      CommonUtils.showErrorToast('Recording start timeout. Please try again.');
      setState(() => isRecording = false);
    } catch (e) {
      CommonUtils.showErrorToast('Failed to start recording');
      setState(() => isRecording = false);
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      setState(() {
        isApiProcessing = true;
      });

      final stopFuture = audioRecorder.stop();
      final path = await stopFuture.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Recording stop timeout');
        },
      );

      setState(() {
        isRecording = false;
        audioPath = path;
      });

      if (audioPath != null && File(audioPath!).existsSync()) {
        await sendAudioToApi();
      } else {
        CommonUtils.showErrorToast('Recording file was not saved');
        setState(() => isApiProcessing = false);
      }
    } on TimeoutException {
      CommonUtils.showErrorToast('Recording stop timeout. Please try again.');

      try {
        await audioRecorder.dispose();
        await audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: '',
        );
        await audioRecorder.stop();
      } catch (e) {
        debugPrint('Force cleanup error: $e');
      }

      setState(() {
        isRecording = false;
        isApiProcessing = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      CommonUtils.showErrorToast('Failed to stop recording');

      setState(() {
        isRecording = false;
        isApiProcessing = false;
      });
    }
  }

  Future<void> cancelRecording() async {
    if (!isRecording) return;

    try {
      await audioRecorder.stop();
      setState(() {
        isRecording = false;
        isApiProcessing = false;
      });
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
      setState(() {
        isRecording = false;
        isApiProcessing = false;
      });
    }
  }

  Future<void> sendAudioToApi() async {
    if (audioPath == null) return;

    setState(() {
      isApiProcessing = true;
    });

    try {
      final audioFile = File(audioPath!);
      if (!audioFile.existsSync()) {
        throw Exception('Audio file not found');
      }

      final newChatItem = {
        'question': 'Audio Recording',
        'answer': '',
        'chatId': getCurrentChatId(),
        'messageId': '',
        'is_bookmarked': false,
        'isLiked': false,
        'isDisliked': false,
        'isUserAudio': true,
        'hasError': false,
      };

      setState(() {
        chatHistory.add(newChatItem);
        currentResponseIndex = chatHistory.length - 1;
        responseLoadingStates[currentResponseIndex!] = true;
        PrefUtils.setChatHistory(chatHistory);
      });

      BlocProvider.of<HomeFlowBloc>(
        context,
      ).add(UploadFile(file: audioPath!, isResponseAudio: false));

      scrollToBottom();
    } catch (e) {
      CommonUtils.showErrorToast('Error sending audio');
      if (currentResponseIndex != null) {
        setState(() {
          responseLoadingStates.remove(currentResponseIndex);
          isApiProcessing = false;
          if (chatHistory.isNotEmpty &&
              currentResponseIndex! < chatHistory.length) {
            chatHistory.removeAt(currentResponseIndex!);
            PrefUtils.setChatHistory(chatHistory);
          }
        });
      }
    }
  }

  Future<void> playAudioFromUrl(
    String audioUrl,
    int index,
    bool isUserAudio,
  ) async {
    if (audioUrl.isEmpty) return;

    try {
      if (currentlyPlayingIndex == index &&
          currentlyPlayingUrl == audioUrl &&
          isPlaying) {
        await audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer.stop();

        setState(() {
          currentlyPlayingIndex = index;
          currentlyPlayingUrl = audioUrl;
          isPlaying = true;
        });

        await audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      CommonUtils.showErrorToast('Failed to play audio');
      setState(() {
        isPlaying = false;
        currentlyPlayingIndex = null;
        currentlyPlayingUrl = null;
      });
    }
  }

  Future<void> playLocalAudio(String filePath, int index) async {
    if (filePath.isEmpty || !File(filePath).existsSync()) return;

    try {
      if (currentlyPlayingIndex == index &&
          currentlyPlayingUrl == filePath &&
          isPlaying) {
        await audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer.stop();

        setState(() {
          currentlyPlayingIndex = index;
          currentlyPlayingUrl = filePath;
          isPlaying = true;
        });

        await audioPlayer.play(DeviceFileSource(filePath));
      }
    } catch (e) {
      debugPrint('Error playing local audio: $e');
      CommonUtils.showErrorToast('Failed to play audio');
      setState(() {
        isPlaying = false;
        currentlyPlayingIndex = null;
        currentlyPlayingUrl = null;
      });
    }
  }

  Future<String> writeResponseFile(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${generateRandomId()}_response.wav';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  bool isValidHex(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean) && clean.length % 2 == 0;
  }

  List<int> hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s+'), '');
    return [
      for (int i = 0; i < clean.length; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ];
  }

  Future<String?> convertWavToMp3(File wavFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final mp3Path = '${dir.path}/${generateRandomId()}_converted.mp3';

      final bytes = await wavFile.readAsBytes();
      final mp3File = File(mp3Path);
      await mp3File.writeAsBytes(bytes);

      return mp3Path;
    } catch (e) {
      debugPrint('Error converting WAV to MP3: $e');
      return null;
    }
  }

  void sendMessageToAPI(String message) {
    try {
      setState(() => isApiProcessing = true);

      if (PrefUtils.getstoredChatID().isEmpty && chatId == null) {
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

      scrollToBottom();
    } catch (e) {
      CommonUtils.showErrorToast('Failed to send message');
      if (currentResponseIndex != null) {
        responseLoadingStates.remove(currentResponseIndex);
      }
      setState(() => isApiProcessing = false);
    }
  }

  void handleUserMessage() {
    final message = inputController.text.trim();
    if (message.isEmpty) return;

    try {
      // RESET audio state before starting new text chat
      _resetAudioState();

      final chatIdValue = getCurrentChatId();
      bool isEdited = false;

      setState(() {
        if (editingIndex != null) {
          chatHistory[editingIndex!]['question'] = message;
          chatHistory[editingIndex!]['answer'] = '';
          chatHistory[editingIndex!]['hasError'] = false;
          currentResponseIndex = editingIndex;
          responseLoadingStates[currentResponseIndex!] = true;
          isEdited = true;
        } else {
          final newChatItem = {
            'question': message,
            'answer': '',
            'chatId': chatIdValue,
            'messageId': '',
            'is_bookmarked': false,
            'isLiked': false,
            'isDisliked': false,
            'isUserAudio': false,
            'hasError': false,
          };
          chatHistory.add(newChatItem);
          currentResponseIndex = chatHistory.length - 1;
          responseLoadingStates[currentResponseIndex!] = true;
          isEdited = false;
        }
        isApiProcessing = true;
        // Clear audio URLs for text chat
        currentUserAudioUrl = null;
        currentResponseAudioUrl = null;
        PrefUtils.setChatHistory(chatHistory);
      });

      if (PrefUtils.getstoredChatID().isEmpty && chatId == null) {
        BlocProvider.of<HomeFlowBloc>(context).add(
          InitiateChatEvent(
            message: message,
            isGuest: PrefUtils.getIsGuest(),
            modelName: 'Atlas',
            searchEngine: 'Search',
            edited: isEdited,
            sender: 'user',
            chatId: chatIdValue,
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
      editingIndex = null;
      scrollToBottom();
    } catch (e) {
      CommonUtils.showErrorToast('Failed to send message');
      if (currentResponseIndex != null) {
        responseLoadingStates.remove(currentResponseIndex);
      }
      setState(() => isApiProcessing = false);
    }
  }

  void handleRegenerate(int index) {
    final chatItem = chatHistory[index];
    final String question = chatItem['question']?.trim() ?? '';

    if (question.isEmpty) {
      CommonUtils.showErrorToast('Cannot regenerate: No question found');
      return;
    }

    final bool isUserAudio = chatItem['isUserAudio'] == true;
    if (isUserAudio) {
      CommonUtils.showErrorToast('Cannot regenerate audio messages');
      return;
    }

    setState(() {
      chatHistory[index]['answer'] = '';
      chatHistory[index]['isRegenerating'] = true;
      responseLoadingStates[index] = true;
      currentResponseIndex = index;
      isApiProcessing = true;
      PrefUtils.setChatHistory(chatHistory);
    });

    scrollToBottom();

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
        responseLoadingStates.remove(index);
        isApiProcessing = false;
      });
    }
  }

  void showFeedbackPopup(BuildContext context) {
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

  void scrollToBottom() {
    scrollTimer?.cancel();
    scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients && mounted) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void handleChatResponse(Map<String, dynamic> response, int index) {
    setState(() {
      // Only update if this is the correct index
      if (index < chatHistory.length) {
        chatHistory[index]['answer'] = response.toString();
        responseLoadingStates.remove(index);
      }
      isApiProcessing = false;
      PrefUtils.setChatHistory(chatHistory);
    });
  }

  Future<void> handleVoiceResponse(dynamic response, int index) async {
    try {
      // Clear previous audio state
      _resetAudioState();

      if (response is Map<String, dynamic> && response.containsKey('audio')) {
        final hexString = response['audio'];
        if (isValidHex(hexString)) {
          final bytes = hexToBytes(hexString);

          final wavPath = await writeResponseFile(bytes);
          final wavFile = File(wavPath);

          setState(() => isConvertingAudio = true);
          final mp3Path = await convertWavToMp3(wavFile);

          if (mp3Path != null) {
            final mp3File = File(mp3Path);

            BlocProvider.of<HomeFlowBloc>(
              context,
            ).add(UploadFile(file: mp3Path, isResponseAudio: true));

            setState(() {
              responseAudioPath = wavPath;
              chatHistory[index]['answer'] = 'Audio Response';
              chatHistory[index]['hasAudioUrl'] = true;
              PrefUtils.setChatHistory(chatHistory);
            });
          } else {
            writeResponseFile(bytes)
                .then((path) {
                  setState(() {
                    responseAudioPath = path;
                    chatHistory[index]['answer'] = 'Audio Response';
                    chatHistory[index]['hasAudioUrl'] = false;
                    responseLoadingStates.remove(index);
                    isApiProcessing = false;
                    isConvertingAudio = false;
                    PrefUtils.setChatHistory(chatHistory);
                  });
                })
                .catchError((e) {
                  handleChatResponse(response, index);
                  setState(() => isConvertingAudio = false);
                });
          }
        } else {
          handleChatResponse(response, index);
          setState(() => isConvertingAudio = false);
        }
      } else if (response is List<int>) {
        final wavPath = await writeResponseFile(response);
        final wavFile = File(wavPath);

        setState(() => isConvertingAudio = true);
        final mp3Path = await convertWavToMp3(wavFile);

        if (mp3Path != null) {
          final mp3File = File(mp3Path);

          BlocProvider.of<HomeFlowBloc>(
            context,
          ).add(UploadFile(file: mp3Path, isResponseAudio: true));

          setState(() {
            responseAudioPath = wavPath;
            chatHistory[index]['answer'] = 'Audio Response';
            chatHistory[index]['hasAudioUrl'] = true;
            PrefUtils.setChatHistory(chatHistory);
          });
        } else {
          setState(() {
            responseAudioPath = wavPath;
            chatHistory[index]['answer'] = 'Audio Response';
            chatHistory[index]['hasAudioUrl'] = false;
            responseLoadingStates.remove(index);
            isApiProcessing = false;
            isConvertingAudio = false;
            PrefUtils.setChatHistory(chatHistory);
          });
        }
      } else {
        handleChatResponse(response, index);
        setState(() => isConvertingAudio = false);
      }
    } catch (e) {
      debugPrint('Error handling voice response: $e');
      handleChatResponse({'error': 'Failed to process response'}, index);
      setState(() => isConvertingAudio = false);
    }
  }
}
