import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/AudioPlayerWidget.dart';
import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ChalisaScreen extends StatefulWidget {
  final String contentImage;
  final String contentName;
  final String contentDescription;
  final String? contentAudio;

  const ChalisaScreen({
    super.key,
    required this.contentImage,
    required this.contentName,
    required this.contentDescription,
    this.contentAudio,
  });

  @override
  State<ChalisaScreen> createState() => _ChalisaScreenState();
}

class _ChalisaScreenState extends State<ChalisaScreen> {
  double _fontSizeMultiplier = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool isPlaying = false;
  void _onLanguageChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _initialize();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
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
    final title = widget.contentName;
    final description = widget.contentDescription;

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
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),

                            Row(
                              children: [
                                LanguageDropdown(),
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
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.gradientStart,
                                  width: 1.5,
                                ),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      widget.contentImage,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                                'assets/images/errorImage.png',
                                                height: 100,
                                                width: 100,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(title, style: FTextStyle.boldText),
                                  const SizedBox(height: 10),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      description,
                                      style: FTextStyle.defaultTextSemiBold,
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
                  if (widget.contentAudio != null &&
                      widget.contentAudio!.trim().isNotEmpty)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 30,
                      child: AudioPlayerWidget(audioPath: widget.contentAudio!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
