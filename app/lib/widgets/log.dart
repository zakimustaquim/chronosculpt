import 'package:chronosculpt/widgets/dialogs.dart';
import 'package:chronosculpt/widgets/stopwatch.dart';
import 'package:flutter/material.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';

/// Wrapper widget that retrieves the current record
/// from the database and passes it to the main log widget.
class LogWidgetWrapper extends StatefulWidget {
  const LogWidgetWrapper({super.key});

  @override
  State<LogWidgetWrapper> createState() => _LogWidgetWrapperState();
}

class _LogWidgetWrapperState extends State<LogWidgetWrapper> {
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
          return const ErrorScreen(message: 'The data was unexpectedly null.');
        }

        if (snapshot.data!.isNotEmpty) {
          return LogWidget(
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

/// Runs when the user has not created a record for the
/// current day. 
class NoRecordFoundWidget extends StatelessWidget {
  final Function refresher;
  const NoRecordFoundWidget({super.key, required this.refresher});

  Future<void> _onAddRecord(BuildContext context) async {
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
        onPressed: () => _onAddRecord(context),
        colorScheme: colorScheme,
        icon: const Icon(Icons.add),
      ),
    );
  }
}

/// Displays all entries for the current day as cards.
class LogWidget extends StatefulWidget {
  final List<Record> recordsList;
  const LogWidget({super.key, required this.recordsList});

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  String _searchQuery = "";
  final _controller = TextEditingController();

  Future<void> _onEdit({
    required BuildContext context,
    required Entry entry,
  }) async {
    var userInput = await Dialogs.showSchedulingDialog(
      context: context,
      title: 'Edit Habit Details',
      entries: [],
      initialValue: entry.comments,
      quadrant: -1,
    );

    if (userInput != null) {
      var temp = entry.clone();
      temp.comments = userInput;
      try {
        await DatabaseHelper().updateEntry(temp);
        entry.updateFrom(temp);
        setState(() => {});
      } catch (e) {
        showSnackBar(context, 'Error updating entry: $e');
      }
    }
  }

  Future<void> _onComplete(Entry e, bool? newStatus) async {
    if (newStatus == null) return;
    var temp = e.clone();
    temp.done = newStatus;
    temp.doneAt = newStatus == true ? DateTime.now() : null;
    try {
      await DatabaseHelper().updateEntry(temp);
      e.updateFrom(temp);
      setState(() => {});
    } catch (e) {
      showSnackBar(context, 'Error updating entry: $e');
    }
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
              top: 4.0,
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
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                return HabitCard(
                  backgroundColor: colorScheme.surface,
                  textColor: colorScheme.secondary,
                  title: entry.habitName,
                  comments: entry.comments,
                  onTap: () => _onEdit(context: context, entry: entry),
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StopwatchWidget(entry: entry),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
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
                        value: entry.done,
                        onChanged: (b) => _onComplete(entry, b),
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
