import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorScreen extends StatelessWidget {
  final AsyncSnapshot snapshot;
  const ErrorScreen({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Text(
        "Error loading records: ${snapshot.error}",
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class HabitCard extends StatefulWidget {
  final Color textColor;
  final Color backgroundColor;
  final String title;
  final String comments;
  final Function onTap;
  final VoidCallback? onLongPress;
  final Widget topRightWidget;
  final bool show;

  const HabitCard({
    super.key,
    required this.textColor,
    required this.backgroundColor,
    required this.title,
    required this.comments,
    required this.onTap,
    this.onLongPress,
    required this.topRightWidget,
    this.show = true,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        enableFeedback: true,
        onHighlightChanged: (hovering) => setState(
          () => scale = hovering ? 0.92 : 1,
        ),
        onTap: () => widget.onTap(),
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: FractionalOffset.center,
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.only(
            left: 36.0,
            right: 36.0,
            top: 34.0,
            bottom: 34.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        letterSpacing: 1.75,
                        color: widget.textColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: widget.topRightWidget,
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.comments,
                      style: TextStyle(
                        letterSpacing: 1.25,
                        color: widget.textColor,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChronosculptFloatingActionButton extends FloatingActionButton {
  ChronosculptFloatingActionButton({
    super.key,
    required super.onPressed,
    required ColorScheme colorScheme,
    required Icon icon,
  }) : super(
          backgroundColor: colorScheme.shadow,
          foregroundColor: colorScheme.tertiaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(120.0),
          ),
          child: const Icon(
            Icons.add,
            size: 32,
          ),
        );
}

class HabitCardOld extends StatefulWidget {
  final Color textColor;
  final Color backgroundColor;
  final String name;
  final String comments;
  final bool additive;
  final bool? currentStatus;
  final VoidCallback
      onEdit; // callback for editing - the way we want to set this up is in the larger class have this call another method with its docid (ex. onEdit: edit(docId))
  final VoidCallback?
      onDelete; // if this is null, it is a quest habit, if it is not null, it is a journey habit
  final Function? onComplete;
  final VoidCallback? onLongPress;
  final int? donePercentage;
  final bool show; // whether to show the card or not

  // uses all of habit card's instance variables for now
  const HabitCardOld({
    super.key,
    required this.textColor,
    required this.backgroundColor,
    required this.name,
    required this.comments,
    this.additive = true,
    required this.onEdit,
    this.currentStatus,
    this.onDelete,
    this.onComplete,
    this.donePercentage,
    this.show = true,
    this.onLongPress,
  });

  @override
  State<HabitCardOld> createState() => _HabitCardOldState();
}

class _HabitCardOldState extends State<HabitCardOld> {
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        enableFeedback: true,
        onHighlightChanged: (h) => setState(() {
          scale = h ? 0.92 : 1;
        }),
        onTap: widget.onEdit,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: FractionalOffset.center,
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.only(
            left: 36.0,
            right: 36.0,
            top: 34.0,
            bottom: 34.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        letterSpacing: 1.75,
                        color: widget.textColor,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    // if onDelete is null, it is assumed to be a Quest card, and if
                    // if it is defined, it is assumed to be a Journey card.
                    // this means that, for a Journey card, currentStatus and onCheck
                    // are assumed to be defined
                    child: widget.onDelete != null
                        ? Transform.scale(
                            scale: 1,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                // fixedSize: Size(24.0, 24.0),
                                shape: const CircleBorder(),
                              ),
                              onPressed: widget.onDelete,
                              child: const Icon(
                                Icons.delete,
                                size: 24,
                              ),
                            ),
                          )
                        : (widget.donePercentage != null)
                            ? Text(
                                widget.donePercentage == -1
                                    ? ''
                                    : '${widget.donePercentage}%',
                                style: TextStyle(
                                    fontSize: 24,
                                    color: widget.textColor,
                                    fontWeight: FontWeight.bold),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                  left: 10.0,
                                  right: 9.5,
                                ),
                                child: Transform.scale(
                                  scale: 1.95,
                                  child: Checkbox(
                                    shape: const CircleBorder(),
                                    value: widget.currentStatus,
                                    onChanged: (b) => widget.onComplete!(b),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.comments,
                      style: TextStyle(
                        letterSpacing: 1.25,
                        color: widget.textColor,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
