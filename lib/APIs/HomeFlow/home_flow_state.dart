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
  final Map<String, dynamic> error;
  ChatErrorState(this.error);
}

// Upload Audio States
class VoiceConversationLoading extends HomeFlowState {}

class VoiceConversationSuccess extends HomeFlowState {
  final dynamic successResponse;
  VoiceConversationSuccess(this.successResponse);
}

class VoiceConversationFailure extends HomeFlowState {
  final String failureResponse;
  VoiceConversationFailure(this.failureResponse);
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
  final Map<String, dynamic> successResponse;
  GetChatHistorySuccess(this.successResponse);
}

class GetChatHistoryFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetChatHistoryFailure(this.failureResponse);
}

// React On Chat states
class ReactOnChatLoading extends HomeFlowState {}

class ReactOnChatSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  ReactOnChatSuccess(this.successResponse);
}

class ReactOnChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  ReactOnChatFailure(this.failureResponse);
}

// Chat Feedback States
class ChatFeedbackLoading extends HomeFlowState {}

class ChatFeedbackSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  ChatFeedbackSuccess(this.successResponse);
}

class ChatFeedbackFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  ChatFeedbackFailure(this.failureResponse);
}

// Share Chat States
class ShareChatLoading extends HomeFlowState {}

class ShareChatSuccess extends HomeFlowState {
  final String successResponse;
  ShareChatSuccess(this.successResponse);
}

class ShareChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  ShareChatFailure(this.failureResponse);
}

// Logout States
class LogoutLoading extends HomeFlowState {}

class LogoutSuccess extends HomeFlowState {
  final String successRespose;
  LogoutSuccess({required this.successRespose});
}

class LogoutFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  LogoutFailure(this.failureResponse);
}

// Update Profile States
class UpdateProfileLoading extends HomeFlowState {}

class UpdateProfileLoaded extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  UpdateProfileLoaded(this.successResponse);
}

class UpdateProfileError extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  UpdateProfileError(this.failureResponse);
}

// Get Single Chat History States
class GetSingleChatHistoryLoading extends HomeFlowState {}

class GetSingleChatHistorySuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  GetSingleChatHistorySuccess(this.successResponse);
}

class GetSingleChatHistoryFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetSingleChatHistoryFailure(this.failureResponse);
}

// Get Random Quote States
class GetRandomQuoteLoading extends HomeFlowState {}

class GetRandomQuoteSuccess extends HomeFlowState {
  final String successResponse;
  GetRandomQuoteSuccess(this.successResponse);
}

class GetRandomQuoteFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetRandomQuoteFailure(this.failureResponse);
}

// Get All Prayers States
class GetAllPrayersLoading extends HomeFlowState {}

class GetAllPrayersLoaded extends HomeFlowState {
  final List<dynamic> successResponse;
  GetAllPrayersLoaded(this.successResponse);
}

class GetAllPrayersFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetAllPrayersFailure(this.failureResponse);
}

// Bookmark Single Chat States
class BookmarkChatLoading extends HomeFlowState {}

class BookmarkChatSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  BookmarkChatSuccess(this.successResponse);
}

class BookmarkChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  BookmarkChatFailure(this.failureResponse);
}

// Unbookmark Single Chat States
class UnbookmarkChatLoading extends HomeFlowState {}

class UnbookmarkChatSuccess extends HomeFlowState {
  final Map<String, dynamic> successResponse;
  UnbookmarkChatSuccess(this.successResponse);
}

class UnbookmarkChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  UnbookmarkChatFailure(this.failureResponse);
}

// Get All Bookmarks Chat States
class GetAllBookmarksChatLoading extends HomeFlowState {}

class GetAllBookmarksChatSuccess extends HomeFlowState {
  final List<dynamic> successResponse;
  GetAllBookmarksChatSuccess(this.successResponse);
}

class GetAllBookmarksChatFailure extends HomeFlowState {
  final Map<String, dynamic> failureResponse;
  GetAllBookmarksChatFailure(this.failureResponse);
}

// Common Server Failure State
class CommonServerFailure extends HomeFlowState {
  final String error;
  CommonServerFailure(this.error);
}

// Check Network Connection State
class CheckNetworkConnection extends HomeFlowState {}
