import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:divine_arc/Utils/api_constant.dart';
import 'package:divine_arc/Utils/connectivity_service.dart';
import 'package:divine_arc/Utils/pref_utils.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
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
        } catch (e, stackTrace) {
          print("Voice conversation error");
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
      if (await ConnectivityService.isConnected()) {
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
            emit(
              SessionExpiredStateHome('Session expired. Please login again.'),
            );
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
      } else {
        emit(CheckNetworkConnectionHomeFlow());
        print("🚫 No internet connection.");
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
      // Check for internet connectivity
      if (await ConnectivityService.isConnected()) {
        emit(UpdateProfileLoading());

        final Uri requestUrl = Uri.parse(APIEndPoints.updateProfile);
        final requestBody = jsonEncode({'name': event.name});
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
  }
}
