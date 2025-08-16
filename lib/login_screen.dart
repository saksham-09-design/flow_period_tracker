import 'package:flow_period_tracker/main_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  late Box userName;
  String uName = "";

  // Explicitly manage the FocusNode
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();

    userName = Hive.box('userName');
    _nameController.text = userName.get('name', defaultValue: '');
    _nameFocusNode = FocusNode();

    // Post-frame callback ensures the context is ready for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _loadUserName() async {
    uName = userName.get('name') ?? "Guest";
    print(uName);
  }

  Future<void> _initApp() async {
    await _loadUserName();
    if (uName != 'Guest') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus node
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _saveName() {
    String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      userName.put('name', name);
      // Dismiss the keyboard
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, $name!',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF5A44F0),
        ),
      );
    }
  }

  void _continue() {
    _saveName();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // A very light, modern gray
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //  Modern Logo or Image
              // Make sure to have a light-themed logo
              SizedBox(
                height: 150,
                child: Image.asset(
                  "assets/images/girl.png", // Use a placeholder or your own image
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              //  Title and Subtitle
              const Text(
                "FLOW Welcomes YOU😊",
                style: TextStyle(
                  color: Color(0xFF1E2749), // Dark, deep blue-gray
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "What should we call you?",
                style: TextStyle(
                  color: Color(0xFF7B859A), // Soft, muted gray for subtitle
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Card Container
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E2749).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2749),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      // Assign the FocusNode to the TextField
                      focusNode: _nameFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: Color(0xFFB0B8C8)),
                        filled: true,
                        fillColor: const Color(
                            0xFFF7F9FC), // Very light gray for the field background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(
                                0xFF5A44F0), // A vibrant blue-violet for focus
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                      ),
                      style: const TextStyle(color: Color(0xFF1E2749)),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A44F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 8,
                          shadowColor: const Color(0xFF5A44F0).withOpacity(0.3),
                        ),
                        onPressed: _continue,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
