// lib/saved_date_range.dart

import 'package:hive/hive.dart';

// This line is needed for the Hive generator
part 'saved_date_range.g.dart';

@HiveType(typeId: 0)
class SavedDateRange extends HiveObject {
  @HiveField(0)
  late DateTime start;

  @HiveField(1)
  late DateTime end;

  SavedDateRange({required this.start, required this.end});
}