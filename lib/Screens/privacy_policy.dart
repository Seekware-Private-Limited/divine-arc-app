import 'package:divine_arc/Utils/flutter_color_themes.dart';
import 'package:divine_arc/Utils/flutter_font_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String _privacyPolicy = '''
# Divine ARC Privacy Policy

**Last Updated:** July 2, 2026

Divine ARC respects your privacy and is committed to protecting your personal information. This Privacy Policy explains what information we collect, how we use it, and how we protect it.

## 1. Information We Collect

Depending on the features you use, Divine ARC may collect:

- Name and email address (if you create an account)
- Profile picture (if you choose to upload one)
- Text questions submitted to the AI Assistant
- Voice input when you choose to use the microphone
- Basic device information, crash reports, and app performance data

## 2. How We Use Your Information

We use your information to:

- Provide and improve Divine ARC services
- Display your profile information
- Generate AI-powered responses
- Process voice input for AI interactions
- Improve app performance, security, and reliability

## 3. AI Processing

Divine ARC includes an AI-powered spiritual assistant.

When you submit a text or voice question, your request is securely transmitted to Divine ARC's backend servers for AI processing. Voice recordings may be converted into text to generate responses.

Microphone access is requested only when you choose to use voice input.

## 4. Data Sharing

We do **not** sell your personal information.

To provide AI-powered responses, user questions and voice input may be processed through trusted AI services integrated with our secure backend infrastructure.

We may also share information with trusted service providers that help us operate, secure, and improve the application, or when required by law.

## 5. Data Security

We use industry-standard security measures, including encrypted communication and secure backend infrastructure, to protect your information.

## 6. Your Rights

You may request access, correction, or deletion of your account and personal information by contacting us.

## 7. Updates

This Privacy Policy may be updated from time to time. Any changes will be published within the application or on our official website.

## Contact Us

If you have any questions regarding this Privacy Policy, please contact us:

**Email:** <contact@divinearc.in>
''';

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Privacy Policy',
          style: FTextStyle.defaultTextSemiBold,
        ),
      ),
      body: Markdown(
        padding: const EdgeInsets.all(20),
        data: _privacyPolicy,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h1: FTextStyle.defaultTextBold.copyWith(fontSize: 25),
          h2: FTextStyle.defaultTextSemiBold.copyWith(fontSize: 14),
          p: FTextStyle.defaultText,
          strong: FTextStyle.defaultTextSemiBold,
          listBullet: FTextStyle.defaultText,
          listBulletPadding: const EdgeInsets.only(right: 8),
          blockSpacing: 18,
          horizontalRuleDecoration: const BoxDecoration(),
          a: FTextStyle.defaultTextSemiBold.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href == null) return;

          if (href.startsWith('mailto:')) {
            await _launchEmail(href.replaceFirst('mailto:', ''));
            return;
          }

          final uri = Uri.parse(href);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        },
      ),
    );
  }
}
