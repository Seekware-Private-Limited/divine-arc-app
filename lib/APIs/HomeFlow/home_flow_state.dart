part of 'home_flow_bloc.dart';

@immutable
sealed class HomeFlowState {}

final class HomeFlowInitial extends HomeFlowState {}


// Create Session States
class CreateSessionLoading extends HomeFlowState {}

class CreateSessionSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  CreateSessionSuccess(this.successResponse);
}

class CreateSessionFailure extends HomeFlowState {
  final String error;
  CreateSessionFailure(this.error);
}


// Chat States
class ChatLoadingState extends HomeFlowState {}

class ChatLoadedState extends HomeFlowState {
  final String partialResponse;
  ChatLoadedState(this.partialResponse);
}

class ChatStreamingState extends HomeFlowState {
  final String response;
  ChatStreamingState(this.response);
}

class ChatErrorState extends HomeFlowState {
  final Map<String,dynamic> error;
  ChatErrorState(this.error);
}

// Upload Audio States
class VoiceConversationLoading extends HomeFlowState {}

class VoiceConversationSuccess extends HomeFlowState {
  final String transcription;
  final String sessionId;
  final List<int> audioBytes; // Response .wav bytes

  VoiceConversationSuccess({
    required this.transcription,
    required this.sessionId,
    required this.audioBytes,
  });

}

class VoiceConversationFailure extends HomeFlowState {
  final String error;
  VoiceConversationFailure(this.error);
}


// Initiate Chat States
class InitiateChatLoading extends HomeFlowState {}

class InitiateChatSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  InitiateChatSuccess(this.successResponse);
}

class InitiateChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  InitiateChatFailure(this.failureResponse);
}


// Store Chat States
class StoreChatLoading extends HomeFlowState {}

class StoreChatSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  StoreChatSuccess(this.successResponse);
}

class StoreChatError extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  StoreChatError(this.failureResponse);
}


// Send API Response States
class SendAPIResponseLoading extends HomeFlowState {}

class SendAPIResponseSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  SendAPIResponseSuccess(this.successResponse);
}

class SendAPIResponseFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  SendAPIResponseFailure(this.failureResponse);
}


// Get Chat History States
class GetChatHistoryLoading extends HomeFlowState {}

class GetChatHistorySuccess extends HomeFlowState {
  final Map<String,dynamic> successResponse;
  GetChatHistorySuccess(this.successResponse);
}

class GetChatHistoryFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetChatHistoryFailure(this.failureResponse);
}


// Common Server Failure State
class CommonServerFailure extends HomeFlowState {
  final String error;
  CommonServerFailure(this.error);

}

// Check Network Connection State
class CheckNetworkConnection extends HomeFlowState {}
