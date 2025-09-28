import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitaGPT Audio Recorder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecordingScreen(),
    );
  }
}

class CustomRecordingButton extends StatelessWidget {
  const CustomRecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 100,
      width: 100,
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isRecording ? 25 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: isRecording ? 8 : 3),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: const CircleBorder(),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool isRecording = false;
  bool isPlaying = false;
  bool isPlayingResponse = false;
  bool isSending = false;

  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  String? _audioPath;
  String? _responseAudioPath;
  String? _apiResponse; // raw response for debugging

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
        isPlayingResponse = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${_generateRandomId()}.wav';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );
    } catch (e) {
      debugPrint('[GitaGPT] ERROR START RECORDING: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        isRecording = false;
        _audioPath = path;
      });
      if (_audioPath != null) await _sendAudioToApi();
    } catch (e) {
      debugPrint('[GitaGPT] ERROR STOP RECORDING: $e');
    }
  }

  Future<void> _sendAudioToApi() async {
    if (_audioPath == null) return;
    setState(() {
      isSending = true;
      _apiResponse = null;
    });

    try {
      final uri = Uri.parse(
        'https://gitagptapi.vexoo.ai/api/voice-conversation',
      );
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Origin': 'null',
        'User-Agent': 'FlutterApp',
      });

      request.fields['language'] = 'english';
      request.fields['session_id'] = 'd39f6353-6a38-445c-a660-91ebe3519bce';

      request.files.add(
        await http.MultipartFile.fromPath('audio', _audioPath!),
      );

      final response = await request.send();
      final responseBytes = await response.stream.toBytes();

      debugPrint('[GitaGPT] STATUS: ${response.statusCode}');
      debugPrint('[GitaGPT] HEADERS: ${response.headers}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('audio')) {
          // 🔊 Binary WAV response
          final responsePath = await _writeResponseFile(responseBytes);
          setState(() => _responseAudioPath = responsePath);
          debugPrint('[GitaGPT] SAVED BINARY AUDIO RESPONSE: $responsePath');
        } else {
          // 📝 Handle textual / JSON / HEX
          final responseText = utf8.decode(responseBytes, allowMalformed: true);
          setState(() => _apiResponse = responseText);

          try {
            final json = jsonDecode(responseText);
            if (json is Map<String, dynamic> && json.containsKey('audio')) {
              final hexString = json['audio'];
              if (_isValidHex(hexString)) {
                final bytes = _hexToBytes(hexString);
                final responsePath = await _writeResponseFile(bytes);
                setState(() => _responseAudioPath = responsePath);
                debugPrint(
                  '[GitaGPT] SAVED JSON+HEX AUDIO RESPONSE: $responsePath',
                );
              }
            }
          } catch (_) {
            // Not JSON — maybe plain HEX
            if (_isValidHex(responseText)) {
              final bytes = _hexToBytes(responseText);
              final responsePath = await _writeResponseFile(bytes);
              setState(() => _responseAudioPath = responsePath);
              debugPrint(
                '[GitaGPT] SAVED PLAIN HEX AUDIO RESPONSE: $responsePath',
              );
            } else {
              debugPrint('[GitaGPT] NON-JSON TEXT RESPONSE: $responseText');
            }
          }
        }
      } else {
        final errorText = utf8.decode(responseBytes, allowMalformed: true);
        debugPrint('[GitaGPT] API ERROR: ${response.statusCode} $errorText');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('[GitaGPT] ERROR SENDING AUDIO: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending audio: $e')));
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<String> _writeResponseFile(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_generateRandomId()}_response.wav';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  bool _isValidHex(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean) && clean.length % 2 == 0;
  }

  List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'\s+'), '');
    return [
      for (int i = 0; i < clean.length; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ];
  }

  Future<void> _playRecording() async {
    if (_audioPath == null) return;
    await _audioPlayer.play(DeviceFileSource(_audioPath!));
  }

  Future<void> _playResponseAudio() async {
    if (_responseAudioPath == null) return;
    await _audioPlayer.play(DeviceFileSource(_responseAudioPath!));
  }

  void _record() async {
    if (!isRecording) {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        setState(() {
          isRecording = true;
          _audioPath = null;
          _responseAudioPath = null;
          _apiResponse = null;
        });
        await _startRecording();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
    } else {
      await _stopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitaGPT Audio Recorder')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRecordingButton(
                isRecording: isRecording,
                onPressed: _record,
              ),
              const SizedBox(height: 16),
              if (isRecording)
                const Text(
                  'Recording...',
                  style: TextStyle(color: Colors.blue),
                ),
              if (isSending)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Sending to API...',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              if (!isRecording && _audioPath != null)
                Column(
                  children: [
                    Text('Recorded: ${_audioPath?.split('/').last}'),
                    ElevatedButton(
                      onPressed: isPlaying ? null : _playRecording,
                      child: Text(isPlaying ? 'Playing...' : 'Play Recording'),
                    ),
                  ],
                ),
              if (!isRecording && _responseAudioPath != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Response: ${_responseAudioPath?.split('/').last}'),
                    ElevatedButton(
                      onPressed: isPlayingResponse ? null : _playResponseAudio,
                      child: Text(
                        isPlayingResponse ? 'Playing...' : 'Play Response',
                      ),
                    ),
                  ],
                ),
              if (_apiResponse != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _apiResponse!,
                    style: const TextStyle(color: Colors.red),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
