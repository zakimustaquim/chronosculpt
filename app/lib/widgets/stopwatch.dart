import 'dart:async';

import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/widgets/history.dart';
import 'package:flutter/material.dart';

class StopwatchWidget extends StatefulWidget {
  final Entry entry;
  const StopwatchWidget({
    super.key,
    required this.entry,
  });

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  late Timer _timer;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _enableButton = true;
  bool _showCustomDurationField = false;
  String toggleText = "Start";
  var minutesController = TextEditingController();
  var secondsController = TextEditingController();

  void _start() {
    if (!_isRunning) {
      toggleText = "Stop";
      _startTime ??= DateTime.now().subtract(_elapsed);
      _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        setState(() {
          // _elapsed += Duration(milliseconds: 100);
          _elapsed = DateTime.now().difference(_startTime!);
        });
      });
      setState(() {
        _isRunning = true;
      });
    }
  }

  void _stop() {
    if (_isRunning) {
      toggleText = "Start";
      _timer.cancel();
      _startTime = null;
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

  void _reset() {
    _stop();
    setState(() {
      _elapsed = Duration.zero;
      _startTime = null;
    });
  }

  @override
  void dispose() {
    if (_isRunning) {
      _timer.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    return formatSplit(duration.inMilliseconds * 1.0);
    /*
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds"; */
  }

  Future<void> saveDuration({
    required BuildContext context,
  }) async {
    setState(() {
      _enableButton = false;
    });
    var tempStartTime = _startTime;
    _stop();
    _elapsed = DateTime.now().difference(tempStartTime!);

    int? newSplit;
    if (_showCustomDurationField) {
      try {
        int minutes = int.parse(minutesController.text);
        int seconds = int.parse(secondsController.text);
        Duration duration = Duration(minutes: minutes, seconds: seconds);
        newSplit = duration.inMilliseconds;
      } catch (e) {
        showSnackBar(context, e.toString());
        setState(() {
          _enableButton = true;
        });
        return;
      }
    } else {
      newSplit = _elapsed.inMilliseconds;
    }

    widget.entry.split = newSplit;
    await DatabaseHelper().updateEntry(widget.entry);
    if (context.mounted) Navigator.of(context).pop();
  }

  Widget getTextField(
      TextEditingController controller, ColorScheme colorScheme, String hint) {
    return Theme(
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
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.surface,
          ),
        ),
        style: TextStyle(color: colorScheme.surface),
      ),
    );
  }

  String getMinSplit() {
    for (var hr in PastHabitsWidget.past30DaysHabits) {
      if (hr.name == widget.entry.habitName) {
        int minSplit = hr.minSplit;
        if (minSplit == 9007199254740) {
          return "N/A";
        } else {
          return formatSplit(hr.minSplit * 1.0);
        }
      }
    }
    return "Unable to retrieve";
  }

  String getAverageSplit() {
    for (var hr in PastHabitsWidget.past30DaysHabits) {
      if (hr.name == widget.entry.habitName) {
        double averageSplit = hr.averageSplit;
        if (averageSplit == 0) {
          return "N/A";
        } else {
          return formatSplit(hr.averageSplit * 1.0);
        }
      }
    }
    return "Unable to retrieve";
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textStyle = TextStyle(color: colorScheme.secondary);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            widget.entry.habitName,
            style: TextStyle(
              color: colorScheme.surface,
            ),
          ),
        ),
        backgroundColor: colorScheme.secondary,
      ),
      backgroundColor: colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'AS: ${getAverageSplit()}',
              style: TextStyle(
                color: colorScheme.surface,
                fontSize: 20.0,
              ),
            ),
            Text(
              'PB: ${getMinSplit()}',
              style: TextStyle(
                color: colorScheme.surface,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              _formatDuration(_elapsed),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggle,
                  child: Text(toggleText, style: textStyle),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  onLongPress: _reset,
                  child: Text(
                    'Reset',
                    style: textStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            _enableButton
                ? ElevatedButton(
                    onPressed: () {},
                    onLongPress: () => saveDuration(context: context),
                    child: Text(
                      'Save',
                      style: textStyle,
                    ),
                  )
                : const SizedBox(),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: () {
                setState(
                  () {
                    _showCustomDurationField = !_showCustomDurationField;
                  },
                );
              },
              child: Text(_showCustomDurationField
                  ? 'Hide custom duration'
                  : 'Show custom duration'),
            ),
            _showCustomDurationField
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40.0,
                          width: 80.0,
                          child: getTextField(
                              minutesController, colorScheme, "MM"),
                        ),
                        const SizedBox(width: 16.0),
                        SizedBox(
                          height: 40.0,
                          width: 80.0,
                          child: getTextField(
                              secondsController, colorScheme, "SS"),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
