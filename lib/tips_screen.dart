import 'package:flutter/material.dart';
import 'main_page.dart';
import 'chat_screen.dart';

class TipsScreen extends StatelessWidget {
  final Map<String, List<String>> categories = {
    "Rest & Recovery 😴": [
      "Prioritize 7-9 hours of sleep nightly.",
      "Incorporate short naps (20-30 mins) if needed.",
      "Practice deep breathing or meditation before bed.",
      "Create a relaxing bedtime routine (e.g., warm bath, reading).",
      "Limit screen time before sleep.",
      "Listen to calming music or white noise.",
      "Ensure your sleep environment is dark, quiet, and cool."
    ],
    "Productivity & Distraction 📝": [
      "Break tasks into smaller, manageable chunks.",
      "Use the Pomodoro Technique (25 mins work, 5 mins break).",
      "Eliminate distractions: turn off notifications, close unnecessary tabs.",
      "Set clear goals for each work session.",
      "Take regular short breaks to stretch or walk around.",
      "Listen to instrumental music to aid focus.",
      "Delegate tasks when possible."
    ],
    "Social & Emotional Support 🤗": [
      "Talk to a trusted friend or family member.",
      "Join a support group or online community.",
      "Practice active listening when others speak.",
      "Offer help to others; it can boost your own mood.",
      "Spend quality time with loved ones.",
      "Don't be afraid to ask for help when you need it.",
      "Practice empathy and understanding towards yourself and others."
    ],
    "Remedies & Pain Relief 💊": [
      "Apply a warm compress to soothe cramps.",
      "Stay hydrated with water and herbal teas.",
      "Gentle exercise like walking or yoga can help.",
      "Over-the-counter pain relievers (e.g., ibuprofen) if necessary.",
      "Try essential oils like lavender or peppermint (diluted).",
      "Acupressure on specific points can offer relief.",
      "Rest in a comfortable position."
    ],
    "Lifestyle & Self-care 🛀": [
      "Maintain a balanced diet rich in fruits, veggies, and whole grains.",
      "Engage in regular physical activity you enjoy.",
      "Practice mindfulness or meditation daily.",
      "Spend time in nature.",
      "Pursue hobbies that bring you joy.",
      "Limit caffeine and alcohol intake.",
      "Schedule 'me-time' for relaxation and reflection."
    ],
    "Entertainment & Watching 📺": [
      "Watch a comforting movie or TV show.",
      "Discover new music or podcasts.",
      "Read a captivating book.",
      "Play a relaxing video game.",
      "Explore documentaries or educational content.",
      "Engage in creative activities like drawing or writing.",
      "Listen to audiobooks or storytelling podcasts."
    ],
    "Food & Drinks 🍎": [
      "Eat iron-rich foods (spinach, lentils) during menstruation.",
      "Increase intake of magnesium (nuts, dark chocolate) for cramps.",
      "Avoid excessive salt to reduce bloating.",
      "Opt for complex carbohydrates for sustained energy.",
      "Drink plenty of water throughout the day.",
      "Limit sugary snacks and processed foods.",
      "Consider ginger or turmeric for anti-inflammatory benefits."
    ],
  };

  void _showTipsPopup(
      BuildContext context, String categoryName, List<String> tips) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(categoryName, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins')),
          content: SingleChildScrollView(
            child: ListBody(
              children: tips
                  .map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text("• $tip", style: const TextStyle(fontFamily: 'Poppins')),
                      ))
                  .toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontFamily: 'Poppins')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ask Sophia', style: TextStyle(fontFamily: 'Poppins')),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen()),
                );
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Health & Wellness Tips",
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFff6f61),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            String categoryName = categories.keys.elementAt(index);
            List<String> tips = categories.values.elementAt(index);
            String emoji =
                categoryName.split(' ').last;

            return GestureDetector(
              onTap: () => _showTipsPopup(context, categoryName, tips),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFffb199).withOpacity(0.7),
                        const Color(0xFFff6f61).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          categoryName
                              .replaceAll(emoji, '')
                              .trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainPage()));
          } else if (index == 1)
            return;
          else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => ChatScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFff6f61),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}
