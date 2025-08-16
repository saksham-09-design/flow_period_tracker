import 'package:flow_period_tracker/chat_screen.dart';
import 'package:flow_period_tracker/models/saved_date_range.dart';
import 'package:flow_period_tracker/tips_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flow_period_tracker/models/period_alert.dart';
import 'package:flow_period_tracker/alert_history_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  late Box<SavedDateRange> _savedRangesBox;
  late Box<PeriodAlert> _periodAlertsBox;

  final int minCycleLength = 21;
  final int maxCycleLength = 35;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  void _saveDateRange() {
    if (_rangeStart != null && _rangeEnd != null) {
      final newRange = SavedDateRange(start: _rangeStart!, end: _rangeEnd!);
      _savedRangesBox.add(newRange);

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
      _checkIrregularity();
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
    List<String> irregularCycleDates = [];
    for (int i = 1; i < sortedRanges.length; i++) {
      final Duration difference =
          sortedRanges[i].start.difference(sortedRanges[i - 1].start);
      cycleLengths.add(difference.inDays);

      final String cycleDateRange =
          '${DateFormat('MMM dd').format(sortedRanges[i - 1].start)} - ${DateFormat('MMM dd').format(sortedRanges[i].start)}';

      if (cycleLengths.last < minCycleLength ||
          cycleLengths.last > maxCycleLength) {
        irregularCycleDates.add(cycleDateRange);
      } else {
        irregularCycleDates.clear();
      }

      if (irregularCycleDates.length >= 3) {
        final String message =
            "Irregular periods detected for the last 3 cycles (${irregularCycleDates.join(', ')}). Consider consulting a doctor.";
        _addAlert(message, 'irregularity');
        localAlertMessages.add(message);
        break;
      } else if (irregularCycleDates.isNotEmpty) {
        final String message =
            "Irregular period detected. Cycle length: ${cycleLengths.last} days. (Cycle: ${irregularCycleDates.last})";
        _addAlert(message, 'irregularity');
        localAlertMessages.add(message);
      }
    }

    final List<PeriodAlert> recentIrregularityAlerts = _periodAlertsBox.values
        .where((alert) =>
            alert.type == 'irregularity' &&
            DateTime.now().difference(alert.timestamp).inDays <= 90)
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
    final userNameBox = Hive.box('userName');
    final name = userNameBox.get('name', defaultValue: 'Friend');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert for $name!', style: const TextStyle(fontFamily: 'Poppins')),
          icon: const Icon(Icons.warning, color: Colors.red, size: 40),
          content: SingleChildScrollView(
            child: ListBody(
              children: messages
                  .map((msg) => Text(msg, style: const TextStyle(fontFamily: 'Poppins')))
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
          ],
        );
      },
    );
  }

  void _addAlert(String message, String type) {
    final bool isDuplicate = _periodAlertsBox.values.any(
      (alert) => alert.message == message && alert.type == type,
    );

    if (!isDuplicate) {
      final newAlert =
          PeriodAlert(message: message, timestamp: DateTime.now(), type: type);
      _periodAlertsBox.add(newAlert);
    }
  }

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
              Navigator.pop(context);
              _editRange(range);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () async {
              await range.delete();
              Navigator.pop(context);
              _checkIrregularity();
            },
          ),
        ],
      ),
    );
  }

  void _editRange(SavedDateRange range) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: range.start, end: range.end),
    );

    if (picked != null) {
      range.start = picked.start;
      range.end = picked.end;
      await range.save();
      _checkIrregularity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Period Tracker',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFff6f61),
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
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: const Color(0xFFffb199).withOpacity(0.3),
                  rangeStartDecoration: const BoxDecoration(
                    color: Color(0xFFff6f61),
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Color(0xFFff6f61),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFFff6f61).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFFff6f61),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: const Color(0xFFff6f61),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  formatButtonShowsNext: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDateRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFff6f61),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Period',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _savedRangesBox.listenable(),
              builder: (context, Box<SavedDateRange> box, _) {
                if (box.isEmpty) {
                  return const Center(
                      child: Text('No saved periods yet.',
                          style: TextStyle(fontFamily: 'Poppins')));
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFFff6f61),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
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
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateRangeString,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
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
        currentIndex: 0,
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
