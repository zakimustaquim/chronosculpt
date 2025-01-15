import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class SnapshotErrorScreen extends StatelessWidget {
  final AsyncSnapshot snapshot;
  const SnapshotErrorScreen({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Text(
        "Error loading data: ${snapshot.error}",
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Text(
        "Error loading data: $message",
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
