import 'package:divine_arc/Utils/app_imports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  });

  @override
  State<GptScreenInputSection> createState() => _GptScreenInputSectionState();
}

class _GptScreenInputSectionState extends State<GptScreenInputSection> {
  bool _shouldShowMicButton = true;

  @override
  void initState() {
    super.initState();
    _shouldShowMicButton = widget.inputController.text.trim().isEmpty;
    widget.inputController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final shouldShowMicButton = widget.inputController.text.trim().isEmpty;

    if (_shouldShowMicButton != shouldShowMicButton) {
      setState(() {
        _shouldShowMicButton = shouldShowMicButton;
      });
    }
  }

  @override
  void dispose() {
    widget.inputController.removeListener(_handleTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
              maxLength: 500,
              buildCounter: (
                context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) {
                return null;
              },
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
          if (_shouldShowMicButton) ...[
            const SizedBox(width: 8),
            _buildMicrophoneButton(),
          ],
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isRecording)
          AnimatedBuilder(
            animation: widget.animationController,
            builder: (context, child) {
              return Container(
                height: 35 + (widget.animationController.value * 5),
                width: 35 + (widget.animationController.value * 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gradientStart.withOpacity(
                        0.3 * (1 - widget.animationController.value),
                      ),
                      AppColors.gradientEnd.withOpacity(
                        0.3 * (1 - widget.animationController.value),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ScaleTransition(
          scale:
              widget.isRecording
                  ? widget.scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    widget.isRecording ? Colors.white : AppColors.gradientStart,
              ),
              borderRadius: BorderRadius.circular(40),
              gradient:
                  widget.isRecording
                      ? LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      )
                      : null,
              color: widget.isRecording ? null : Colors.white,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                size: 21,
                color:
                    widget.isRecording ? Colors.white : AppColors.gradientStart,
              ),
              onPressed:
                  (widget.isApiProcessing || widget.isConvertingAudio)
                      ? null
                      : () async {
                        if (widget.isRecording) {
                          widget.onStopRecording();
                        } else {
                          widget.onStartRecording();
                        }
                      },
            ),
          ),
        ),
      ],
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
          LucideIcons.arrowUp,
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
}
