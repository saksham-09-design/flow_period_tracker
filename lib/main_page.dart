import 'package:flow_period_tracker/chat_screen.dart';
import 'package:flow_period_tracker/models/saved_date_range.dart';
import 'package:flow_period_tracker/tips_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flow_period_tracker/models/period_alert.dart';
import 'package:flow_period_tracker/alert_history_screen.dart';
import 'package:flow_period_tracker/utils/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // State variables for the calendar
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Reference to the opened Hive box
  late Box<SavedDateRange> _savedRangesBox;
  late Box<PeriodAlert> _periodAlertsBox;

  // Irregularity thresholds (in days)
  final int minCycleLength = 21;
  final int maxCycleLength = 35;

  

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Get the box instance. Assumes it's opened in your main.dart file.
    _savedRangesBox = Hive.box('date_ranges');
    _periodAlertsBox = Hive.box('periodAlerts');
  }

  bool _isInitialCheckDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialCheckDone) {
      _checkIrregularity();
      _isInitialCheckDone = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// This function is called when a date range is selected on the calendar.
  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  /// This function saves the currently selected date range to the Hive box.
  void _saveDateRange() {
    if (_rangeStart != null && _rangeEnd != null) {
      final newRange = SavedDateRange(start: _rangeStart!, end: _rangeEnd!);
      // Use add() to let Hive auto-assign an incrementing key
      _savedRangesBox.add(newRange);

      // Clear the selection from the calendar UI
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date range saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _checkIrregularity(); // Check for irregularity after saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid date range first.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  
  void _checkIrregularity() {
    List<String> localAlertMessages = [];

    final List<SavedDateRange> sortedRanges = _savedRangesBox.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (sortedRanges.length < 2) {
      return;
    }

    List<int> cycleLengths = [];
    List<String> irregularCycleDates = []; // To store dates of irregular cycles
    for (int i = 1; i < sortedRanges.length; i++) {
      final Duration difference =
          sortedRanges[i].start.difference(sortedRanges[i - 1].start);
      cycleLengths.add(difference.inDays);

      // Store dates for the current cycle
      final String cycleDateRange =
          '${DateFormat('MMM dd').format(sortedRanges[i - 1].start)} - ${DateFormat('MMM dd').format(sortedRanges[i].start)}';

      if (cycleLengths.last < minCycleLength ||
          cycleLengths.last > maxCycleLength) {
        irregularCycleDates.add(cycleDateRange);
      } else {
        irregularCycleDates.clear(); // Reset if a regular cycle is found
      }

      if (irregularCycleDates.length >= 3) {
        final String message =
            "Irregular periods detected for the last 3 cycles (${irregularCycleDates.join(', ')}). Consider consulting a doctor.";
        _addAlert(message, 'irregularity');
        localAlertMessages.add(message);
        break; // Only show one "3 irregular cycles" alert at a time
      } else if (irregularCycleDates.isNotEmpty) {
        final String message =
            "Irregular period detected. Cycle length: ${cycleLengths.last} days. (Cycle: ${irregularCycleDates.last})";
        _addAlert(message, 'irregularity');
        localAlertMessages.add(message);
      }
    }

    // Check for concurrent alerts for "consult doctor"
    final List<PeriodAlert> recentIrregularityAlerts = _periodAlertsBox.values
        .where((alert) =>
            alert.type == 'irregularity' &&
            DateTime.now().difference(alert.timestamp).inDays <= 90) // Within last 3 months
        .toList();

    if (recentIrregularityAlerts.length >= 2) {
      final String message = "You should consult a doctor.";
      _addAlert(message, 'consult_doctor');
      localAlertMessages.add(message);
    }

    if (localAlertMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAlertPopup(localAlertMessages);
      });
    }
  }

  void _showAlertPopup(List<String> messages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert!'),
          icon: const Icon(Icons.warning, color: Colors.red, size: 40),
          content: SingleChildScrollView(
            child: ListBody(
              children: messages.map((msg) => Text(msg)).toList(),
            ),
          ),
          actions: 
          <Widget>[
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

  

  void _addAlert(String message, String type) {
    // Check for duplicate before adding
    final bool isDuplicate = _periodAlertsBox.values.any(
      (alert) => alert.message == message && alert.type == type,
    );

    if (!isDuplicate) {
      final newAlert =
          PeriodAlert(message: message, timestamp: DateTime.now(), type: type);
      _periodAlertsBox.add(newAlert);
    }
  }

  /// Shows a bottom sheet with options to edit or delete a range.
  void _showRangeOptions(SavedDateRange range) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet
              _editRange(range);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () async {
              // The delete() method is now available because SavedDateRange extends HiveObject
              await range.delete();
              // The ValueListenableBuilder will automatically update the UI.
              Navigator.pop(context); // Close the bottom sheet
              _checkIrregularity(); // Re-check irregularity after deletion
            },
          ),
        ],
      ),
    );
  }

  /// Opens a date range picker to edit an existing range.
  void _editRange(SavedDateRange range) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );

    if (picked != null) {
      // Update the fields of the HiveObject
      range.start = picked.start;
      range.end = picked.end;
      // The save() method is now available to persist the changes.
      await range.save();
      // The ValueListenableBuilder will automatically update the UI.
      _checkIrregularity(); // Re-check irregularity after editing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Periods Tracker',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Alert History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- CALENDAR WIDGET ---
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                onRangeSelected: _onRangeSelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // --- STYLING THE CALENDAR ---
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: AppColors.primaryAccent.withOpacity(0.2),
                  rangeStartDecoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  formatButtonShowsNext: false,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // --- SAVE BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDateRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Date Range',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // --- SAVED DATES LIST ---
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _savedRangesBox.listenable(),
              builder: (context, Box<SavedDateRange> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('No saved date ranges yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final SavedDateRange? range = box.getAt(index);
                    if (range == null) return const SizedBox.shrink();

                    final String monthYear =
                        DateFormat.yMMMM().format(range.start);
                    final String dateRangeString =
                        '${DateFormat('dd').format(range.start)} - ${DateFormat('dd').format(range.end)}';

                    return GestureDetector(
                      onTap: () => _showRangeOptions(range),
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // --- LEFT PART (20%): IMAGE PLACEHOLDER ---
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryAccent,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),

                            // --- RIGHT PART (80%): TEXT INFO ---
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      monthYear,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateRangeString,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Track is index 0
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => TipsScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => ChatScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryAccent,
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
