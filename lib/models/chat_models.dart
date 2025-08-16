import 'package:hive/hive.dart';

part 'chat_models.g.dart';

@HiveType(typeId: 1)
class ChatMessage {
  @HiveField(0)
  final String sender; // "You" or "Gemini"

  @HiveField(1)
  final String text;

  ChatMessage({required this.sender, required this.text});
}

@HiveType(typeId: 2)
class ChatGroup {
  @HiveField(0)
  final String title; // First message sent by user

  @HiveField(1)
  final List<ChatMessage> messages;

  ChatGroup({required this.title, required this.messages});
}
