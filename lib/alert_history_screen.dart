import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flow_period_tracker/models/period_alert.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PeriodAlert>('periodAlerts').listenable(),
        builder: (context, Box<PeriodAlert> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No alerts yet.'));
          }

          final List<PeriodAlert> alerts = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Dismissible(
                key: ValueKey(alert.key), // Use alert.key for unique identification
                direction: DismissDirection.endToStart, // Swipe from right to left
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  alert.delete(); // Delete the alert from Hive
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert dismissed')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.message,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(alert.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Type: ${alert.type}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
