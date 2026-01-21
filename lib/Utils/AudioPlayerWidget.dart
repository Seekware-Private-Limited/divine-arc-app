import 'package:audioplayers/audioplayers.dart';
import 'package:divine_arc/Utils/app_imports.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({super.key, required this.audioPath});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isMuted = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _preloadAudio();

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
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
        _currentPosition =
            await _audioPlayer.getCurrentPosition() ?? Duration.zero;
        await _audioPlayer.pause();
      } else {
        if (_currentPosition.inSeconds > 0) {
          await _audioPlayer.seek(_currentPosition);
        }
        await _audioPlayer.play(UrlSource(widget.audioPath));
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _seek(int seconds) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition < Duration.zero) {
      await _audioPlayer.seek(Duration.zero);
    } else if (newPosition > _totalDuration) {
      await _audioPlayer.seek(_totalDuration);
    } else {
      await _audioPlayer.seek(newPosition);
    }
    setState(() => _currentPosition = newPosition);
  }

  void _onSliderChanged(double value) {
    final newPosition = Duration(seconds: value.toInt());
    _audioPlayer.seek(newPosition);
    setState(() => _currentPosition = newPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Slider(
                  activeColor: AppColors.gradientStart,
                  inactiveColor: Colors.white24,
                  value: _currentPosition.inSeconds.toDouble().clamp(
                    0,
                    _totalDuration.inSeconds.toDouble(),
                  ),
                  max: _totalDuration.inSeconds.toDouble(),
                  onChanged: _onSliderChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          /// Audio control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _toggleMute,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () => _seek(-10),
              ),
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: _toggleAudio,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () => _seek(10),
              ),

              /// Empty space (replaces the favorite icon)
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
