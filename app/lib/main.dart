import 'package:chronosculpt/database_helper.dart';
import 'package:chronosculpt/firebase_helper.dart';
import 'package:chronosculpt/firebase_options.dart';
import 'package:chronosculpt/shared_preferences_helper.dart';
import 'package:chronosculpt/widgets/authentication.dart';
import 'package:chronosculpt/widgets/habit_list.dart';
import 'package:chronosculpt/widgets/history.dart';
import 'package:chronosculpt/widgets/interactive_scheduler.dart';
import 'package:chronosculpt/widgets/log.dart';
import 'package:chronosculpt/widgets/misc_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Before running the app, initialize Firebase
/// and sign out if the user requested it on login.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wake up server if it's asleep
  DatabaseHelper().getHabits('none');

  // Initialize authenticated
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferencesHelper().forgetIfRequested();

  runApp(const ChronosculptApp());
}

/// Returns the user ID of the currently logged in user.
String getCurrentUserUid() {
  var currentUser = FirebaseAuth.instance.currentUser;
  return currentUser?.uid ?? 'none';
}

/// Shows a snack bar with a given message.
void showSnackBar(BuildContext context, String s) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}

/// The main entry point of the application.
class ChronosculptApp extends StatelessWidget {
  const ChronosculptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronosculpt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 174, 85, 196),
          surface: const Color.fromARGB(255, 247, 239, 243),
        ),
        useMaterial3: true,
      ),
      home: const MainWidget(),
    );
  }
}

/// The widget that holds the main 4 widgets of the app.
/// Contains the currently selected widget as well as
/// the BottomNavigationBar.
class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  var selectedIndex = 0;
  var dataLoaded = false;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    if (!FirebaseHelper().authenticated()) {
      return const SplashWidget();
    }

    Widget page;
    String appBarText = '';
    Color appBarColor = Colors.transparent;
    Color textColor = Colors.transparent;
    switch (selectedIndex) {
      case 0:
        page = const LogWidgetWrapper();
        appBarText = "Log";
        appBarColor = colorScheme.secondary;
        textColor = colorScheme.surface;
        break;
      case 1:
        page = const InteractiveSchedulerWrapper();
        appBarText = "Interactive Scheduler";
        appBarColor = colorScheme.surface;
        textColor = colorScheme.secondary;
        break;
      case 2:
        page = const HabitListWrapper();
        appBarText = "Habit List";
        appBarColor = colorScheme.surface;
        textColor = colorScheme.secondary;
        break;
      case 3:
        page = const HistoryWidgetWrapper();
        appBarText = "History";
        appBarColor = colorScheme.secondary;
        textColor = colorScheme.surface;
        break;
      default:
        page = const ErrorScreen(message: '404 Page Not Found');
        break;
    }

    // Backfills past data for stopwatch and live splitter functionality.
    if (!dataLoaded) {
      PastHabitsWidget.retrieveAndAnalyzeData().catchError(
        (error) => showSnackBar(context, 'Error preloading past data: $error'),
      );
      dataLoaded = true;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        centerTitle: true,
        title: Text(
          appBarText,
          style: TextStyle(color: textColor),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseHelper().signOut();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: textColor),
            child: Text(
              'Sign Out',
              style: TextStyle(color: appBarColor),
            ),
          ),
        ],
      ),
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
      ),
    );
  }
}
