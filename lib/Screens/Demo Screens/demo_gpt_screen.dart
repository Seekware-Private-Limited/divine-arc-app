import 'dart:async';
import 'package:flutter/material.dart';

class ChatTypingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Typing Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChatTypingScreen(),
    );
  }
}

class ChatTypingScreen extends StatefulWidget {
  @override
  _ChatTypingScreenState createState() => _ChatTypingScreenState();
}

class _ChatTypingScreenState extends State<ChatTypingScreen> {
  final ScrollController _scrollController = ScrollController();
  final String fullResponse =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";
  String displayedText = "";
  int _currentIndex = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _startTypingEffect();
  }

  void _startTypingEffect() {
    _typingTimer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (_currentIndex < fullResponse.length) {
        setState(() {
          displayedText += fullResponse[_currentIndex];
          _currentIndex++;
        });
        _maybeScrollToBottom();
      } else {
        _typingTimer?.cancel();
      }
    });
  }

  void _maybeScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final isNearBottom = (maxScroll - currentScroll) <= 50;

        if (isNearBottom || maxScroll > 0) {
          _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ChatGPT Typing Effect")),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        child: Text(
          displayedText,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
