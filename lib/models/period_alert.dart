import 'package:hive/hive.dart';

part 'period_alert.g.dart';

@HiveType(typeId: 3) // Ensure this typeId is unique
class PeriodAlert extends HiveObject {
  @HiveField(0)
  late String message;

  @HiveField(1)
  late DateTime timestamp;

  @HiveField(2)
  late String type; // e.g., 'irregularity', 'consult_doctor'

  PeriodAlert({required this.message, required this.timestamp, required this.type});
}
