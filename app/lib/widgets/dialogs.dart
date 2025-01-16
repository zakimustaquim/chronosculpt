import 'dart:io';

import 'package:chronosculpt/data_structures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shared variable between QuadrantRadio and QuadrantDropdown
int selectedQuadrant = 0;

/// Static class containing various dialogs.
class Dialogs {
  /// Shows a dialog with a title and comments box
  /// and optional quadrant selection.
  static Future<({String? first, String? second, int? preferredQuadrant})?>
      showEditDialog({
    required BuildContext context,
    required bool showQuadrantSelection,
    required int initialQuadrant,
    String? title,
    String? initialValue1,
    String? initialValue2,
  }) async {
    final TextEditingController textController1 =
        TextEditingController(text: initialValue1 ?? '');
    final TextEditingController textController2 =
        TextEditingController(text: initialValue2 ?? '');

    // trying to get the Platform directly throws an error on web
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (showQuadrantSelection) selectedQuadrant = initialQuadrant;

    return showDialog<
        ({
          String? first,
          String? second,
          int? preferredQuadrant,
        })>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title ?? 'Enter Information',
                  style: TextStyle(fontSize: isMobile ? 14 : 18),
                ),
              ),
              isMobile && showQuadrantSelection
                  ? const QuadrantDropdown()
                  : const SizedBox(),
            ],
          ),
          content: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.08,
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 12),
                  controller: textController1,
                  decoration: const InputDecoration(
                    hintText: 'Type here...',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              SizedBox(height: isMobile ? 0.0 : 16.0),
              isMobile || !showQuadrantSelection
                  ? const SizedBox()
                  : const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: QuadrantRadio(),
                    ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.18,
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 12),
                  controller: textController2,
                  decoration: const InputDecoration(
                    hintText: 'Type here...',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  (
                    first: textController1.text,
                    second: textController2.text,
                    preferredQuadrant:
                        !showQuadrantSelection ? 0 : selectedQuadrant,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog prompting the user to confirm deletion.
  static Future<bool?> showDeleteConfirmationDialog(
      {required BuildContext context}) async {
    var colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.onError,
          title: const Text('Are you sure?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This action will permanently delete this habit.'),
                Text('This cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
              child: Text('Delete',
                  style: TextStyle(color: colorScheme.errorContainer)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog displaying a given message to the user.
  static Future<void> showAlertDialog(
      BuildContext context, String message) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog with one text box.
  static Future<String?> showSchedulingDialog({
    required BuildContext context,
    String? title,
    required List<Entry> entries,
    required String initialValue,
    required int? quadrant,
  }) async {
    final TextEditingController textController =
        TextEditingController(text: initialValue);

    List<Widget> habitWidgets = entries
        .map(
          (e) => Text(e.habitName),
        )
        .toList();
    Widget habitInfo = Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Wrap(
          direction: Axis.horizontal,
          spacing: 18.0,
          runSpacing: 2.0,
          children: habitWidgets,
        ),
      ),
    );

    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title ?? 'Enter Information',
            style: const TextStyle(fontSize: 18),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quadrant == -1 ? '' : 'Notes for Quadrant $quadrant',
                style: const TextStyle(fontSize: 16),
              ),
              (kIsWeb ? habitInfo : const SizedBox()),
              const SizedBox(
                height: 16.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.25,
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 12),
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Type here...',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(textController.text);
              },
            ),
          ],
        );
      },
    );
  }
}

/// A dropdown menu with 5 options for selecting
/// the preferred quadrant in showEditDialog().
/// Used in the mobile app for a more efficient UI.
class QuadrantDropdown extends StatefulWidget {
  const QuadrantDropdown({super.key});

  @override
  State<QuadrantDropdown> createState() => _QuadrantDropdownState();
}

class _QuadrantDropdownState extends State<QuadrantDropdown> {
  var dropdownItems = [
    const DropdownMenuItem<int>(
      value: 0,
      child: Text('N/A'),
    ),
    const DropdownMenuItem<int>(
      value: 1,
      child: Text('1'),
    ),
    const DropdownMenuItem<int>(
      value: 2,
      child: Text('2'),
    ),
    const DropdownMenuItem<int>(
      value: 3,
      child: Text('3'),
    ),
    const DropdownMenuItem<int>(
      value: 4,
      child: Text('4'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.65,
      child: DropdownButton<int>(
        isDense: true,
        value: selectedQuadrant,
        items: dropdownItems,
        onChanged: (value) {
          setState(() {
            selectedQuadrant = value!;
          });
        },
      ),
    );
  }
}

/// A radio group with 5 options for selecting
/// the preferred quadrant in showEditDialog().
/// Used in the web app.
class QuadrantRadio extends StatefulWidget {
  final bool isMobile;
  const QuadrantRadio({super.key, this.isMobile = false});

  @override
  State<QuadrantRadio> createState() => _QuadrantRadioState();
}

class _QuadrantRadioState extends State<QuadrantRadio> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget.isMobile ? const SizedBox() : const Text('Preferred Quadrant: '),
        const SizedBox(width: 10.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<int>(
              value: 0,
              groupValue: selectedQuadrant,
              onChanged: (value) {
                setState(() => selectedQuadrant = 0);
              },
            ),
            const Text('N/A'),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<int>(
              value: 1,
              groupValue: selectedQuadrant,
              onChanged: (value) {
                setState(() => selectedQuadrant = 1);
              },
            ),
            const Text('1'),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<int>(
              value: 2,
              groupValue: selectedQuadrant,
              onChanged: (value) {
                setState(() => selectedQuadrant = 2);
              },
            ),
            const Text('2'),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<int>(
              value: 3,
              groupValue: selectedQuadrant,
              onChanged: (value) {
                setState(() => selectedQuadrant = 3);
              },
            ),
            const Text('3'),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<int>(
              value: 4,
              groupValue: selectedQuadrant,
              onChanged: (value) {
                setState(() => selectedQuadrant = 4);
              },
            ),
            const Text('4'),
          ],
        ),
      ],
    );
  }
}
