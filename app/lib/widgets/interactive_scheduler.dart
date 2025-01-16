import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/widgets/dialogs.dart';
import 'package:chronosculpt/widgets/live_splitter.dart';
import 'package:chronosculpt/widgets/log.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';
import 'package:chronosculpt/widgets/stopwatch.dart';
import 'package:flutter/material.dart';

/// Wrapper widget which retrieves the current record
/// from the database and launches the main interactive
/// scheduler widget.
class InteractiveSchedulerWrapper extends StatefulWidget {
  const InteractiveSchedulerWrapper({super.key});

  @override
  State<InteractiveSchedulerWrapper> createState() =>
      _InteractiveSchedulerWrapperState();
}

class _InteractiveSchedulerWrapperState
    extends State<InteractiveSchedulerWrapper> {

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
              child: FutureBuilder<List<Record>>(
            future:
                DatabaseHelper().getRecordsForCurrentDay(getCurrentUserUid()),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == null) {
                return const ErrorScreen(message: 'Unexpected null value');
              }

              if (snapshot.data!.isEmpty) {
                return NoRecordFoundWidget(refresher: () {
                  setState(() {});
                });
              }

              return InteractiveSchedulerWidget(
                r: snapshot.data![0],
                reloader: () {
                  setState(() {});
                },
              );
            },
          )),
        ],
      ),
    );
  }
}

/// Displays the entries for a given record broken up
/// into 6 containers depending on their quadrant and
/// whether they are done or not.
class InteractiveSchedulerWidget extends StatefulWidget {
  final Record r;
  final Function reloader;
  const InteractiveSchedulerWidget({
    super.key,
    required this.r,
    required this.reloader,
  });

  @override
  State<InteractiveSchedulerWidget> createState() =>
      _InteractiveSchedulerWidgetState();
}

