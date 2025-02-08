import 'dart:async';
import 'dart:io';

import 'package:chronosculpt/config.dart';
import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/widgets/history.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Displays a list of entries as a reorderable list
/// of tiles, enabling the user to create a sequence
/// of habits to perform in immediate succession.
class LiveSplitter extends StatefulWidget {
  final List<Entry> entries;
  const LiveSplitter({super.key, required this.entries});

  @override
  State<LiveSplitter> createState() => _LiveSplitterState();
}

class _LiveSplitterState extends State<LiveSplitter> {
  late List<LiveSplitUnit> _units;
  bool _enableButton = true;
  late Timer _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Duration _lastSavedDuration = Duration.zero;
  bool _isRunning = false;

  String _toggleText = "Start";

  @override
  void initState() {
    super.initState();

    _units = widget.entries
        .map(
          (element) => LiveSplitUnit(
            entry: element,
            averageSplit: getAverageSplit(
              element.hid,
              PastHabitsWidget.past30DaysHabits,
            ),
            minSplit: getMinSplit(
              element.hid,
              PastHabitsWidget.past30DaysHabits,
            ),
          ),
        )
        .toList();
  }

  LiveSplitUnit _getCurrentUnit() {
    // look for a unit in progress
    for (var unit in _units) {
      if (unit.status == LiveSplitStatus.inProgress) return unit;
    }

    // if none in progress, just find the first one that is waiting
    for (var unit in _units) {
      if (unit.status == LiveSplitStatus.waiting) return unit;
    }

    return _units[_units.length - 1];
  }

