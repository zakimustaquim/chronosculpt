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
          onTap: () {},
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
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class PastRecordDisplayWidget extends StatefulWidget {
  const PastRecordDisplayWidget({super.key});

  @override
  State<PastRecordDisplayWidget> createState() =>
      _PastRecordDisplayWidgetState();
}

class _PastRecordDisplayWidgetState extends State<PastRecordDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class PastHabitDisplayWidget extends StatefulWidget {
  const PastHabitDisplayWidget({super.key});

  @override
  State<PastHabitDisplayWidget> createState() => _PastHabitDisplayWidgetState();
}

class _PastHabitDisplayWidgetState extends State<PastHabitDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
