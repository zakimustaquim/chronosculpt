import 'package:chronosculpt/widgets/dialogs.dart';
import 'package:chronosculpt/widgets/stopwatch.dart';
import 'package:flutter/material.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';

class LogWidget extends StatefulWidget {
  const LogWidget({super.key});

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Record>>(
      future: DatabaseHelper().getRecordsForCurrentDay(
        getCurrentUserUid(),
      ),
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

        if (snapshot.data!.isNotEmpty) {
          return CurrentDayWidget(
            recordsList: snapshot.data!,
          );
        } else {
          return NoRecordFoundWidget(
            refresher: () => setState(() {}),
          );
        }
      },
    );
  }
}

class NoRecordFoundWidget extends StatelessWidget {
  final Function refresher;
  const NoRecordFoundWidget({super.key, required this.refresher});

  Future<void> onAddRecord(BuildContext context) async {
    try {
      await DatabaseHelper().createRecordForCurrentDay(getCurrentUserUid());
      refresher();
    } on DatabaseTransactionException catch (dte) {
      if (dte.errorCode == 406) {
          Dialogs.showAlertDialog(context,
              'Please add at least one habit before creating a daily record.');
      } else {
        showSnackBar(context, dte.toString());
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'No record found for today',
              style: TextStyle(
                  color: colorScheme.surfaceContainerLowest, fontSize: 20.0),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              child: const Text('Recheck'),
              onPressed: () => refresher(),
            )
          ],
        ),
      ),
      floatingActionButton: ChronosculptFloatingActionButton(
        onPressed: () => onAddRecord(context),
        colorScheme: colorScheme,
        icon: Icon(Icons.add),
      ),
    );
  }
}

class CurrentDayWidget extends StatefulWidget {
  final List<Record> recordsList;
  const CurrentDayWidget({super.key, required this.recordsList});

  @override
  State<CurrentDayWidget> createState() => _CurrentDayWidgetState();
}

class _CurrentDayWidgetState extends State<CurrentDayWidget> {
  String searchQuery = "";
  var controller = TextEditingController();

  Future<void> onEdit({
    required BuildContext context,
    required Entry entry,
  }) async {
    var userInput = await Dialogs.showEditDialog(
      context: context,
      title: 'Edit Habit Details',
      showQuadrantSelection: false,
      initialQuadrant: 0,
      initialValue1: entry.habitName,
      initialValue2: entry.comments,
    );

    if (userInput != null &&
        userInput.first != null &&
        userInput.second != null) {
      entry.habitName = userInput.first!;
      entry.comments = userInput.second!;
      await DatabaseHelper().updateEntry(entry);
      setState(() => {});
    }
  }

  Future<void> onComplete(Entry e, bool? newStatus) async {
    if (newStatus == null) return;
    e.done = newStatus;
    e.doneAt = newStatus == true ? DateTime.now() : null;
    await DatabaseHelper().updateEntry(e);
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    List<Entry> entries = widget.recordsList[0].entries;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 28.0,
              right: 28.0,
              top: 30.0,
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
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                return HabitCard(
                  backgroundColor: colorScheme.surface,
                  textColor: colorScheme.secondary,
                  title: entry.habitName,
                  comments: entry.comments,
                  onTap: () => onEdit(context: context, entry: entry),
                  onLongPress: () => launchStopwatchWidget(),
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
                        value: entry.done,
                        onChanged: (b) => onComplete(entry, b),
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