class _InteractiveSchedulerWidgetState
    extends State<InteractiveSchedulerWidget> {
  final ScrollController _scrollController = ScrollController();

  void _stateSetter() => setState(() {});

  @override
  Widget build(BuildContext context) {
    List<List<Entry>> stratifiedList = [
      <Entry>[],
      <Entry>[],
      <Entry>[],
      <Entry>[],
      <Entry>[],
      <Entry>[],
    ];

    for (var entry in widget.r.entries) {
      if (entry.done) {
        stratifiedList[5].add(entry);
      } else {
        stratifiedList[entry.quadrant].add(entry);
      }
    }

    double donePercentage = stratifiedList[5].length /
        (stratifiedList[0].length +
            stratifiedList[1].length +
            stratifiedList[2].length +
            stratifiedList[3].length +
            stratifiedList[4].length +
            stratifiedList[5].length);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: QuadrantContainer(
                  entries: stratifiedList[0],
                  quadrant: 0,
                  scrollController: _scrollController,
                  record: widget.r,
                  refresher: () => _stateSetter(),
                  reloader: () => widget.reloader(),
                ),
              ),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: QuadrantContainer(
                    entries: stratifiedList[1],
                    quadrant: 1,
                    scrollController: _scrollController,
                    record: widget.r,
                    refresher: () => _stateSetter(),
                    reloader: () => widget.reloader(),
                  ),
                ),
                Expanded(
                  child: QuadrantContainer(
                    entries: stratifiedList[2],
                    quadrant: 2,
                    scrollController: _scrollController,
                    record: widget.r,
                    refresher: () => _stateSetter(),
                    reloader: () => widget.reloader(),
                  ),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: QuadrantContainer(
                    entries: stratifiedList[3],
                    quadrant: 3,
                    scrollController: _scrollController,
                    record: widget.r,
                    refresher: () => _stateSetter(),
                    reloader: () => widget.reloader(),
                  ),
                ),
                Expanded(
                  child: QuadrantContainer(
                    entries: stratifiedList[4],
                    quadrant: 4,
                    scrollController: _scrollController,
                    record: widget.r,
                    refresher: () => _stateSetter(),
                    reloader: () => widget.reloader(),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: QuadrantContainer(
                  entries: stratifiedList[5],
                  quadrant: 5,
                  scrollController: _scrollController,
                  donePercentage: donePercentage,
                  record: widget.r,
                  refresher: () => _stateSetter(),
                  reloader: () => widget.reloader(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Displays all of a given list of entries as well as
/// facilitating notes retrieval and updating.
class QuadrantContainer extends StatefulWidget {
  final List<Entry> entries;
  final int quadrant;
  final ScrollController scrollController;
  final double donePercentage;
  final Record record;
  final Function refresher;
  final Function reloader;

  const QuadrantContainer({
    super.key,
    required this.entries,
    required this.quadrant,
    required this.scrollController,
    required this.record,
    required this.refresher,
    required this.reloader,
    this.donePercentage = 0,
  });

  @override
  State<QuadrantContainer> createState() => _QuadrantContainerState();
}

class _QuadrantContainerState extends State<QuadrantContainer> {
  double _scale = 1;

  Future<void> _onUpdateQuadrantNotes(BuildContext context) async {
    if (widget.quadrant < 1 || widget.quadrant > 4) return;

    String initialNotes = "";
    switch (widget.quadrant) {
      case 1:
        initialNotes = widget.record.q1notes;
        break;
      case 2:
        initialNotes = widget.record.q2notes;
        break;
      case 3:
        initialNotes = widget.record.q3notes;
        break;
      case 4:
        initialNotes = widget.record.q4notes;
        break;
    }

    String? newComments = await Dialogs.showSchedulingDialog(
      context: context,
      initialValue: initialNotes,
      quadrant: widget.quadrant,
      entries: widget.entries,
    );
    try {
      if (newComments != null) {
        switch (widget.quadrant) {
          case 1:
            widget.record.q1notes = newComments;
            break;
          case 2:
            widget.record.q2notes = newComments;
            break;
          case 3:
            widget.record.q3notes = newComments;
            break;
          case 4:
            widget.record.q4notes = newComments;
            break;
        }
        try {
          await DatabaseHelper().updateRecord(widget.record);
          widget.refresher();
        } catch (e) {
          showSnackBar(context, 'Error updating notes: $e');
        }
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    List<Widget> widgetList = widget.entries.map((entry) {
      return InkWell(
        enableFeedback: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          var temp = entry.clone();
          temp.done = widget.quadrant < 5 ? true : false;
          temp.doneAt = widget.quadrant < 5 ? DateTime.now() : null;
          try {
            await DatabaseHelper().updateEntry(temp);
            entry.updateFrom(temp);
            widget.refresher();
          } catch (e) {
            showSnackBar(context, 'Error updating entry: $e');
          }
        },
        onLongPress: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StopwatchWidget(entry: entry),
              )).then((_) {
            widget.refresher();
          });
        },
        child: Draggable<Entry>(
          onDragUpdate: (details) {
            const double scrollThreshold = 75.0;
            if (details.globalPosition.dy < scrollThreshold) {
              // Scroll up
              widget.scrollController.jumpTo(
                widget.scrollController.offset - 9.0,
              );
            } else if (details.globalPosition.dy >
                MediaQuery.of(context).size.height - scrollThreshold) {
              // Scroll down
              widget.scrollController.jumpTo(
                widget.scrollController.offset + 9.0,
              );
            }
          },
          data: entry,
          feedback:
              InteractiveSchedulerBrick(text: entry.habitName, blank: false),
          childWhenDragging:
              InteractiveSchedulerBrick(text: entry.habitName, blank: true),
          child: InteractiveSchedulerBrick(text: entry.habitName, blank: false),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(
        top: 4.0,
        left: 10.0,
        right: 10.0,
        bottom: 12.0,
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        onTap: () => _onUpdateQuadrantNotes(context),
        onLongPress: widget.quadrant == 5 || widget.entries.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveSplitter(
                      entries: widget.entries,
                    ),
                  ),
                ).then((_) {
                  widget.reloader();
                });
              },
        onHighlightChanged: (h) => setState(() {
          _scale = h ? 0.92 : 1;
        }),
        child: DragTarget<Entry>(
          builder: (BuildContext context, List<dynamic> accepted,
              List<dynamic> rejected) {
            return AnimatedContainer(
              transform: Matrix4.identity()..scale(_scale),
              transformAlignment: FractionalOffset.center,
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(30),
              ),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 16.0),
                    child: Text(
                      widget.quadrant == 5
                          ? '${(widget.donePercentage * 100).toStringAsFixed(0)}% done'
                          : '${_getQuadrantLabel(widget.quadrant)}\n${getTimesink(
                              widget.entries,
                            )} min remaining',
                      style: TextStyle(
                          color: colorScheme.surface,
                          fontSize: 10.0,
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10.0,
                      left: 10.0,
                      right: 10.0,
                      top: 6.0,
                    ),
                    child: Wrap(
                      direction: Axis.horizontal,
                      spacing: 8.0,
                      runSpacing: 2.0,
                      children: widgetList,
                    ),
                  ),
                ],
              ),
            );
          },
          onAcceptWithDetails: (details) async {
            Entry entry = details.data;
            Entry temp = entry.clone();
            if (widget.quadrant != 5) {
              temp.done = false;
              temp.doneAt = null;
              temp.quadrant = widget.quadrant;
            } else {
              temp.done = true;
              temp.doneAt = DateTime.now();
            }
            try {
              await DatabaseHelper().updateEntry(temp);
              entry.updateFrom(temp);
              widget.refresher();
            } catch (e) {
              showSnackBar(context, 'Error updating entry: $e');
            }
          },
        ),
      ),
    );
  }

  String _getQuadrantLabel(int i) {
    switch (i) {
      case 1:
        return "Morning";
      case 2:
        return "Afternoon";
      case 3:
        return "Evening";
      case 4:
        return "Night";
      default:
        return "Unplanned";
    }
  }
}

/// Minor class used by QuadrantContainer to display an
/// individual entry.
class InteractiveSchedulerBrick extends StatelessWidget {
  final String text;
  final bool blank;

  const InteractiveSchedulerBrick({
    super.key,
    required this.text,
    required this.blank,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          color: blank ? colorScheme.secondary : colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            style: TextStyle(
              letterSpacing: 1.75,
              color: colorScheme.secondary,
              fontSize: 8.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