  void _start() {
    if (!_isRunning) {
      _toggleText = "Stop";
      _startTime ??= DateTime.now().subtract(_elapsed);

      LiveSplitUnit u = _getCurrentUnit();
      u.status = LiveSplitStatus.inProgress;
      u.startTime ??= DateTime.now().subtract(u.elapsed);

      _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
          u.elapsed = DateTime.now().difference(u.startTime!);
        });
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _stop() {
    if (_isRunning) {
      _toggleText = "Start";
      _timer.cancel();
      _startTime = null;
      _getCurrentUnit().startTime = null;
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _toggle() {
    if (_isRunning) {
      _stop();
    } else {
      _start();
    }
  }

  Future<void> _next(BuildContext context) async {
    if (!_isRunning) return;

    // Stop timer
    var unit = _getCurrentUnit();
    var tempStartTime = _startTime;
    _elapsed = DateTime.now().difference(tempStartTime!);
    tempStartTime = unit.startTime;
    unit.elapsed = DateTime.now().difference(unit.startTime!);
    _lastSavedDuration = _elapsed;
    _stop();

    // Save split on unit
    setState(() {
      _enableButton = false;
      unit.status = LiveSplitStatus.uploading;
    });
    try {
      unit.entry.split = unit.elapsed.inMilliseconds;
      unit.entry.done = true;
      unit.entry.doneAt = DateTime.now();
      await DatabaseHelper().updateEntry(unit.entry);
      unit.status = LiveSplitStatus.uploadSuccess;
    } catch (e) {
      unit.status = LiveSplitStatus.uploadFailure;
      showSnackBar(
          context, 'Error updating entry. Tap the X icon to retry. $e');
    } finally {
      setState(() {
        _enableButton = true;
      });
      if (_allUnitsCompleted()) {
        if (_noFailures() && context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _start();
      }
    }
  }

  bool _allUnitsCompleted() {
    for (var unit in _units) {
      if (unit.status == LiveSplitStatus.waiting ||
          unit.status == LiveSplitStatus.inProgress) {
        return false;
      }
    }
    return true;
  }

  bool _noFailures() {
    for (var unit in _units) {
      if (unit.status == LiveSplitStatus.uploadFailure) return false;
    }
    return true;
  }

  void _shuffle() {
    if (_isRunning) return;

    // get uncompleted ones
    var waitingList = _units
        .where((element) => element.status == LiveSplitStatus.waiting)
        .toList();
    waitingList.shuffle();

    int j = 0;
    for (int i = _getFirstWaiting(); i < _units.length && i >= 0; i++) {
      _units[i] = waitingList[j];
      j++;
    }
    setState(() {});
  }

  int _getFirstWaiting() {
    for (int i = 0; i < _units.length; i++) {
      if (_units[i].status == LiveSplitStatus.waiting) {
        return i;
      }
    }
    return -1;
  }

  void _reset() {
    _stop();
    setState(() {
      _elapsed = _lastSavedDuration;
      _startTime = null;
      var u = _getCurrentUnit();
      u.elapsed = Duration.zero;
      u.startTime = null;
      u.status = LiveSplitStatus.waiting;
    });
  }

  void _delete(int i, BuildContext context) {
    if (_isRunning) return;

    if (_units[i].status == LiveSplitStatus.inProgress) {
      _elapsed = _lastSavedDuration;
    }

    _units.removeAt(i);
    if (_units.isEmpty || _allUnitsCompleted()) {
      Navigator.of(context).pop();
    }
    setState(() {});
  }

  void _reorder(int oldIndex, int newIndex) {
    try {
      if (_units[oldIndex].status != LiveSplitStatus.waiting ||
          _units[newIndex].status != LiveSplitStatus.waiting) {
        showSnackBar(context, "Can only reorder waiting habits.");
        return;
      }
    } catch (e) {
      // Nothing
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    var temp = _units.removeAt(oldIndex);
    _units.insert(newIndex, temp);
    setState(() {});
  }

  Future<void> _retryUpload(LiveSplitUnit lsu, BuildContext context) async {
    try {
      await DatabaseHelper().updateEntry(lsu.entry);
      setState(() {
        lsu.status = LiveSplitStatus.uploadSuccess;
      });
    } catch (e) {
      showSnackBar(
          context, 'Error updating entry. Tap the X icon to retry. $e');
    }
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textStyle = TextStyle(color: colorScheme.surface);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'LiveSplitter',
          style: TextStyle(color: colorScheme.secondary),
        ),
        backgroundColor: colorScheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: "Shuffle",
              child: ElevatedButton(
                onPressed: _isRunning ? null : () => _shuffle(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary),
                child: Icon(Icons.shuffle, color: colorScheme.surface),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SizedBox(height: 32.0),
            Expanded(
              child: ReorderableListView.builder(
                itemBuilder: (context, index) {
                  final isMobile =
                      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
                  var unit = _units[index];

                  if (isMobile) {
                    return ReorderableDelayedDragStartListener(
                      key: Key('${unit.entry.eid}'),
                      index: index,
                      child: IgnorePointer(
                        ignoring: _isRunning ||
                            (unit.status == LiveSplitStatus.uploading ||
                                unit.status == LiveSplitStatus.uploadSuccess),
                        child: LiveSplitTile(
                          unit: unit,
                          deleter: () => _delete(index, context),
                          retrier: () => _retryUpload(unit, context),
                        ),
                      ),
                    );
                  } else {
                    return ReorderableDragStartListener(
                      key: Key('$index'),
                      index: index,
                      child: IgnorePointer(
                        ignoring: _isRunning ||
                            (unit.status == LiveSplitStatus.uploading ||
                                unit.status == LiveSplitStatus.uploadSuccess),
                        child: LiveSplitTile(
                          unit: unit,
                          deleter: () => _delete(index, context),
                          retrier: () => _retryUpload(unit, context),
                        ),
                      ),
                    );
                  }
                },
                buildDefaultDragHandles: false,
                itemCount: _units.length,
                onReorder: _reorder,
              ),
            ),
            Text(
              formatSplit(_elapsed.inMilliseconds * 1.0),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary),
                  child: Text(_toggleText, style: textStyle),
                ),
                const SizedBox(width: 10),
                _enableButton
                    ? ElevatedButton(
                        onPressed: null,
                        onLongPress: _isRunning ? () => _next(context) : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary),
                        child: Text(
                          'Next',
                          style: textStyle,
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {},
              onLongPress: _reset,
              style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary),
              child: Text(
                'Reset Current',
                style: textStyle,
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

/// An individual tile used by the Live Splitter class.
class LiveSplitTile extends StatefulWidget {
  final LiveSplitUnit unit;
  final Function deleter;
  final Function retrier;
  const LiveSplitTile({
    super.key,
    required this.unit,
    required this.deleter,
    required this.retrier,
  });

  @override
  State<LiveSplitTile> createState() => _LiveSplitTileState();
}

class _LiveSplitTileState extends State<LiveSplitTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Color background =
        _hovering ? colorScheme.surfaceContainerHigh : colorScheme.surface;

    final textStyle = TextStyle(
      color: colorScheme.secondary,
      fontSize: 16.0,
    );
    final labelStyle = TextStyle(
      color: colorScheme.secondary,
      fontSize: 11.0,
    );

    String averageSplitText = widget.unit.averageSplit == 0
        ? ''
        : formatSplit(widget.unit.averageSplit);
    String minSplitText = widget.unit.minSplit == 0
        ? ''
        : formatSplit(widget.unit.minSplit * 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Tooltip(
        message: isMobile ? "" : widget.unit.entry.comments,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onHover: (value) {
            setState(() => _hovering = value);
          },
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0.3,
                  blurRadius: 0.3,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(widget.unit.name, style: textStyle),
                  ),
                  const SizedBox(width: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      averageSplitText.isEmpty
                          ? const SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(averageSplitText, style: textStyle),
                                Text('AS', style: labelStyle),
                              ],
                            ),
                      const SizedBox(width: 12.0),
                      minSplitText.isEmpty
                          ? const SizedBox()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(minSplitText, style: textStyle),
                                Text('PB', style: labelStyle),
                              ],
                            ),
                      const SizedBox(width: 8.0),
                      _getStatusWidget(colorScheme),
                      const SizedBox(width: 4.0),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 32.0),
                        child: InkWell(
                          onLongPress: () => widget.deleter(),
                          child:
                              Icon(Icons.delete, color: colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getStatusWidget(ColorScheme scheme) {
    switch (widget.unit.status) {
      case LiveSplitStatus.waiting:
        return Icon(Icons.more_horiz, color: scheme.secondary);
      case LiveSplitStatus.inProgress:
        return Text(
          formatSplit(widget.unit.elapsed.inMilliseconds * 1.0),
          style: TextStyle(
            color: scheme.secondary,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        );
      case LiveSplitStatus.uploading:
        return Transform.scale(
          scale: 0.5,
          child: CircularProgressIndicator(color: scheme.secondary),
        );
      case LiveSplitStatus.uploadSuccess:
        return Icon(Icons.check, color: scheme.secondary);
      case LiveSplitStatus.uploadFailure:
        return InkWell(
          onTap: () => widget.retrier(),
          child: Icon(Icons.close, color: scheme.error),
        );
    }
  }
}
