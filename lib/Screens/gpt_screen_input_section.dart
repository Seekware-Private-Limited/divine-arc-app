import 'package:divine_arc/Utils/app_imports.dart';

class GptScreenInputSection extends StatelessWidget {
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
              controller: inputController,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isRecording)
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Container(
                height: 35 + (animationController.value * 5),
                width: 35 + (animationController.value * 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gradientStart.withOpacity(
                        0.3 * (1 - animationController.value),
                      ),
                      AppColors.gradientEnd.withOpacity(
                        0.3 * (1 - animationController.value),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ScaleTransition(
          scale:
              isRecording ? scaleAnimation : const AlwaysStoppedAnimation(1.0),
          child: Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              border: Border.all(
                color: isRecording ? Colors.white : AppColors.gradientStart,
              ),
              borderRadius: BorderRadius.circular(40),
              gradient:
                  isRecording
                      ? LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      )
                      : null,
              color: isRecording ? null : Colors.white,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isRecording ? Icons.stop : Icons.mic,
                size: 21,
                color: isRecording ? Colors.white : AppColors.gradientStart,
              ),
              onPressed:
                  (isApiProcessing || isConvertingAudio)
                      ? null
                      : () async {
                        if (isRecording) {
                          onStopRecording();
                        } else {
                          onStartRecording();
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
          (isApiProcessing || isRecording || isConvertingAudio)
              ? null
              : onSendMessage,
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
              (isApiProcessing || isRecording || isConvertingAudio)
                  ? Colors.grey
                  : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
