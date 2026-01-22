import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:divine_arc/Utils/api_constant.dart';
import 'package:divine_arc/Utils/connectivity_service.dart';
import 'package:divine_arc/Utils/pref_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
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
        print("Request URL: $requestUrl");

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
            print("Create Session Response Data: $data");
          } else {
            final errorData = jsonDecode(response.body);
            emit(CreateSessionFailure(errorData));
            print("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("Exception: $e");
        }
      }
    });

    // Chat Bloc
    on<ChatEvent>((event, emit) async {
      // Step 1: Connectivity Validation — Legacy reliability preserved
      if (await ConnectivityService.isConnected()) {
        emit(ChatLoadingState());

        final requestUrl = Uri.parse(APIEndPoints.streamChat);
        final requestBody = {
          'message': event.message,
          'language': event.language,
          'session_id': event.sessionId,
        };

        print("📡 [API REQUEST] → URL: $requestUrl");
        print("📝 [REQUEST BODY]: ${jsonEncode(requestBody)}");

        http.Client? client;

        try {
          client = http.Client();

          final request =
              http.Request('POST', requestUrl)
                ..headers['accept'] = 'application/json'
                ..headers['Content-Type'] = 'application/json'
                ..body = jsonEncode(requestBody);

          final response = await client.send(request);

          print("📥 [RESPONSE STATUS]: ${response.statusCode}");
          print("📄 [RESPONSE HEADERS]: ${response.headers}");

          if (response.statusCode == 200) {
            final contentType = response.headers['content-type']?.toLowerCase();

            // Step 2: Handle Streaming Responses
            if (contentType?.contains('text/plain') == true ||
                contentType?.contains('text/event-stream') == true) {
              StringBuffer buffer = StringBuffer();

              await for (final chunk in response.stream.transform(
                utf8.decoder,
              )) {
                buffer.write(chunk);
                emit(ChatStreamingState(chunk));
              }

              final finalMessage = buffer.toString();
              print("✅ [FINAL STREAM RESPONSE]: $finalMessage");

              emit(ChatLoadedState(finalMessage));
            }
            // Step 3: Handle Non-Streaming Success
            else {
              final body = await response.stream.bytesToString();
              print("⚠️ [UNEXPECTED CONTENT TYPE]: $contentType");
              print("📄 [RAW RESPONSE BODY]: $body");

              emit(
                ChatErrorState({
                  'error': 'Unsupported content type: $contentType',
                  'raw_response': body,
                }),
              );
            }
          }
          // Step 4: Handle Non-200 Server Responses
          else {
            final body = await response.stream.bytesToString();
            print("❌ [ERROR RESPONSE BODY]: $body");

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
          emit(CheckNetworkConnectionHomeFlow());
          print("🚫 SocketException: No internet connection.");
        } catch (e) {
          emit(
            ChatErrorState({
              'error': 'Something went wrong, Please try again later',
              'details': e.toString(),
            }),
          );
          print("💥 Exception: $e");
        } finally {
          client?.close();
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("🌐 No internet connection.");
      }
    });

    // Voice Chat Conversation Bloc
    on<VoiceConversationEvent>((event, emit) async {
      if (await ConnectivityService.isConnected()) {
        emit(VoiceConversationLoading());

        final requestUrl = Uri.parse(APIEndPoints.voiceConversation);
        print("Request URL: $requestUrl");
        print(
          "Sending multipart request with fields: language=${event.language}, session_id=${event.sessionId}",
        );

        try {
          final request = http.MultipartRequest('POST', requestUrl);

          request.headers.addAll({
            'Accept': '*/*',
            'Connection': 'keep-alive',
            'Origin': 'null',
            'User-Agent': 'FlutterApp',
          });

          request.fields['language'] = event.language;
          request.fields['session_id'] = event.sessionId;
          request.files.add(
            await http.MultipartFile.fromPath('audio', event.audioFile.path),
          );

          final response = await request.send();
          final responseBytes = await response.stream.toBytes();

          if (response.statusCode == 200) {
            final contentType = response.headers['content-type'] ?? '';

            if (contentType.contains('audio')) {
              // Binary audio response
              emit(VoiceConversationSuccess(responseBytes));
            } else {
              // Handle JSON or text response
              final responseText = utf8.decode(
                responseBytes,
                allowMalformed: true,
              );
              try {
                final json = jsonDecode(responseText);
                if (json is Map<String, dynamic> && json.containsKey('audio')) {
                  emit(
                    VoiceConversationSuccess(json),
                  ); // JSON with hex-encoded audio
                } else {
                  emit(VoiceConversationFailure("Unexpected JSON response"));
                }
              } catch (_) {
                // Non-JSON response, possibly plain hex or text
                emit(VoiceConversationSuccess(responseText));
              }
            }
          } else {
            final errorText = utf8.decode(responseBytes, allowMalformed: true);
            emit(
              VoiceConversationFailure(
                "API error: ${response.statusCode} $errorText",
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) ("Voice conversation error");
          emit(VoiceConversationFailure("Exception: $e"));
        }
      } else {
        emit(VoiceConversationFailure("No internet connection"));
      }
    });

    // Initiate Chat Bloc
    on<InitiateChatEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(InitiateChatLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.initiateChat);
        print("Request URL: $requestUrl");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: jsonEncode({
              'message': event.message,
              'chat_id': event.chatId,
              'is_guest': event.isGuest,
              'model_name': event.modelName,
              'search_engine': event.searchEngine,
              'edited': event.edited,
              'sender': event.sender,
            }),
          );

          if (response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(InitiateChatSuccess(responseData['data']));
            print("Initiate Chat Response Data: ${responseData['data']}");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(InitiateChatFailure(errorData));
            print("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("No internet connection.");
      }
    });

    // Store Chat Bloc
    on<StoreChatEvent>((event, emit) async {
      // Step 1: Connectivity Check — Legacy approach retained for reliability
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnectionHomeFlow());
        print("🚫 No internet connection.");
        return;
      }

      emit(StoreChatLoading());

      final Uri requestUrl = Uri.parse(APIEndPoints.storeChatConversation);
      print("📡 [API REQUEST] → URL: $requestUrl");

      // Step 2: Build Request Body
      final Map<String, dynamic> requestBody = {
        'message': event.message,
        'chat_id': event.chatId,
        'model_name': event.modelName,
        'search_engine': event.searchEngine,
        'edited': event.edited,
        'sender': event.sender,
      };

      // ✅ Conditionally include audioUrl
      if (event.audioUrl != null && event.audioUrl!.isNotEmpty) {
        requestBody['audio_url'] = event.audioUrl;
      }

      print("📝 [REQUEST BODY]: ${jsonEncode(requestBody)}");

      try {
        // Step 3: Execute POST Call
        final response = await http.post(
          requestUrl,
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'Cookie': PrefUtils.getToken(),
          },
          body: jsonEncode(requestBody),
        );

        print("📥 [RESPONSE STATUS]: ${response.statusCode}");
        print("📄 [RESPONSE BODY]: ${response.body}");

        // Step 4: Evaluate Response
        if (response.statusCode == 201) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          emit(StoreChatSuccess(responseData['data']));
          print("✅ Store Chat Success: ${responseData['data']}");
        } else if (response.statusCode == 401) {
          emit(SessionExpiredStateHome('Session expired. Please login again.'));
        } else {
          final errorData = jsonDecode(response.body);
          emit(StoreChatError(errorData));
          print("❌ Store Chat Error: $errorData");
        }
      } on SocketException {
        emit(CheckNetworkConnectionHomeFlow());
        print("⚠️ SocketException: No internet connection.");
      } catch (e) {
        emit(
          CommonServerFailureHome(
            'Something went wrong, Please try again later',
          ),
        );
        print("💥 Exception: $e");
      }
    });

    // Send API Response Bloc
    on<SendAPIResponseEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(SendAPIResponseLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.sendAPIResponse);
        final requestBody = jsonEncode({
          'message_id': event.messageId,
          'api_name': event.apiName,
          'api_type': event.apiType,
          'audio_url': event.audioUrl,
          'api_response': event.apiResponse,
          'status': event.apiStatus,
          'api_error': event.apiError,
        });

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(SendAPIResponseSuccess(responseData['data']));
            print(
              "✅ SEND API RESPONSE API - Response Data: ${responseData['data']}",
            );
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(SendAPIResponseFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Get All Chat Conversation History Bloc
    on<GetChatHistoryEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(GetChatHistoryLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.getChatHistory);
        print("Request URL: $requestUrl");

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(GetChatHistorySuccess(responseData));
            print("Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(GetChatHistoryFailure(errorData));
            print("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("No internet connection.");
      }
    });

    // React On Chat Bloc
    on<ReactOnChatEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ReactOnChatLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.reactOnChat);
        final requestBody = jsonEncode({
          'message_id': event.message_id,
          'is_like': event.is_like,
          'type': event.type,
          'is_guest': event.is_guest,
        });

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(ReactOnChatSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ReactOnChatFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Chat Feedback Bloc
    on<ChatFeedbackEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ChatFeedbackLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.chatFeedback);
        final requestBody = jsonEncode({
          'feedbackText': event.feedbackText,
          'reactionId': event.reactionId,
        });

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(ChatFeedbackSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ChatFeedbackFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Chat Feedback Bloc
    on<ShareChatEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ShareChatLoading());

        final Uri requestUrl = Uri.parse(
          APIEndPoints.shareChatUrl(event.chatId),
        );

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ShareChatSuccess(responseData['shareUrl']));
            print("✅ Parsed Response Data: ${responseData['shareUrl']}");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ShareChatFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Logout Bloc
    on<LogoutEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(LogoutLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.logout);

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(LogoutSuccess(successRespose: responseData['message']));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(LogoutFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Update Profile Bloc
    on<UpdateProfileEvent>((event, emit) async {
      if (await ConnectivityService.isConnected()) {
        emit(UpdateProfileLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.updateProfile);
        final requestBody = jsonEncode({
          'name': event.name,
          'profile_picture': event.profilePicture,
        });
        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(UpdateProfileLoaded(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(UpdateProfileError(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Get Single Chat Conversation History Bloc
    on<GetSingleChatHistoryEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(GetSingleChatHistoryLoading());

        final Uri requestUrl = Uri.parse(
          APIEndPoints.singleChatHistory(event.chatId),
        );

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(GetSingleChatHistorySuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(GetSingleChatHistoryFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Get Random Quote Event
    on<GetRandomQuoteEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(GetRandomQuoteLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.getRandomQuote);

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final quote = response.body;
            emit(GetRandomQuoteSuccess(quote));
          } else {
            final errorData = jsonDecode(response.body);
            emit(GetRandomQuoteFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Get All Prayers GET API
    on<GetAllPrayersEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(GetAllPrayersLoading());

        final Uri requestUrl = Uri.parse(
          APIEndPoints.allPrayers(PrefUtils.getLanguage()),
        );

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(GetAllPrayersLoaded(responseData));
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(GetAllPrayersFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Bookmark Chat Bloc
    on<BookmarkChat>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(BookmarkChatLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.bookmarkChat);
        final requestBody = jsonEncode({'message_id': event.messageId});

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(BookmarkChatSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(BookmarkChatFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Unbookmark Chat Bloc
    on<UnbookmarkChat>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(UnbookmarkChatLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.bookmarkChat);
        final requestBody = jsonEncode({'message_id': event.messageId});

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.delete(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print("🟣 Response Status Code: ${response.statusCode}");
          print("🟤 Raw Response Body: ${response.body}");

          if (response.statusCode == 201) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(UnbookmarkChatSuccess(responseData));
            print("✅ Parsed Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(UnbookmarkChatFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Get All Prayers GET API
    on<GetAllBookmarksChat>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(GetAllBookmarksChatLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.bookmarkChatList);

        if (kDebugMode) {
          print("🔵 Request URL: $requestUrl");
        }
        if (kDebugMode) {
          print(
            "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
          );
        }

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          if (kDebugMode) {
            print("🟣 Response Status Code: ${response.statusCode}");
          }
          if (kDebugMode) {
            print("🟤 Raw Response Body: ${response.body}");
          }

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(GetAllBookmarksChatSuccess(responseData));
          }
          /// 🚨 TOKEN EXPIRED / INVALID
          else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(GetAllBookmarksChatFailure(errorData));
            if (kDebugMode) {
              print("❌ Error Response Data: $errorData");
            }
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          if (kDebugMode) {
            print("❗ SocketException: No internet connection.");
          }
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          if (kDebugMode) {
            print("❗ Exception: $e");
          }
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        if (kDebugMode) {
          print("❗ No internet connection.");
        }
      }
    });

    on<UploadFile>((event, emit) async {
      if (!await ConnectivityService.isConnected()) {
        emit(CheckNetworkConnectionHomeFlow());
        return;
      }

      emit(UploadFileLoading());

      try {
        final uri = Uri.parse(APIEndPoints.uploadfile);
        final request = http.MultipartRequest('POST', uri);

        // Add authorization
        final token = PrefUtils.getToken();
        request.headers['Cookie'] = token;
        request.headers['accept'] = 'application/json';

        // Add file
        final file = File(event.file);
        if (await file.exists()) {
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();

          // Determine content type based on file extension
          final extension = path.extension(file.path).toLowerCase();
          MediaType contentType;

          if (extension == '.mp3') {
            contentType = MediaType('audio', 'mpeg');
          } else if (extension == '.wav') {
            contentType = MediaType('audio', 'wav');
          } else if (extension == '.png') {
            contentType = MediaType('image', 'png');
          } else if (extension == '.jpg' || extension == '.jpeg') {
            contentType = MediaType('image', 'jpeg');
          } else {
            contentType = MediaType('application', 'octet-stream');
          }

          final multipartFile = http.MultipartFile(
            'file',
            fileStream,
            fileLength,
            filename: path.basename(file.path),
            contentType: contentType,
          );
          request.files.add(multipartFile);
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print("🟣 Upload File Status: ${response.statusCode}");
        print("🟤 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          emit(UploadFileSuccess(data, isResponseAudio: event.isResponseAudio));

          // Only save as profile picture if it's not a response audio file
          if (data['url'] != null && event.isResponseAudio != true) {
            PrefUtils.setProfilePicture(data['url']);
          }
        } else if (response.statusCode == 401) {
          emit(SessionExpiredStateHome('Session expired. Please login again.'));
        } else {
          Map<String, dynamic> errorData = {};
          try {
            errorData = jsonDecode(response.body);
          } catch (_) {
            errorData = {'message': 'Failed to upload file'};
          }
          emit(
            UploadFileFailure(
              errorData,
              isResponseAudio: event.isResponseAudio,
            ),
          );
        }
      } on SocketException {
        emit(CheckNetworkConnectionHomeFlow());
      } catch (e, stack) {
        print("Upload file error: $e");
        emit(
          UploadFileFailure({
            'message': e.toString(),
          }, isResponseAudio: event.isResponseAudio),
        );
      }
    });
    // View User Profile Bloc
    on<ViewUserProfile>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(UserProfileLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.viewProfile);
        print("Request URL: $requestUrl");

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(UserProfileLoaded(responseData));
            print("Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(UserProfileError(errorData));
            print("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("No internet connection.");
      }
    });

    // View All Content Bloc
    on<ViewAllContent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(ViewAllContentLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.viewAllContent);
        print("Request URL: $requestUrl");

        try {
          final response = await http.get(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
          );

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            emit(ViewAllContentLoaded(responseData));
            print("Response Data: $responseData");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(ViewAllContentError(errorData));
            print("Error Response: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("No internet connection.");
      }
    });

    // Send Regenerate Chat API Response
    on<SendRegenerateAPIResponseEvent>((event, emit) async {
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(SendRegenerateAPIResponseLoading());

        final Uri requestUrl = Uri.parse(
          APIEndPoints.sendregenerateAPIResponse,
        );
        final requestBody = jsonEncode({
          'message_id': event.messageId,
          'api_name': event.apiName,
          'api_type': event.apiType,
          'api_response': event.apiResponse,
          'status': event.apiStatus,
          'api_error': event.apiError,
        });

        print("🔵 Request URL: $requestUrl");
        print(
          "🟡 Request Headers: ${{'accept': 'application/json', 'Content-Type': 'application/json', 'Cookie': PrefUtils.getToken()}}",
        );
        print("🟠 Request Body: $requestBody");

        try {
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: requestBody,
          );

          print(
            "🟣 Send Regenerate Chat Response Status Code: ${response.statusCode}",
          );
          print("🟤  Send Regenerate Chat Raw Response Body: ${response.body}");

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(SendRegenerateAPIResponseSuccess(responseData['data']));
            print(
              "✅ Send Regenerate Chat API RESPONSE API - Response Data: ${responseData['data']}",
            );
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(SendRegenerateAPIResponseFailure(errorData));
            print("❌ Error Response Data: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("❗ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("❗ Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("❗ No internet connection.");
      }
    });

    // Store Editted Chat Bloc
    on<StoreEdittedChatEvent>((event, emit) async {
      // Step 1: Connectivity Check — Legacy approach retained for reliability
      if (await ConnectivityService.isConnected()) {
        emit(StoreEdittedChatLoading());

        final Uri requestUrl = Uri.parse(
          APIEndPoints.storeEdittedChatConversation,
        );
        print("📡 [Store Editted API REQUEST] → URL: $requestUrl");

        // Step 2: Build Request Body
        final Map<String, dynamic> requestBody = {
          'message': event.message,
          'chat_id': event.chatId,
          'message_id': event.messageId,
          'model_name': event.modelName,
          'search_engine': event.searchEngine,
          'edited': event.edited,
          'sender': event.sender,
        };

        print("📝 [Store Editted REQUEST BODY]: ${jsonEncode(requestBody)}");

        try {
          // Step 3: Execute POST Call
          final response = await http.post(
            requestUrl,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
              'Cookie': PrefUtils.getToken(),
            },
            body: jsonEncode(requestBody),
          );

          print("📥 [Store Edited RESPONSE STATUS]: ${response.statusCode}");
          print("📄 [Store Edited RESPONSE BODY]: ${response.body}");

          // Step 4: Evaluate Response
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            emit(StoreEdittedChatSuccess(responseData['data']));
            print("✅ Store Chat Success: ${responseData['data']}");
          } else if (response.statusCode == 401) {
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
          } else {
            final errorData = jsonDecode(response.body);
            emit(StoreEdittedChatError(errorData));
            print("❌ Store Chat Error: $errorData");
          }
        } on SocketException {
          emit(CheckNetworkConnectionHomeFlow());
          print("⚠️ SocketException: No internet connection.");
        } catch (e) {
          emit(
            CommonServerFailureHome(
              'Something went wrong, Please try again later',
            ),
          );
          print("💥 Exception: $e");
        }
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("🚫 No internet connection.");
      }
    });
  }
}
