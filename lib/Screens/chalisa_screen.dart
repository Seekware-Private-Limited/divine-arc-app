import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/AudioPlayerWidget.dart';
import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChalisaScreen extends StatefulWidget {
  final String contentId;
  const ChalisaScreen({super.key, required this.contentId});

  @override
  State<ChalisaScreen> createState() => _ChalisaScreenState();
}

class _ChalisaScreenState extends State<ChalisaScreen> {
  double _fontSizeMultiplier = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool isPlaying = false;

  // State variables for fetched API content
  bool isLoading = false;
  String title = '';
  String description = '';
  String contentAudio = '';
  String currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _fetchLanguageAndContent();
    _initialize();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  void _fetchLanguageAndContent() {
    String language = PrefUtils.getLanguage();
    if (language.isEmpty) {
      language = 'en';
    }
    setState(() {
      currentLanguage = language;
    });

    BlocProvider.of<HomeFlowBloc>(
      context,
    ).add(ViewContentById(id: widget.contentId, language: currentLanguage));
  }

  Future<void> _initialize() async {
    await _analytics.logEvent(name: 'UserIsOnChalisaScreen');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_fontSizeMultiplier)),
      child: Scaffold(
        backgroundColor: AppColors.GlobalBG,
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgGitaGPT.png',
                fit: BoxFit.cover,
              ),
            ),

            SafeArea(
              child: BlocListener<HomeFlowBloc, HomeFlowState>(
                listener: (context, state) {
                  if (state is ViewContentByIdLoading) {
                    setState(() => isLoading = true);
                  } else if (state is ViewContentByIdLoaded) {
                    setState(() {
                      isLoading = false;
                      final data =
                          state.successResponse['data'] ??
                          state.successResponse;
                      title = data['content_name'] ?? 'No Title';
                      description = data['content_description'] ?? '';
                      contentAudio = data['audio'] ?? '';
                    });
                  } else if (state is ViewContentByIdError) {
                    setState(() => isLoading = false);
                    CommonUtils.showErrorToast(
                      'Failed to load chalisa content',
                    );
                  } else if (state is CommonServerFailureHome) {
                    setState(() => isLoading = false);
                  } else if (state is SessionExpiredStateHome) {
                    setState(() => isLoading = false);
                    SessionExpiredSnackBar.show(
                      context: context,
                      message: state.message,
                    );
                  } else if (state is CheckNetworkConnectionHomeFlow) {
                    setState(() => isLoading = false);
                    CommonUtils.showErrorToast(
                      AppLocalizations.of(
                        context,
                      )!.translate('nointernetConnection'),
                    );
                  }
                },
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          Row(
                            children: [
                              LanguageDropdown(
                                onLanguageChanged: (updatedLanguageCode) {
                                  setState(() {
                                    currentLanguage = updatedLanguageCode;
                                  });
                                  BlocProvider.of<HomeFlowBloc>(context).add(
                                    ViewContentById(
                                      id: widget.contentId,
                                      language: updatedLanguageCode,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              FontSizeDropdown(
                                currentScale: _fontSizeMultiplier,
                                onFontSizeChanged: (newScale) {
                                  setState(
                                    () => _fontSizeMultiplier = newScale,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Content
                    Expanded(
                      child:
                          isLoading
                              ? Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: AppColors.gradientStart,
                                  size: 50,
                                ),
                              )
                              : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),

                                    color: Colors.white.withOpacity(0.95),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Center(
                                        child: Text(
                                          title.isNotEmpty
                                              ? title
                                              : 'Loading...',
                                          textAlign: TextAlign.center,
                                          style: FTextStyle.boldText,
                                        ),
                                      ),

                                      const Divider(
                                        height: 32,
                                        thickness: 0.5,
                                        color: Colors.grey,
                                      ),

                                      // Description using Markdown
                                      if (description.isNotEmpty)
                                        MarkdownBody(
                                          data: description,
                                          selectable: true,
                                          styleSheet: MarkdownStyleSheet(
                                            p: FTextStyle.defaultTextSemiBold
                                                .copyWith(
                                                  height: 1.85,
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                ),
                                            h1: FTextStyle.boldText.copyWith(
                                              fontSize: 20,
                                              color: Colors.black,
                                            ),
                                            h2: FTextStyle.boldText.copyWith(
                                              fontSize: 22,
                                              color: Colors.black,
                                            ),
                                            h3: FTextStyle.boldText.copyWith(
                                              fontSize: 20,
                                              color: Colors.black,
                                            ),
                                            strong: FTextStyle.boldText
                                                .copyWith(color: Colors.black),
                                            em: FTextStyle.defaultTextSemiBold
                                                .copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                            listBullet:
                                                FTextStyle.defaultTextSemiBold,
                                            horizontalRuleDecoration:
                                                const BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                      color: Colors.grey,
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                ),
                                            blockSpacing: 18,
                                          ),
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

            // Audio Player
            if (!isLoading && contentAudio.trim().isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 10,
                child: AudioPlayerWidget(audioPath: contentAudio),
              ),
          ],
        ),
      ),
    );
  }
}
