import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/widgets/dialogs.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';
import 'package:flutter/material.dart';

/// Gets the list of habits from the database and launches the
/// habits list widget.
class HabitListWrapper extends StatefulWidget {
  const HabitListWrapper({super.key});

  @override
  State<HabitListWrapper> createState() => _HabitListWrapperState();
}

class _HabitListWrapperState extends State<HabitListWrapper> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Habit>>(
      future: DatabaseHelper().getHabits(
        getCurrentUserUid(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return SnapshotErrorScreen(snapshot: snapshot);
        }

        if (snapshot.data != null) {
          return HabitListWidget(
            habits: snapshot.data!,
          );
        }

        return const ErrorScreen(message: 'The data was unexpectedly null.');
      },
    );
  }
}

/// Displays the habits as a list of cards.
class HabitListWidget extends StatefulWidget {
  final List<Habit> habits;
  const HabitListWidget({super.key, required this.habits});

  @override
  State<HabitListWidget> createState() => _HabitListWidgetState();
}

class _HabitListWidgetState extends State<HabitListWidget> {
  final _controller = TextEditingController();
  var _searchQuery = "";

  Future<void> _onDelete(
      {required BuildContext context,
      required Habit habit,
      required List<Habit> habitsList}) async {
    var userInput =
        await Dialogs.showDeleteConfirmationDialog(context: context);

    if (userInput != null && userInput == true) {
      try {
        await DatabaseHelper().deleteHabit(habit);
        habitsList.removeWhere((element) => element == habit);
        setState(() {});
      } catch (e) {
        showSnackBar(context, 'Error updating habit: $e');
      }
    }
  }

  Future<void> _onEdit({
    required BuildContext context,
    required Habit habit,
  }) async {
    var userInput = await Dialogs.showEditDialog(
      context: context,
      title: 'Edit Habit Details',
      showQuadrantSelection: true,
      initialQuadrant: habit.preferredQuadrant,
      initialValue1: habit.name,
      initialValue2: habit.comments,
      initialValue3: habit.length == 0 ? '' : '${habit.length}',
    );

    if (userInput != null &&
        userInput.first != null &&
        userInput.second != null &&
        userInput.preferredQuadrant != null &&
        userInput.length != null) {
      Habit temp = habit.clone();
      temp.name = userInput.first!;
      temp.comments = userInput.second!;
      temp.preferredQuadrant = userInput.preferredQuadrant!;
      temp.length = userInput.length!;
      try {
        await DatabaseHelper().updateHabit(temp);
        habit.updateFrom(temp);
        setState(() => {});
      } catch (e) {
        showSnackBar(context, 'Error updating habit: $e');
      }
    }
  }

  Future<void> _onAdd(BuildContext context, List<Habit> habitsList) async {
    var userInput = await Dialogs.showEditDialog(
      context: context,
      title: 'Add New Habit',
      showQuadrantSelection: true,
      initialQuadrant: 0,
    );

    if (userInput != null &&
        userInput.first != null &&
        userInput.second != null &&
        userInput.preferredQuadrant != null &&
        userInput.length != null) {
      var name = userInput.first!;
      var comments = userInput.second!;
      var preferredQuadrant = userInput.preferredQuadrant!;
      var length = userInput.length!;
      try {
        Habit h = await DatabaseHelper().createHabit(
          getCurrentUserUid(),
          name: name,
          comments: comments,
          preferredQuadrant: preferredQuadrant,
          length: length,
        );
        setState(() => habitsList.add(h));
      } catch (e) {
        showSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: ChronosculptFloatingActionButton(
        onPressed: () => _onAdd(context, widget.habits),
        colorScheme: colorScheme,
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 28.0,
              right: 28.0,
              top: 4.0,
              bottom: 12.0,
            ),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search habits',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: widget.habits.isEmpty
                ? Center(
                    child: Text(
                      'No habits found',
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.secondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.habits.length,
                    itemBuilder: (context, i) {
                      final habit = widget.habits[i];
                      final title = habit.length != 0
                          ? '${habit.name} (${habit.length} min)'
                          : habit.name;

                      return HabitCard(
                        backgroundColor: colorScheme.secondary,
                        textColor: colorScheme.surface,
                        title: title,
                        comments: habit.comments,
                        onTap: () => _onEdit(context: context, habit: habit),
                        show: habit.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            habit.comments
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()),
                        topRightWidget: Transform.scale(
                          scale: 1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // fixedSize: Size(24.0, 24.0),
                              shape: const CircleBorder(),
                            ),
                            onPressed: () => _onDelete(
                                context: context,
                                habit: habit,
                                habitsList: widget.habits),
                            child: const Icon(
                              Icons.delete,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
