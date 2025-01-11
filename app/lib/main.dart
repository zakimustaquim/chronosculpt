import 'package:chronosculpt/widgets/habit_list.dart';
import 'package:chronosculpt/widgets/history.dart';
import 'package:chronosculpt/widgets/log.dart';
import 'package:flutter/material.dart';

// global variables
bool authenticated = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  attemptSignIn();
  runApp(const ChronosculptApp());
}

void attemptSignIn() {
  // will do when authentication implemented
  // retrieve saved login and attempt to sign in
}

String getCurrentUserUid() {
  return 'a23';
}

void showSnackBar(BuildContext context, String s) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}

class ChronosculptApp extends StatelessWidget {
  const ChronosculptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronosculpt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 174, 85, 196),
        ),
        useMaterial3: true,
      ),
      home: const MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  static BuildContext? applicationContext;
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const LogWidget();
        break;
      case 1:
        page = const Placeholder();
        break;
      case 2:
        page = const HabitListWrapper();
        break;
      case 3:
        page = const HistoryWidget();
        break;
      default:
        page = const Placeholder();
        break;
    }

    applicationContext ??= context;
    return Scaffold(
        body: Column(
      children: [
        Expanded(
          child: page,
        ),
        BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12.5,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.create),
              label: 'Interactive Scheduler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Log',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Habits List',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Past Records',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: (value) {
            setState(() {
              selectedIndex = value;
            });
          },
        ),
      ],
    ));
  }
}
