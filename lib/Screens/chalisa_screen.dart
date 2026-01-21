import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/AudioPlayerWidget.dart';
import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class ChalisaScreen extends StatefulWidget {
  final String contentImage;
  final String contentName;
  final String contentDescription;
  final String contentAudio;

  const ChalisaScreen({
    super.key,
    required this.contentImage,
    required this.contentName,
    required this.contentDescription,
    required this.contentAudio,
  });

  @override
  State<ChalisaScreen> createState() => _ChalisaScreenState();
}

class _ChalisaScreenState extends State<ChalisaScreen> {
  double _fontSizeMultiplier = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  void _onLanguageChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
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
        body: SafeArea(
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
                            LanguageDropdown(
                              onLanguageChanged: _onLanguageChanged,
                            ),
                            const SizedBox(width: 8),
                            FontSizeDropdown(
                              currentScale: _fontSizeMultiplier,
                              onFontSizeChanged: (newScale) {
                                setState(() => _fontSizeMultiplier = newScale);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Container(
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
                                  style: FTextStyle.defaultText,
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

              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: AudioPlayerWidget(audioPath: widget.contentAudio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
