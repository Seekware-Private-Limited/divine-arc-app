import 'package:divine_arc/Utils/app_imports.dart';

class SessionExpiredSnackBar {
  static void show({required BuildContext context, required String message}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: _SessionExpiredContent(
          message: message,
          onLoginTap: () {
            scaffoldMessenger.hideCurrentSnackBar();
            PrefUtils.clearAll();
            if (!context.mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}

class _SessionExpiredContent extends StatelessWidget {
  final String message;
  final VoidCallback onLoginTap;

  const _SessionExpiredContent({
    required this.message,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFC7902), // gradientStart
            Color(0xFFC62E00), // gradientEnd
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: FTextStyle.tabbarTextStyle)),
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: onLoginTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Login', style: FTextStyle.tabbarTextStyle),
            ),
          ),
        ],
      ),
    );
  }
}
