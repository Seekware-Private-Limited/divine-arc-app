import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Screens/%20gpt_screen_chat_list.dart';
import 'package:divine_arc/Screens/privacy_policy.dart';
import 'package:divine_arc/Screens/terms_conditions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:record/record.dart';
import 'package:divine_arc/Utils/app_imports.dart';

import 'gpt_screen_bloc_listener.dart';
import 'gpt_screen_input_section.dart';
import 'gpt_screen_methods.dart';

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
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        GptScreenMethods {
  // Implement abstract getters required by GptScreenMethods mixin
  @override
  String? get chatId => widget.chatId;

  @override
  String? get searchQueryFromAskAnythingScreen =>
      widget.searchQueryFromAskAnythingScreen;

  // Controllers
  @override
  final TextEditingController inputController = TextEditingController();
  @override
  final TextEditingController feedbackTextController = TextEditingController();
  @override
  final ScrollController scrollController = ScrollController();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Audio components
  @override
  late final AudioRecorder audioRecorder;
  @override
  late final AudioPlayer audioPlayer;
  late final AnimationController animationController;
  late final Animation<double> scaleAnimation;

  StreamSubscription<PlayerState>? playerStateSubscription;

  // State variables
  @override
  bool isRecording = false;
  @override
  bool isInitialLoading = false;
  @override
  bool isApiProcessing = false;
  @override
  bool isConvertingAudio = false;

  // File paths
  @override
  String? audioPath;
  @override
  String? responseAudioPath;
  @override
  String? apiResponse;
  @override
  String reactionId = '';

  // Chat state
  @override
  int? editingIndex;
  @override
  int? currentResponseIndex;
  @override
  List<Map<String, dynamic>> chatHistory = [];
  @override
  Timer? scrollTimer;
  @override
  final Map<int, bool> responseLoadingStates = {};
  @override
  Completer<void>? initialLoadCompleter;

  // Audio URL tracking
  @override
  final Map<int, String> userAudioUrlMap = {};
  @override
  final Map<int, String> responseAudioUrlMap = {};

  bool _isConsentDialogVisible = false;

  // Current voice conversation
  @override
  String? currentUserAudioUrl;
  @override
  String? currentResponseAudioUrl;

  // Current playing audio
  @override
  int? currentlyPlayingIndex;
  @override
  String? currentlyPlayingUrl;
  @override
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    WidgetsBinding.instance.addObserver(this);

    audioRecorder = AudioRecorder();
    audioPlayer = AudioPlayer();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        isPlaying = state == PlayerState.playing;

        if (state == PlayerState.stopped || state == PlayerState.completed) {
          currentlyPlayingIndex = null;
          currentlyPlayingUrl = null;
          isPlaying = false;
        }
      });
    });

    initializeChatHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_isConsentDialogVisible &&
          !PrefUtils.getAiPrivacyConsent()) {
        showAiConsentDialog();
      }
    });
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnGPTScreen');
  }

  @override
  void showAiConsentDialog() {
    if (_isConsentDialogVisible || PrefUtils.getAiPrivacyConsent()) {
      return;
    }

    if (!mounted) return;

    final currentContext = context;
    _isConsentDialogVisible = true;
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.GlobalBG,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'AI Privacy Notice',
            style: FTextStyle.boldText.copyWith(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To provide AI-powered responses, the information you submit may be securely processed by our AI service provider.',
                  style: FTextStyle.defaultText,
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      const TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: FTextStyle.defaultText,
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(currentContext).push(
                              MaterialPageRoute(
                                builder: (_) => const TermsConditionsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Terms & Conditions',
                            style: FTextStyle.defaultText.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text: '  and ',
                        style: FTextStyle.defaultText,
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(currentContext).push(
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Privacy Policy',
                            style: FTextStyle.defaultText.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
                _isConsentDialogVisible = false;
                if (mounted) setState(() {});
              },
              child: Text('Decline', style: FTextStyle.defaultText),
            ),
            FilledButton(
              onPressed: () {
                PrefUtils.setAiPrivacyConsent(true);
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
                _isConsentDialogVisible = false;
                if (mounted) setState(() {});
              },
              child: Text(
                'I Agree',
                style: FTextStyle.defaultText.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        _isConsentDialogVisible = false;
      }
    });
  }

  void handleSendMessage() {
    if (!PrefUtils.getAiPrivacyConsent()) {
      showAiConsentDialog();
      return;
    }

    handleUserMessage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    animationController.stop();
    animationController.dispose();

    playerStateSubscription?.cancel();
    scrollTimer?.cancel();

    if (initialLoadCompleter?.isCompleted == false) {
      initialLoadCompleter?.complete();
    }

    if (isPlaying) {
      audioPlayer.stop();
    }

    if (isRecording) {
      audioRecorder.stop();
    }

    inputController.dispose();
    feedbackTextController.dispose();
    scrollController.dispose();

    audioRecorder.dispose();
    audioPlayer.dispose();

    cleanupTemporaryFiles();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      stopAllAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await stopAllAudio();
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1)),
          child: Scaffold(
            backgroundColor: AppColors.GlobalBG,
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
                    listener:
                        (context, state) => handleBlocState(context, state),
                    child: Padding(
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
                                isInitialLoading
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          LoadingAnimationWidget.staggeredDotsWave(
                                            color: AppColors.gradientStart,
                                            size: 50,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Loading...',
                                            style: FTextStyle.defaultText
                                                .copyWith(
                                                  color:
                                                      AppColors.gradientStart,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : GptScreenChatList(
                                      chatId: widget.chatId,
                                      chatHistory: chatHistory,
                                      scrollController: scrollController,
                                      responseLoadingStates:
                                          responseLoadingStates,
                                      userAudioUrlMap: userAudioUrlMap,
                                      responseAudioUrlMap: responseAudioUrlMap,
                                      currentResponseIndex:
                                          currentResponseIndex,
                                      audioPath: audioPath,
                                      responseAudioPath: responseAudioPath,
                                      apiResponse: apiResponse,
                                      isRecording: isRecording,
                                      currentlyPlayingIndex:
                                          currentlyPlayingIndex,
                                      currentlyPlayingUrl: currentlyPlayingUrl,
                                      isPlaying: isPlaying,
                                      onEdit: (index, question) {
                                        setState(() {
                                          inputController.text = question;
                                          editingIndex = index;
                                        });
                                      },
                                      onRegenerate: handleRegenerate,
                                      onPlayAudioFromUrl: playAudioFromUrl,
                                      onPlayLocalAudio: playLocalAudio,
                                      onLike: (messageId, index) {
                                        setState(() {
                                          chatHistory[index]['isLiked'] = true;
                                          chatHistory[index]['isDisliked'] =
                                              false;
                                          PrefUtils.setChatHistory(chatHistory);
                                        });

                                        BlocProvider.of<HomeFlowBloc>(
                                          context,
                                        ).add(
                                          ReactOnChatEvent(
                                            message_id: messageId,
                                            is_guest: PrefUtils.getIsGuest(),
                                            is_like: true,
                                            type: 'MESSAGE',
                                          ),
                                        );
                                      },
                                      onDislike: (messageId, index) {
                                        setState(() {
                                          chatHistory[index]['isDisliked'] =
                                              true;
                                          chatHistory[index]['isLiked'] = false;
                                          PrefUtils.setChatHistory(chatHistory);
                                        });

                                        BlocProvider.of<HomeFlowBloc>(
                                          context,
                                        ).add(
                                          ReactOnChatEvent(
                                            message_id: messageId,
                                            is_guest: PrefUtils.getIsGuest(),
                                            is_like: false,
                                            type: 'MESSAGE',
                                          ),
                                        );
                                      },
                                      onBookmark: (
                                        messageId,
                                        index,
                                        is_bookmarked,
                                      ) {
                                        // Don't update state optimistically
                                        // Let the API response handler update it
                                        BlocProvider.of<HomeFlowBloc>(
                                          context,
                                        ).add(
                                          is_bookmarked
                                              ? UnbookmarkChat(
                                                messageId: messageId,
                                              )
                                              : BookmarkChat(
                                                messageId: messageId,
                                              ),
                                        );
                                      },
                                    ),
                          ),
                          const SizedBox(height: 10),
                          GptScreenInputSection(
                            inputController: inputController,
                            isRecording: isRecording,
                            isApiProcessing: isApiProcessing,
                            isConvertingAudio: isConvertingAudio,
                            animationController: animationController,
                            scaleAnimation: scaleAnimation,
                            onSendMessage: handleSendMessage,
                            onStartRecording: startRecording,
                            onStopRecording: () async {
                              setState(() {
                                isApiProcessing = true;
                              });
                              await stopRecording();
                            },
                          ),
                        ],
                      ),
                    ),
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
