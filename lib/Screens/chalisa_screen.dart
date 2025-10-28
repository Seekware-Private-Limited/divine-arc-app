import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/AudioPlayerWidget.dart';
import 'package:divine_arc/Utils/FontSizeDropdown.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:flutter/material.dart';

class ChalisaScreen extends StatefulWidget {
  final String image;
  final String titleEn;
  final String titleHi;
  final String prayerEn;
  final String prayerHi;
  final String descriptionEn;
  final String descriptionHi;
  final String audio;

  const ChalisaScreen({
    super.key,
    required this.image,
    required this.titleEn,
    required this.titleHi,
    required this.prayerEn,
    required this.prayerHi,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.audio,
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

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        _currentPosition =
            await _audioPlayer.getCurrentPosition() ?? Duration.zero;
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_currentPosition.inSeconds > 0) {
          await _audioPlayer.seek(_currentPosition);
        }
        await _audioPlayer.play(AssetSource(widget.audio));
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

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
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'en' ? widget.titleEn : widget.titleHi;
    final prayer = locale == 'en' ? widget.prayerEn : widget.prayerHi;
    final description =
        locale == 'en' ? widget.descriptionEn : widget.descriptionHi;

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
                    /// --- HEADER ROW ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Back Icon on Left
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

                        /// Language + Font Controls on Right
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

                    /// --- MAIN SCROLL CONTENT ---
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
                                  widget.image,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        context,
                                        error,
                                        stackTrace,
                                      ) => Image.asset(
                                        'assets/images/hanuman_placeholder.png',
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(title, style: FTextStyle.boldText),
                              const SizedBox(height: 10),
                              Text(
                                prayer,
                                style: FTextStyle.defaultText,
                                textAlign: TextAlign.center,
                              ),
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

              /// --- STICKY AUDIO PLAYER AT BOTTOM ---
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: AudioPlayerWidget(audioPath: widget.audio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
