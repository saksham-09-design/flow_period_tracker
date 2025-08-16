import 'package:flow_period_tracker/login_screen.dart';
import 'package:flow_period_tracker/models/saved_date_range.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('userName');
  Hive.registerAdapter(SavedDateRangeAdapter());
  await Hive.openBox<SavedDateRange>('date_ranges');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Flow",
      home: LoginScreen(),
    );
  }
}
