import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:gita_gpt/Utils/api_constant.dart';
import 'package:gita_gpt/Utils/connectivity_service.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

part 'home_flow_event.dart';
part 'home_flow_state.dart';

class HomeFlowBloc extends Bloc<HomeFlowEvent, HomeFlowState> {
  HomeFlowBloc() : super(HomeFlowInitial()) {

    // Create Session Bloc
    on<CreateSessionEvent>((event, emit) async {
      if (await ConnectivityService.isConnected()) {
        emit(CreateSessionLoading());

        final requestUrl = Uri.parse(APIEndPoints.createSession);
        developer.log("Request URL: $requestUrl");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'language': event.language}),
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = jsonDecode(response.body);
            emit(CreateSessionSuccess(data));
            developer.log("Response Data: $data");
          } else {
            final errorData = jsonDecode(response.body);
            emit(CreateSessionFailure(errorData));
            developer.log("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnection());
          developer.log("SocketException: No internet connection.");
        } catch (e) {
          emit(CommonServerFailure('An error occurred: $e'));
          developer.log("Exception: $e");
        }
      }
    });

    // Chat Bloc
    on<ChatEvent>((event, emit) async {
      if (await ConnectivityService.isConnected()) {
        emit(ChatLoadingState());

        final requestUrl = Uri.parse(APIEndPoints.streamChat);
        developer.log("Request URL: $requestUrl");
        developer.log(
          "Request Body: ${jsonEncode({'message': event.message, 'language': event.language, 'session_id': event.sessionId})}",
        );

        http.Client? client;

        try {
          client = http.Client();

          final request =
              http.Request('POST', requestUrl)
                ..headers['accept'] = 'application/json'
                ..headers['Content-Type'] = 'application/json'
                ..body = jsonEncode({
                  'message': event.message,
                  'language': event.language,
                  'session_id': event.sessionId,
                });

          final response = await client.send(request);
          developer.log("Response Status: ${response.statusCode}");

          if (response.statusCode == 200) {
            final contentType = response.headers['content-type']?.toLowerCase();

            if (contentType?.contains('text/plain') == true ||
                contentType?.contains('text/event-stream') == true) {
              StringBuffer buffer = StringBuffer();

              await for (final chunk in response.stream.transform(
                utf8.decoder,
              )) {
                buffer.write(chunk);
                emit(ChatStreamingState(chunk)); // emit only the new chunk
              }

              emit(
                ChatLoadedState(buffer.toString()),
              ); // ✅ Final message complete
            } else {
              final body = await response.stream.bytesToString();
              emit(
                ChatErrorState({
                  'error': 'Unsupported content type: $contentType',
                  'raw_response': body,
                }),
              );
            }
          } else {
            final body = await response.stream.bytesToString();
            try {
              final json = jsonDecode(body);
              emit(ChatErrorState({'error': json.toString()}));
            } catch (e) {
              emit(
                ChatErrorState({
                  'error': 'Server error: ${response.statusCode}',
                  'raw_response': body,
                }),
              );
            }
          }
        } on SocketException {
          emit(CheckNetworkConnection());
        } catch (e) {
          emit(
            ChatErrorState({
              'error': 'An error occurred: $e',
              'details': e.toString(),
            }),
          );
        } finally {
          client?.close();
        }
      } else {
        emit(CheckNetworkConnection());
      }
    });

    // Voice Chat Conversation Bloc
    on<VoiceConversationEvent>((event, emit) async {
      if (await ConnectivityService.isConnected()) {
        emit(VoiceConversationLoading());

        final requestUrl = Uri.parse(APIEndPoints.voiceConversation);
        developer.log("Request URL: $requestUrl");
        developer.log(
          "Sending multipart request with fields: language=${event.language}, session_id=${event.sessionId}",
        );

        try {
          final request = http.MultipartRequest('POST', requestUrl)
            ..fields['language'] = event.language
            ..fields['session_id'] = event.sessionId
            ..files.add(
              await http.MultipartFile.fromPath(
                'audio',
                event.audioFile.path,
                contentType: MediaType('audio', 'wav'),
              ),
            );

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          developer.log("Response status: ${response.statusCode}");
          developer.log("Response headers: ${response.headers}");
          developer.log("Response body (bytes): ${response.bodyBytes.length} bytes");

          if (response.statusCode == 200) {
            final contentType = response.headers['content-type'];

            if (contentType != null && contentType.contains("application/json")) {
              final json = jsonDecode(response.body);
              emit(
                VoiceConversationFailure(
                  "Unexpected JSON response: ${json.toString()}",
                ),
              );
            } else {
              final transcription = response.headers['x-transcription'] ?? '';
              final sessionId = response.headers['x-session-id'] ?? '';

              emit(
                VoiceConversationSuccess(
                  transcription: transcription,
                  sessionId: sessionId,
                  audioBytes: response.bodyBytes,
                ),
              );
            }
          } else {
            emit(
              VoiceConversationFailure(
                "Failed: ${response.statusCode} ${response.reasonPhrase}",
              ),
            );
          }
        } catch (e, stackTrace) {
          developer.log("Voice conversation error", error: e, stackTrace: stackTrace);
          emit(VoiceConversationFailure("Exception: $e"));
        }
      } else {
        emit(VoiceConversationFailure("No internet connection"));
      }
    });

  }
}
