import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';
import 'package:chronosculpt/data_structures.dart';
import 'package:flutter/material.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  final _selectedView = <bool>[true, false];
  int view = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    List<Widget> tabs = [];
    for (int i = 0; i < _selectedView.length; i++) {
      if (_selectedView[i]) view = i;
    }

    return FutureBuilder<List<Record>>(
      future: DatabaseHelper().getPast30Days(getCurrentUserUid()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return SnapshotErrorScreen(snapshot: snapshot);
        }

        if (snapshot.data == null) {
          return ErrorScreen(message: 'The data was unexpectedly null.');
        }

        if (tabs.isEmpty) {
          tabs = [
            PastRecordsWidget(records: snapshot.data!),
            PastHabitsWidget(records: snapshot.data!)
          ];
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30.0, bottom: 8.0),
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
                  index: view,
                  children: tabs,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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

class PastHabitsWidget extends StatefulWidget {
  static List<HabitRetrospective> past30DaysHabits = [];
  final List<Record> records;
  const PastHabitsWidget({super.key, required this.records});

  @override
  State<PastHabitsWidget> createState() => _PastHabitsWidgetState();
}

class _PastHabitsWidgetState extends State<PastHabitsWidget> {
  var controller = TextEditingController();
  var searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    // calculate habit statistics
    Map<String, HabitRetrospective> map = {};
    for (var record in widget.records) {
      for (var entry in record.entries) {
        String cleanedName = cleanName(entry.habitName);
        entry.dateOfOccurrence = record.date;
        if (map.containsKey(cleanedName)) {
          map[cleanedName]!.occurrences.add(entry);
        } else {
          HabitRetrospective hr =
              HabitRetrospective(name: cleanedName, occurrences: [entry]);
          map[cleanedName] = hr;
        }
      }
    }

    PastHabitsWidget.past30DaysHabits =
        map.entries.toList().map((e) => e.value).toList();

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
              controller: controller,
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
                  searchQuery = value;
                });
              },
              onChanged: (value) {
                if (value == "") {
                  setState(() {
                    searchQuery = value;
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

class PastRecordDisplayWidget extends StatefulWidget {
  final Record record;
  const PastRecordDisplayWidget({super.key, required this.record});

  @override
  State<PastRecordDisplayWidget> createState() =>
      _PastRecordDisplayWidgetState();
}

class _PastRecordDisplayWidgetState extends State<PastRecordDisplayWidget> {
  var controller = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 28.0, left: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back_ios_new_outlined),
                ),
              ),
            ],
          ),
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
                controller: controller,
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
                    searchQuery = value;
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
                          .contains(searchQuery.toLowerCase()) ||
                      entry.comments
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()),
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
    String infoString = widget.hr.name;
    if (widget.hr.averageSplit > 0) {
      infoString =
          "$infoString\nAverage Split: ${formatSplit(widget.hr.averageSplit)}";
    }

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 28.0, left: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back_ios_new_outlined),
                ),
              ),
            ],
          ),
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
