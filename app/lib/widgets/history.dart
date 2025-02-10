import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/shared_preferences_helper.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';
import 'package:chronosculpt/data_structures.dart';
import 'package:flutter/material.dart';

/// Retrieves the past 30 days of data from the
/// database and launches the main history widget.
class HistoryWidgetWrapper extends StatefulWidget {
  const HistoryWidgetWrapper({super.key});

  @override
  State<HistoryWidgetWrapper> createState() => _HistoryWidgetWrapperState();
}

class _HistoryWidgetWrapperState extends State<HistoryWidgetWrapper> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Record>>(
      future: DatabaseHelper().getPastRecords(getCurrentUserUid()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return SnapshotErrorScreen(snapshot: snapshot);
        }

        if (snapshot.data == null) {
          return const ErrorScreen(message: 'The data was unexpectedly null.');
        }

        return HistoryWidget(
          records: snapshot.data!,
        );
      },
    );
  }
}

class HistoryPopupMenu extends StatefulWidget {
  final Function refresher;
  final int value;

  const HistoryPopupMenu({
    super.key,
    required this.refresher,
    required this.value,
  });

  @override
  State<HistoryPopupMenu> createState() => _HistoryPopupMenuState();
}

class _HistoryPopupMenuState extends State<HistoryPopupMenu> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textStyle = TextStyle(color: colorScheme.secondary);

    var items = [
      PopupMenuItem<int>(
        value: 7,
        child: Text('Past week', style: textStyle),
      ),
      PopupMenuItem<int>(
        value: 14,
        child: Text('Past 2 weeks', style: textStyle),
      ),
      PopupMenuItem<int>(
        value: 30,
        child: Text('Past month', style: textStyle),
      ),
      PopupMenuItem<int>(
        value: 90,
        child: Text('Past 3 months', style: textStyle),
      ),
      PopupMenuItem<int>(
        value: 0,
        child: Text('All time', style: textStyle),
      ),
    ];

    return PopupMenuButton<int>(
      tooltip: 'Change history view',
      borderRadius: BorderRadius.circular(50),
      initialValue: widget.value,
      onSelected: (value) async {
        await SharedPreferencesHelper().setPreferredHistory(value);
        widget.refresher();
      },
      itemBuilder: (context) => items,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.more_horiz, color: colorScheme.surface),
      ),
    );
  }
}

/// Launches the two main views for displaying
/// past history data.
class HistoryWidget extends StatefulWidget {
  final List<Record> records;
  const HistoryWidget({
    super.key,
    required this.records,
  });

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

final _selectedView = <bool>[true, false];
class _HistoryWidgetState extends State<HistoryWidget> {
  List<Widget> _tabs = [];
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    for (int i = 0; i < _selectedView.length; i++) {
      if (_selectedView[i]) _view = i;
    }

