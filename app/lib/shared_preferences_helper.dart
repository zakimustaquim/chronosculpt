import 'package:chronosculpt/firebase_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
