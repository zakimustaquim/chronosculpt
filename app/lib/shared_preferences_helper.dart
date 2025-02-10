import 'package:chronosculpt/firebase_helper.dart';
import 'package:chronosculpt/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles Shared Preferences transactions.
class SharedPreferencesHelper {
  Future<void> forgetIfRequested() async {
    var fh = FirebaseHelper();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? shouldForget = prefs.getBool('shouldForget');

      if (shouldForget != null) {
        await fh.signOut();
        removeForgetting();
      }
    } catch (e) {
      if (fh.authenticated()) await fh.signOut();
    }
  }

  Future<void> setToForget() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shouldForget', true);
    } catch (e) {
      // Do nothing
    }
  }

  Future<void> removeForgetting() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('shouldForget');
    } catch (e) {
      // Do nothing
    }
  }

  Future<void> getPreferredHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int pref = prefs.getInt('preferredHistory')!;
      historyPreference = pref;
    } catch (_) {
      historyPreference = 30;
    }
  }

  Future<void> setPreferredHistory(int days) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('preferredHistory', days);
      historyPreference = days;
    } catch (_) {
      // Do nothing
    }
  }
}
