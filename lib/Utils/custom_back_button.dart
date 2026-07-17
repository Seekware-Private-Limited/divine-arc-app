import 'package:divine_arc/Utils/app_imports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CustomBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).pop(),
        child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gradientStart.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.arrowLeft500,
            size: 20,
            color: AppColors.gradientStart,
          ),
        ),
      ),
    );
  }
}
