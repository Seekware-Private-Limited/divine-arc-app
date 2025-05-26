part of 'home_flow_bloc.dart';

@immutable
sealed class HomeFlowEvent {}

class CreateSessionEvent extends HomeFlowEvent {
  final String language;
  CreateSessionEvent({required this.language});
}

class ChatEvent extends HomeFlowEvent {
  final String message;
  final String language;
  final String sessionId;
  ChatEvent({required this.message,required this.language,required this.sessionId});
}

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