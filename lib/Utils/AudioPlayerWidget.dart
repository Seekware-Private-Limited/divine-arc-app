import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'dart:ui';

import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({super.key, required this.audioPath});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _preloadAudio();
  }

  Future<void> _setupAudioPlayer() async {
    // Set release mode to stop after completion (good default for single tracks)
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    // Handle completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _preloadAudio() async {
    try {
      await _audioPlayer.setSourceUrl(widget.audioPath);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Error preloading audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Resume from current position or start from beginning
        await _audioPlayer.play(UrlSource(widget.audioPath));
        if (_currentPosition > Duration.zero) {
          await _audioPlayer.seek(_currentPosition);
        }
      }
    } catch (e) {
      debugPrint("Error toggling audio: $e");
    }
  }

  Future<void> _seek(int seconds) async {
    Duration newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (_totalDuration > Duration.zero && newPosition > _totalDuration) {
      newPosition = _totalDuration;
    }

    await _audioPlayer.seek(newPosition);
    if (mounted) {
      setState(() => _currentPosition = newPosition);
    }
  }

  void _onSliderChanged(double value) {
    final newPosition = Duration(seconds: value.toInt());
    _audioPlayer.seek(newPosition);
    if (mounted) {
      setState(() => _currentPosition = newPosition);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GlassMorphismContainer(
      padding: const EdgeInsets.all(12),
      blurIntensity: 20,
      opacity: 0.70,
      glassThickness: 1.0,
      tintColor: Colors.black,
      borderRadius: BorderRadius.circular(10),
      enableBackgroundDistortion: true,
      enableGlassBorder: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _currentPosition.inSeconds.toDouble().clamp(
                0.0,
                _totalDuration.inSeconds.toDouble().clamp(1.0, double.infinity),
              ),
              max: _totalDuration.inSeconds.toDouble().clamp(
                1.0,
                double.infinity,
              ),
              onChanged: _onSliderChanged,
            ),
          ),

          // Time Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: FTextStyle.tabbarTextStyle,
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: FTextStyle.tabbarTextStyle,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 50),
              // Rewind 10s
              IconButton(
                icon: const Icon(Icons.replay_10, size: 30),
                color: Colors.white,
                onPressed: () => _seek(-10),
              ),

              // Play/Pause Button
              GestureDetector(
                onTap: _toggleAudio,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),

              // Forward 10s
              IconButton(
                icon: const Icon(Icons.forward_10, size: 30),
                color: Colors.white,
                onPressed: () => _seek(10),
              ),
              const SizedBox(width: 50),
            ],
          ),
        ],
      ),
    );
  }
}
