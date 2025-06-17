part of 'home_flow_bloc.dart';

@immutable
sealed class HomeFlowEvent {}

// Create Session Event
class CreateSessionEvent extends HomeFlowEvent {
  final String language;
  CreateSessionEvent({required this.language});
}

// Initiate Chat Event
class InitiateChatEvent extends HomeFlowEvent {
  final String message;
  final bool isGuest;
  final String modelName;
  final String searchEngine;
  final bool edited;
  final String sender;
  final String chatId;

  InitiateChatEvent({
    required this.message,
    required this.isGuest,
    required this.modelName,
    required this.searchEngine,
    required this.edited,
    required this.sender,
    required this.chatId,
  });
}

// Store Chat Event
class StoreChatEvent extends HomeFlowEvent {
  final String message;
  final String modelName;
  final String searchEngine;
  final bool edited;
  final String sender;
  final String chatId;

  StoreChatEvent({
    required this.message,
    required this.modelName,
    required this.searchEngine,
    required this.edited,
    required this.sender,
    required this.chatId,
  });
}

// Send Chat API Response Event
class SendAPIResponseEvent extends HomeFlowEvent {
  final String messageId;
  final String apiName;
  final String apiType;
  final String apiResponse;
  final String apiStatus;
  final String apiError;

  SendAPIResponseEvent({
    required this.messageId,
    required this.apiName,
    required this.apiType,
    required this.apiResponse,
    required this.apiStatus,
    required this.apiError,
  });
}

// Get Chat History Event
class GetChatHistoryEvent extends HomeFlowEvent {}

// Get Random Quote Event
class GetRandomQuoteEvent extends HomeFlowEvent {}

// Stream Chat Event
class ChatEvent extends HomeFlowEvent {
  final String message;
  final String language;
  final String sessionId;
  ChatEvent({
    required this.message,
    required this.language,
    required this.sessionId,
  });
}

// Voice-Chat Event
class VoiceConversationEvent extends HomeFlowEvent {
  final File audioFile;
  final String language;
  final String sessionId;

  VoiceConversationEvent({
    required this.audioFile,
    required this.language,
    required this.sessionId,
  });
}

// React On Chat Event
class ReactOnChatEvent extends HomeFlowEvent {
  final String message_id;
  final bool is_guest;
  final bool is_like;
  final String type;


  ReactOnChatEvent({
    required this.message_id,
    required this.is_guest,
    required this.is_like,
    required this.type,
  });
}

// Share Chat Event
class ShareChatEvent extends HomeFlowEvent {
  final String chatId;
  ShareChatEvent({required this.chatId});
}


// Logout Event
class LogoutEvent extends HomeFlowEvent {}

class ChatFeedbackEvent extends HomeFlowEvent {
 final String reactionId;
 final String feedbackText;

 ChatFeedbackEvent({
   required this.reactionId,
   required this.feedbackText
  });
}

// Update Profile Name Event
class UpdateProfileEvent extends HomeFlowEvent {
  final String name;
  UpdateProfileEvent({required this.name});
}

// Get Single Chat History
class GetSingleChatHistoryEvent extends HomeFlowEvent {
  final String chatId;
  GetSingleChatHistoryEvent({required this.chatId});
}

