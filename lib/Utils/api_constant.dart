class APIEndPoints {
  // Streaming APIs
  static const String streamingBaseUrl = 'https://gitagptapi.vexoo.ai';

  static const String createSession = '$streamingBaseUrl/api/session';
  static const String streamChat = '$streamingBaseUrl/api/chat/stream';
  static const String voiceConversation =
      '$streamingBaseUrl/api/voice-conversation';
  static const String getVoices = '$streamingBaseUrl/api/voices';
  static String getConversation(String sessionId) =>
      '$streamingBaseUrl/api/conversations/$sessionId';
  static const String getRandomQuote = '$streamingBaseUrl/api/quote/stream';
  static const String healthCheck = '$streamingBaseUrl/api/health';

  // GitaGPT App APIs
  // static const String baseUrl = 'https://api.divinearc.in'; // Production
  // static const String baseUrl = 'https://gitagptapp.vexoo.ai'; // Staging
  static const String baseUrl = 'https://9b731a839f81.ngrok-free.app'; // Local

  static const String signup = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String socialLogin = '$baseUrl/auth/socialLogin';
  static const String googleLogin = '$baseUrl/auth/google/login';
  static const String initiateChat = '$baseUrl/chat/initiate';
  static String allPrayers(String lan) => '$baseUrl/chat/$lan/prayers';
  static const String storeChatConversation = '$baseUrl/chat/store';
  static const String storeEdittedChatConversation = '$baseUrl/chat/store/edit';
  static const String sendAPIResponse = '$baseUrl/chat/api-response';
  static const String sendregenerateAPIResponse =
      '$baseUrl/chat/api-response/update';
  static const String getChatHistory = '$baseUrl/chat/history';
  static const String reactOnChat = '$baseUrl/chat/react';
  static const String chatFeedback = '$baseUrl/chat/feedback';
  static const String bookmarkChat = '$baseUrl/chat/bookmark';
  static const String bookmarkChatList = '$baseUrl/chat/bookmarks';
  static String shareChatUrl(String chatId) => '$baseUrl/chat/$chatId/share';
  static const String logout = '$baseUrl/auth/logout';
  static const String updateProfile = '$baseUrl/users/me/update-profile';
  static const String updatePassword = '$baseUrl/users/me/update-password';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static String singleChatHistory(String chatId) =>
      '$baseUrl/chat/$chatId/history';
  static const String uploadfile = '$baseUrl/users/upload';
  static const String viewProfile = '$baseUrl/users/me';
  static const String viewAllContent = '$baseUrl/content';
  static const String sendDeviceToken = '$baseUrl/device-token';
}
