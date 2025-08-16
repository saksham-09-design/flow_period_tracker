import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'main_page.dart';
import 'tips_screen.dart';
import 'models/chat_models.dart';
import 'previous_chat_screen.dart';
import 'package:uuid/uuid.dart';
import 'widgets/loading_dots.dart';
import 'api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  late Box<ChatGroup> _chatBox;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  String? _currentGroupId; // Unique ID for each conversation
  String? _currentGroupTitle;

  final uuid = const Uuid();

  final model = GenerativeModel(
    model: 'gemini-2.5-flash-lite',
    apiKey: API().api,
  );

  @override
  void initState() {
    super.initState();
    _chatBox = Hive.box<ChatGroup>('chatGroups');
    _startNewChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomePopup();
    });
  }

  @override
  void dispose() {
    _saveChatLocally();
    super.dispose();
  }

  void _startNewChat() {
    _saveChatLocally(); // Save current before starting new
    setState(() {
      _messages.clear();
      _currentGroupId = uuid.v4(); // new unique id
      _currentGroupTitle = null;
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(sender: "You", text: text));
      if (_currentGroupTitle == null) {
        _currentGroupTitle = text;
      }
      _isTyping = true;
    });

    _saveChatLocally(); // Save after user message

    String textTosend =
        "Answer the following question: $text. Guidelines: Act as an Emotional Support Bot and Give response in roughly 5 to 100 words depeding on the question. You can include pointers and emojes in your response. Note: Dont mention any of the guidelines in your response.";

    _controller.clear();

    String reply = await _getGeminiResponse(textTosend);

    setState(() {
      _messages.add(ChatMessage(sender: "Gemini", text: reply));
      _isTyping = false;
    });

    _saveChatLocally(); // Save after bot reply
  }

  Future<String> _getGeminiResponse(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text?.replaceAll("*", "").replaceAll("#", "") ??
          "Sorry, I couldn't process that.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  void _saveChatLocally() {
    if (_messages.isEmpty ||
        _currentGroupId == null ||
        _currentGroupTitle == null) return;

    final existingGroup = _chatBox.get(_currentGroupId);

    if (existingGroup != null) {
      // Append messages
      final updatedMessages = List<ChatMessage>.from(existingGroup.messages)
        ..clear()
        ..addAll(_messages);

      _chatBox.put(
        _currentGroupId,
        ChatGroup(title: _currentGroupTitle!, messages: updatedMessages),
      );
    } else {
      // Create new group
      _chatBox.put(
        _currentGroupId,
        ChatGroup(title: _currentGroupTitle!, messages: _messages),
      );
    }
  }

  void _showWelcomePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to Sophia!'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/girl.png', height: 100),
                const SizedBox(height: 16),
                const Text(
                  "Hi, I am Sophia your personal Assistant. You can chill with me anytime, I'll be there for you.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sophia", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A44F0),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: Colors.white),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Previous Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PreviousChatsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        LoadingDots(), // Custom loading animation
                      ],
                    ),
                  );
                }

                final msg = _messages[index];
                bool isUser = msg.sender == "You";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isUser ? const Color(0xFF5A44F0) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 2),
            ]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF5A44F0)),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainPage()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => TipsScreen()));
          } else if (index == 2)
            return;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5A44F0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_outlined), label: 'Track'),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline), label: 'Tips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        ],
      ),
    );
  }
}
