import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIEndPoints {
  // Base URLs fetched safely from .env with fallback defaults
  static String get streamingBaseUrl =>
      dotenv.env['STREAMING_BASE_URL'] ?? 'https://gitagptapi.vexoo.ai';

  static String get baseUrl =>
      dotenv.env['APP_BASE_URL'] ?? 'https://api.divinearc.in';

  // Streaming APIs
  static String get createSession => '$streamingBaseUrl/api/session';
  static String get streamChat => '$streamingBaseUrl/api/chat/stream';
  static String get voiceConversation =>
      '$streamingBaseUrl/api/voice-conversation';
  static String get getVoices => '$streamingBaseUrl/api/voices';
  static String getConversation(String sessionId) =>
      '$streamingBaseUrl/api/conversations/$sessionId';
  static String get getRandomQuote => '$streamingBaseUrl/api/quote/stream';
  static String get healthCheck => '$streamingBaseUrl/api/health';

  // GitaGPT App APIs
  static String get signup => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get socialLogin => '$baseUrl/auth/socialLogin';
  static String get initiateChat => '$baseUrl/chat/initiate';
  static String allPrayers(String lan) => '$baseUrl/chat/$lan/prayers';
  static String get storeChatConversation => '$baseUrl/chat/store';
  static String get storeEdittedChatConversation => '$baseUrl/chat/store/edit';
  static String get sendAPIResponse => '$baseUrl/chat/api-response';
  static String get sendregenerateAPIResponse =>
      '$baseUrl/chat/api-response/update';
  static String get getChatHistory => '$baseUrl/chat/history';
  static String get reactOnChat => '$baseUrl/chat/react';
  static String get chatFeedback => '$baseUrl/chat/feedback';
  static String get bookmarkChat => '$baseUrl/chat/bookmark';
  static String get bookmarkChatList => '$baseUrl/chat/bookmarks';
  static String shareChatUrl(String chatId) => '$baseUrl/chat/$chatId/share';
  static String get logout => '$baseUrl/auth/logout';
  static String get updateProfile => '$baseUrl/users/me/update-profile';
  static String get updatePassword => '$baseUrl/users/me/update-password';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String singleChatHistory(String chatId) =>
      '$baseUrl/chat/$chatId/history';
  static String get uploadfile => '$baseUrl/users/upload';
  static String get viewProfile => '$baseUrl/users/me';
  static String get viewAllContent => '$baseUrl/content';
  static String viewContentById(String id) => '$baseUrl/content/$id';
  static String get sendDeviceToken => '$baseUrl/device-token';
  static String get appConfig => '$baseUrl/app-config';
  static String get trendingQuestions => '$baseUrl/trending-questions/random';
  static String get reportIssue => '$baseUrl/support';
  static String get completeProfile => '$baseUrl/auth/complete-profile';
}
