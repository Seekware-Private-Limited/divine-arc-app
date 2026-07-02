import 'package:divine_arc/Utils/flutter_color_themes.dart';
import 'package:divine_arc/Utils/flutter_font_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  static const String _terms = '''
# Divine ARC Terms & Conditions

**Last Updated:** July 2, 2026

Welcome to Divine ARC. By downloading, accessing, or using the Divine ARC application, you agree to these Terms & Conditions.

## 1. Acceptance of Terms

By using Divine ARC, you agree to comply with these Terms & Conditions and all applicable laws and regulations.

## 2. Use of the Application

Divine ARC provides devotional and spiritual content, including Aarti, Shlokas, audio playback, and an AI-powered spiritual assistant.

You agree to use the application only for lawful purposes and not to misuse, disrupt, or interfere with its services.

## 3. User Account

You are responsible for maintaining the confidentiality of your account and for all activities performed through your account.

You are responsible for ensuring that the information you provide is accurate and up to date.

## 4. AI Assistant

The AI Assistant is provided to answer spiritual and devotional questions.

AI-generated responses are intended for informational and devotional purposes only and should not be considered legal, medical, financial, or professional advice.

## 5. User Content

You are responsible for any text, voice input, profile pictures, or other content you submit through the application.

You agree not to upload or transmit unlawful, offensive, abusive, defamatory, or harmful content.

## 6. Intellectual Property

All content, including text, images, audio, logos, design, and software within Divine ARC, is the property of Divine ARC or its licensors and is protected by applicable intellectual property laws.

You may not copy, modify, distribute, or reproduce any part of the application without prior written permission.

## 7. Limitation of Liability

While we strive to provide accurate and reliable services, Divine ARC is provided on an "as is" and "as available" basis.

We are not responsible for any direct, indirect, incidental, or consequential damages arising from the use of the application.

## 8. Changes to These Terms

We may update these Terms & Conditions from time to time. Continued use of Divine ARC after any updates constitutes acceptance of the revised Terms.

## 9. Governing Law

These Terms & Conditions shall be governed by and interpreted in accordance with the laws of India.

## Contact Us

If you have any questions regarding these Terms & Conditions, please contact us:

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
          'Terms & Conditions',
          style: FTextStyle.defaultTextSemiBold,
        ),
      ),
      body: Markdown(
        padding: const EdgeInsets.all(20),
        selectable: true,
        data: _terms,
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
