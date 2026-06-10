import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/AudioPlayerWidget.dart';
import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:divine_arc/Utils/session_expired_snackbar.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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

  // State variables for fetched API content data
  bool isLoading = false;
  String title = '';
  String description = '';
  String contentImage = '';
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

    // Call API On Init State
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
            Positioned.fill(
              child: Image.asset(
                'assets/images/bgGitaGPT.png',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: BlocListener<HomeFlowBloc, HomeFlowState>(
                listener: (context, state) {
                  // Adjust these state classes matching your HomeFlowBloc definitions
                  if (state is ViewContentByIdLoading) {
                    setState(() => isLoading = true);
                  } else if (state is ViewContentByIdLoaded) {
                    setState(() {
                      isLoading = false;
                      // Mapping JSON values out of response structure safely
                      final data =
                          state.successResponse['data'] ??
                          state.successResponse;
                      title = data['content_name'] ?? 'No Title';
                      description = data['content_description'] ?? '';
                      contentImage = data['content_image'] ?? '';
                      contentAudio = data['content_audio'] ?? '';
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
                child: Stack(
                  children: [
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ),
                              Row(
                                children: [
                                  LanguageDropdown(
                                    onLanguageChanged: (updatedLanguageCode) {
                                      setState(() {
                                        currentLanguage = updatedLanguageCode;
                                      });
                                      // Call API again as the user changes the language
                                      BlocProvider.of<HomeFlowBloc>(
                                        context,
                                      ).add(
                                        ViewContentById(
                                          id: widget.contentId,
                                          language: updatedLanguageCode,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
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
                          const SizedBox(height: 10),
                          Expanded(
                            child:
                                isLoading
                                    ? Center(
                                      child:
                                          LoadingAnimationWidget.staggeredDotsWave(
                                            color: AppColors.gradientStart,
                                            size: 50,
                                          ),
                                    )
                                    : SingleChildScrollView(
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.gradientStart,
                                            width: 1.5,
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            ClipOval(
                                              child:
                                                  contentImage.isNotEmpty
                                                      ? Image.network(
                                                        contentImage,
                                                        height: 100,
                                                        width: 100,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Image.asset(
                                                              'assets/images/errorImage.png',
                                                              height: 100,
                                                              width: 100,
                                                              fit: BoxFit.cover,
                                                            ),
                                                      )
                                                      : Image.asset(
                                                        'assets/images/errorImage.png',
                                                        height: 100,
                                                        width: 100,
                                                        fit: BoxFit.cover,
                                                      ),
                                            ),
                                            const SizedBox(height: 15),
                                            Text(
                                              title.isNotEmpty
                                                  ? title
                                                  : 'Loading...',
                                              style: FTextStyle.boldText,
                                            ),
                                            const SizedBox(height: 10),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                description,
                                                style:
                                                    FTextStyle
                                                        .defaultTextSemiBold,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLoading && contentAudio.trim().isNotEmpty)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 30,
                        child: AudioPlayerWidget(audioPath: contentAudio),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
