import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/chat_models.dart';

class PreviousChatsScreen extends StatefulWidget {
  const PreviousChatsScreen({super.key});

  @override
  State<PreviousChatsScreen> createState() => _PreviousChatsScreenState();
}

class _PreviousChatsScreenState extends State<PreviousChatsScreen> {
  void _showChatPopup(BuildContext context, ChatGroup chatGroup, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  chatGroup.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: chatGroup.messages.map((msg) {
                        bool isUser = msg.sender == "You";
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFff6f61)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${msg.sender}: ${msg.text}",
                            style: TextStyle(
                              fontWeight:
                                  isUser ? FontWeight.bold : FontWeight.normal,
                              color: isUser ? Colors.white : Colors.black87,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
                      onPressed: () {
                        final chatBox = Hive.box<ChatGroup>('chatGroups');
                        chatBox.deleteAt(index);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: const Text("Close", style: TextStyle(fontFamily: 'Poppins')),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatBox = Hive.box<ChatGroup>('chatGroups');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Previous Chats",
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFff6f61),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: chatBox.length,
        itemBuilder: (context, index) {
          final chatGroup = chatBox.getAt(index);
          if (chatGroup == null) return const SizedBox();

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(chatGroup.title, style: const TextStyle(fontFamily: 'Poppins')),
              subtitle: Text(
                chatGroup.messages.isNotEmpty
                    ? "${chatGroup.messages.length} messages"
                    : "No messages",
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () => _showChatPopup(context, chatGroup, index),
            ),
          );
        },
      ),
    );
  }
}
