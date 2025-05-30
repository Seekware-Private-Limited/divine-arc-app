class APIEndPoints {

   // Streaming APIs
   static const String streamingBaseUrl = 'https://gitagptapi.vexoo.ai';

   static const String createSession = '$streamingBaseUrl/api/session';
   static const String streamChat = '$streamingBaseUrl/api/chat/stream';
   static const String voiceConversation = '$streamingBaseUrl/api/voice-conversation';
   static const String getVoices = '$streamingBaseUrl/api/voices';
   static String getConversation(String sessionId) => '$streamingBaseUrl/api/conversations/$sessionId';
   static const String getRandomQuote = '$streamingBaseUrl/api/quote/stream';
   static const String healthCheck = '$streamingBaseUrl/api/health';

   // GitaGPT App APIs
   static const String baseUrl = 'https://gitagptapp.vexoo.ai';
   static const String signup = '$baseUrl/auth/register';
   static const String login = '$baseUrl/auth/login';
   static const String googleLogin = '$baseUrl/auth/google/login';
   static const String initiateChat = '$baseUrl/chat/initiate';
   static const String storeChatConversation = '$baseUrl/chat/store';
   static const String sendAPIResponse = '$baseUrl/chat/api-response';
   static const String getChatHistory = '$baseUrl/chat/history';
   static const String reactOnChat = '$baseUrl/chat/react';
   static const String chatFeedback = '$baseUrl/chat/feedback';
   static String shareChatUrl(String chatId) => '$baseUrl/chat/$chatId/share';
   static const String logout = '$baseUrl/auth/logout';

}