    if (_tabs.isEmpty) {
      _tabs = [
        PastRecordsWidget(records: widget.records),
        PastHabitsWidget(records: widget.records)
      ];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(50),
              selectedColor: colorScheme.secondary,
              color: colorScheme.surface,
              fillColor: colorScheme.surface,
              constraints: BoxConstraints(
                minHeight: 40.0,
                minWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              onPressed: (int index) {
                setState(
                  () {
                    for (int i = 0; i < _selectedView.length; i++) {
                      _selectedView[i] = i == index;
                    }
                  },
                );
              },
              isSelected: _selectedView,
              children: const [
                Text(
                  'Records',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Habits',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _view,
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a list of all past records.
class PastRecordsWidget extends StatefulWidget {
  final List<Record> records;
  const PastRecordsWidget({super.key, required this.records});

  @override
  State<PastRecordsWidget> createState() => _PastRecordsWidgetState();
}

class _PastRecordsWidgetState extends State<PastRecordsWidget> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    if (widget.records.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.secondary,
        body: Center(
          child: Text(
            'No past records found',
            style: TextStyle(
                color: colorScheme.surfaceContainerLowest, fontSize: 20.0),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.records.length,
      itemBuilder: (context, i) {
        var record = widget.records[i];
        int totalDone = 0;
        int totalHabits = 0;
        for (var entry in record.entries) {
          totalHabits++;
          if (entry.done) totalDone++;
        }

        double donePercentage =
            totalHabits == 0 ? 0 : (totalDone / totalHabits) * 100;

        return HabitCard(
          textColor: colorScheme.secondary,
          backgroundColor: colorScheme.surface,
          title: record.date.toString().split(' ')[0],
          comments: '$totalDone out of $totalHabits done',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PastRecordDisplayWidget(record: record),
              ),
            );
          },
          topRightWidget: DonePercentage(
            val: donePercentage.toStringAsFixed(0),
          ),
        );
      },
    );
  }
}

class DonePercentage extends StatelessWidget {
  final String val;
  const DonePercentage({super.key, required this.val});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Text(
      '$val%',
      style: TextStyle(
        fontSize: 24,
        color: colorScheme.secondary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Displays detailed information at the habit level.
class PastHabitsWidget extends StatefulWidget {
  static List<HabitRetrospective> past30DaysHabits = [];
  static Map<int, HabitRetrospective> past30DaysHabitsMap = {};
  final List<Record> records;
  const PastHabitsWidget({super.key, required this.records});

  static void analyzeData(List<Record> data) {
    // calculate habit statistics
    Map<int, HabitRetrospective> map = {};
    for (var record in data) {
      for (var entry in record.entries) {
        entry.dateOfOccurrence = record.date;
        if (map.containsKey(entry.hid)) {
          map[entry.hid]!.occurrences.add(entry);
        } else {
          HabitRetrospective hr = HabitRetrospective(
            name: entry.habitName,
            occurrences: [entry],
            hid: entry.hid,
          );
          map[entry.hid] = hr;
        }
      }
    }

    PastHabitsWidget.past30DaysHabits =
        map.entries.toList().map((e) => e.value).toList();
    PastHabitsWidget.past30DaysHabitsMap = map;

    past30DaysHabits.sort((a, b) => b.donePercentage.compareTo(a.donePercentage)); 
  }

  static Future<void> retrieveAndAnalyzeData() async {
    try {
      var data = await DatabaseHelper().getPastRecords(getCurrentUserUid());
      analyzeData(data);
    } catch (e) {
      // showSnackBar(context, e.toString());
    }
  }

  @override
  State<PastHabitsWidget> createState() => _PastHabitsWidgetState();
}

class _PastHabitsWidgetState extends State<PastHabitsWidget> {
  final _controller = TextEditingController();
  var _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    if (widget.records.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.secondary,
        body: Center(
          child: Text(
            'No past records found',
            style: TextStyle(
                color: colorScheme.surfaceContainerLowest, fontSize: 20.0),
          ),
        ),
      );
    }

    PastHabitsWidget.analyzeData(widget.records);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 28.0,
            right: 28.0,
            top: 8.0,
            bottom: 12.0,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            child: TextField(
              cursorColor: colorScheme.surface,
              controller: _controller,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.surface,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colorScheme.surfaceContainerHighest,
                    width: 2.0,
                  ),
                ),
                hintText: 'Search habits',
                hintStyle: TextStyle(
                  color: colorScheme.surface,
                ),
              ),
              style: TextStyle(color: colorScheme.surface),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onChanged: (value) {
                if (value == "") {
                  setState(() {
                    _searchQuery = value;
                  });
                }
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: PastHabitsWidget.past30DaysHabits.length,
            itemBuilder: (context, index) {
              var hr = PastHabitsWidget.past30DaysHabits[index];
              int totalDone = 0;
              int totalOccurrences = 0;
              for (var occurrence in hr.occurrences) {
                totalOccurrences++;
                if (occurrence.done) totalDone++;
              }
              double donePercentage = totalOccurrences == 0
                  ? 0
                  : (totalDone / totalOccurrences) * 100;

              return HabitCard(
                textColor: colorScheme.secondary,
                backgroundColor: colorScheme.surface,
                title: hr.name,
                comments: '$totalDone out of $totalOccurrences done',
                show: hr.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PastHabitDisplayWidget(hr: hr),
                    ),
                  );
                },
                topRightWidget: DonePercentage(
                  val: donePercentage.toStringAsFixed(0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Displays all recorded entries for a past record,
/// including any recorded comments, when they were
/// done, and the recorded time.
class PastRecordDisplayWidget extends StatefulWidget {
  final Record record;
  const PastRecordDisplayWidget({super.key, required this.record});

  @override
  State<PastRecordDisplayWidget> createState() =>
      _PastRecordDisplayWidgetState();
}

class _PastRecordDisplayWidgetState extends State<PastRecordDisplayWidget> {
  final _controller = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        centerTitle: true,
        title: Text(
          widget.record.date.toString().split(' ')[0],
          style: TextStyle(
            color: colorScheme.surface,
          ),
        ),
      ),
      backgroundColor: colorScheme.secondary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 28.0,
              right: 28.0,
              bottom: 12.0,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              child: TextField(
                cursorColor: colorScheme.surface,
                controller: _controller,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.surface,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.surfaceContainerHighest,
                      width: 2.0,
                    ),
                  ),
                  hintText: 'Search habits',
                  hintStyle: TextStyle(
                    color: colorScheme.surface,
                  ),
                ),
                style: TextStyle(color: colorScheme.surface),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.record.entries.length,
              itemBuilder: (context, index) {
                Entry entry = widget.record.entries[index];
                String name = entry.habitName;
                String comments = entry.comments;
                bool done = entry.done;

                if (entry.length != 0) {
                  name = '$name (${entry.length} min)';
                }

                if (entry.split != null) {
                  name = '$name - ${formatSplit(entry.split! * 1.0)}';
                }

                if (entry.doneAt != null) {
                  if (comments.isEmpty) {
                    comments =
                        "Completed at ${formatDateForPastRecord(entry.doneAt!)}";
                  } else {
                    comments =
                        "$comments\n\nCompleted at ${formatDateForPastRecord(entry.doneAt!)}";
                  }
                }

                return HabitCard(
                  textColor: colorScheme.secondary,
                  backgroundColor: colorScheme.surface,
                  title: name,
                  comments: comments,
                  onTap: () {},
                  show: entry.habitName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      entry.comments
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()),
                  topRightWidget: Padding(
                    padding: const EdgeInsets.only(
                      left: 10.0,
                      right: 9.5,
                    ),
                    child: Transform.scale(
                      scale: 1.95,
                      child: Checkbox(
                        shape: const CircleBorder(),
                        value: done,
                        onChanged: (b) => {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays detailed information for all occurrences
/// of a given habit.
class PastHabitDisplayWidget extends StatefulWidget {
  final HabitRetrospective hr;
  const PastHabitDisplayWidget({super.key, required this.hr});

  @override
  State<PastHabitDisplayWidget> createState() => _PastHabitDisplayWidgetState();
}

class _PastHabitDisplayWidgetState extends State<PastHabitDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    String infoString = '';
    if (widget.hr.averageSplit > 0) {
      infoString = "Average Split: ${formatSplit(widget.hr.averageSplit)}";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.secondary,
        centerTitle: true,
        title: Text(
          widget.hr.name,
          style: TextStyle(
            color: colorScheme.surface,
          ),
        ),
      ),
      backgroundColor: colorScheme.secondary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Text(
              infoString,
              style: TextStyle(fontSize: 18.0, color: colorScheme.surface),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.hr.occurrences.length,
              itemBuilder: (context, index) {
                final occurrence = widget.hr.occurrences[index];
                String dateString =
                    occurrence.dateOfOccurrence.toString().split(' ')[0];
                if (occurrence.split != null) {
                  dateString =
                      "$dateString - ${formatSplit(occurrence.split! * 1.0)}";
                }

                return HabitCard(
                  textColor: colorScheme.secondary,
                  backgroundColor: colorScheme.surface,
                  title: dateString,
                  comments: occurrence.comments,
                  onTap: () {},
                  topRightWidget: Padding(
                    padding: const EdgeInsets.only(
                      left: 10.0,
                      right: 9.5,
                    ),
                    child: Transform.scale(
                      scale: 1.95,
                      child: Checkbox(
                        shape: const CircleBorder(),
                        value: occurrence.done,
                        onChanged: (b) => {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
