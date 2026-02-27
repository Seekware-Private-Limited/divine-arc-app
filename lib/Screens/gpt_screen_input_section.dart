import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:divine_arc/Utils/app_imports.dart';

class GptScreenInputSection extends StatefulWidget {
  final TextEditingController inputController;
  final bool isRecording;
  final bool isApiProcessing;
  final bool isConvertingAudio;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final VoidCallback onSendMessage;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;

  const GptScreenInputSection({
    super.key,
    required this.inputController,
    required this.isRecording,
    required this.isApiProcessing,
    required this.isConvertingAudio,
    required this.animationController,
    required this.scaleAnimation,
    required this.onSendMessage,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
  });

  @override
  State<GptScreenInputSection> createState() => _GptScreenInputSectionState();
}

class _GptScreenInputSectionState extends State<GptScreenInputSection> {
  final RecorderController _recorderController = RecorderController();

  Timer? _timer;
  final ValueNotifier<int> _recordDuration = ValueNotifier<int>(0);
  bool _isDialogOpen = false;

  Future<void> _startRecordingFlow() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _recordDuration.value = 0;

    await _recorderController.record();

    widget.onStartRecording();

    _startTimer();

    _showRecordingDialog();
  }

  Future<void> _stopRecordingFlow() async {
    debugPrint("Stopping recording flow...");
    if (_isDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogOpen = false;
    }

    _timer?.cancel();
    _timer = null;

    try {
      await _recorderController.stop();
    } catch (_) {}

    widget.onStopRecording();

    _recordDuration.value = 0;
  }

  Future<void> _cancelRecordingFlow() async {
    debugPrint("Cancelling recording flow...");
    if (_isDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogOpen = false;
    }

    _timer?.cancel();
    _timer = null;

    try {
      await _recorderController.stop();
    } catch (_) {}

    widget.onCancelRecording();

    _recordDuration.value = 0;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _recordDuration.value++;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  void _showRecordingDialog() {
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.GlobalBG,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Recording...",
                      style: FTextStyle.defaultTextBold,
                    ),

                    const SizedBox(height: 20),

                    TweenAnimationBuilder(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: const CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    ValueListenableBuilder<int>(
                      valueListenable: _recordDuration,
                      builder: (context, duration, child) {
                        return Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    AudioWaveforms(
                      recorderController: _recorderController,
                      waveStyle: const WaveStyle(
                        waveColor: AppColors.gradientStart,
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                      size: const Size(double.infinity, 70),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Colors.white,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _stopRecordingFlow,
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              "Send",
                              style: FTextStyle.tabbarTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 1,
                                  color: Colors.white,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _cancelRecordingFlow,
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text(
                              "Cancel",
                              style: FTextStyle.tabbarTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gradientStart),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.inputController,
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
          _buildMicrophoneButton(),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    final bool isDisabled = widget.isApiProcessing || widget.isConvertingAudio;

    return GestureDetector(
      onTap:
          isDisabled
              ? null
              : () async {
                if (widget.isRecording) {
                  await _stopRecordingFlow();
                } else {
                  await _startRecordingFlow();
                }
              },
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gradientStart),
          borderRadius: BorderRadius.circular(40),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.mic,
          size: 21,
          color: isDisabled ? Colors.grey : AppColors.gradientStart,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap:
          (widget.isApiProcessing ||
                  widget.isRecording ||
                  widget.isConvertingAudio)
              ? null
              : widget.onSendMessage,
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: Icon(
          Icons.send,
          color:
              (widget.isApiProcessing ||
                      widget.isRecording ||
                      widget.isConvertingAudio)
                  ? Colors.grey
                  : Colors.white,
          size: 18,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorderController.dispose();
    _recordDuration.dispose();
    super.dispose();
  }
}
