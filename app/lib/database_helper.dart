import 'dart:async';

import 'package:chronosculpt/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/config.dart';

/// Class which facilitates network connections to the
/// backend. Uses the http package to make requests.
class DatabaseHelper {
  final Map<String, String> _headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  DatabaseHelper();

  Future<List<Habit>> getHabits(String uid) async {
    final response = await http.get(Uri.parse('$backendPath/habits/$uid/'));
    checkResponse(response);
    final Map<String, dynamic> data = json.decode(response.body);

    var habitsList = data['habits'] as List;
    List<Habit> result = [];
    for (var habit in habitsList) {
      result.add(Habit.fromMap(habit));
    }
    return result;
  }

  Future<List<Record>> getRecordsByTimestamp(String uid, int timestamp) async {
    final response =
        await http.get(Uri.parse('$backendPath/records/$uid/$timestamp/'));
    checkResponse(response);
    final Map<String, dynamic> data = json.decode(response.body);

    var recordsList = data['records'] as List;
    List<Record> result = [];
    for (var record in recordsList) {
      result.add(Record.fromMap(record));
    }
    return result;
  }

  Future<List<Record>> getRecordsForCurrentDay(String uid) async {
    var date = DateTime.now().subtract(const Duration(days: 1));
    return await getRecordsByTimestamp(uid, date.millisecondsSinceEpoch);
  }

  Future<List<Record>> getPastRecords(String uid) async {
    int daysPast =
        historyPreference; // retrieve from global variable in main.dart
    var date = daysPast == 0
        ? DateTime(2000)
        : DateTime.now().subtract(Duration(days: daysPast + 1));
    var recordsList =
        await getRecordsByTimestamp(uid, date.millisecondsSinceEpoch);
    recordsList
        .removeWhere((element) => element.date.day == DateTime.now().day);
    if (DateTime.now().hour < 4) {
      DateTime now = DateTime.now();
      int year = now.year;
      int month = now.month;
      int day = now.day;

      DateTime d =
          (DateTime(year, month, day, 4).subtract(const Duration(days: 1)));

      recordsList.removeWhere((element) =>
          element.date.day == d.day && element.date.month == d.month);
    }
    recordsList.sort(
      (a, b) => b.date.compareTo(a.date),
    );
    return recordsList;
  }

  Future<Record> updateRecord(Record r) async {
    var requestBody = {
      'q1notes': r.q1notes,
      'q2notes': r.q2notes,
      'q3notes': r.q3notes,
      'q4notes': r.q4notes,
    };

    final response = await http.put(
      Uri.parse('$backendPath/records/${r.rid}/'),
      body: json.encode(requestBody),
      headers: _headers,
    );
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Record.fromMap(data);
  }

  Future<Entry> updateEntry(Entry e) async {
    var requestBody = {
      'comments': e.comments,
      'done': e.done,
      'quadrant': e.quadrant,
      'doneAt': e.doneAt?.millisecondsSinceEpoch,
      'split': e.split
    };

    final response = await http.put(
      Uri.parse('$backendPath/entries/${e.eid}/'),
      body: json.encode(requestBody),
      headers: _headers,
    );
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Entry.fromMap(data);
  }

  Future<Habit> updateHabit(Habit h) async {
    var requestBody = {
      'name': h.name,
      'comments': h.comments,
      'preferredQuadrant': h.preferredQuadrant,
      'active': h.active,
      'length': h.length,
    };

    final response = await http.put(
      Uri.parse('$backendPath/habits/${h.hid}/'),
      body: json.encode(requestBody),
      headers: _headers,
    );
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Habit.fromMap(data);
  }

  Future<Record> createRecordForCurrentDay(String uid) async {
    final DateTime date = DateTime.now();
    var startOfDay =
        DateTime(date.year, date.month, date.day).add(const Duration(hours: 4));
    if (date.hour < 4) {
      startOfDay = startOfDay.subtract(const Duration(days: 1));
    }
    final timestamp = startOfDay.millisecondsSinceEpoch;

    final response =
        await http.post(Uri.parse('$backendPath/records/$uid/$timestamp/'));
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Record.fromMap(data);
  }

  Future<Habit> createHabit(
    String uid, {
    required String name,
    required String comments,
    required int preferredQuadrant,
    required int length,
  }) async {
    var requestBody = {
      'name': name,
      'comments': comments,
      'preferredQuadrant': preferredQuadrant,
      'length': length,
    };

    final response = await http.post(
      Uri.parse('$backendPath/habits/$uid/add/'),
      body: json.encode(requestBody),
      headers: _headers,
    );
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Habit.fromMap(data);
  }

  Future<void> deleteHabit(Habit h) async {
    final response =
        await http.delete(Uri.parse('$backendPath/habits/${h.hid}/'));
    checkResponse(response);
  }

  void checkResponse(http.Response response) {
    if (response.statusCode == 200) return;
    throw DatabaseTransactionException(
      errorCode: response.statusCode,
      invalidValue: response.body,
    );
  }

  Future<void> wakeUpDatabase() async {
    bool isRunning = true;

    // Try to wake up the database for 15 seconds;
    // if by that point it has not woken up, stop trying.
    Future.delayed(const Duration(seconds: 15), () {
      isRunning = false;
    });

    while (isRunning) {
      try {
        final response = await http
            .get(Uri.parse('$backendPath/wakeup'))
            .timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) isRunning = false;
        await Future.delayed(const Duration(milliseconds: 250));
      } on TimeoutException {
        // Request timed out, try again
        continue;
      } catch (e) {
        continue;
      }
    }
  }
}

/// Exception thrown when a non-200 status code was received
/// from the backend.
class DatabaseTransactionException {
  int errorCode;
  String? message;
  String? invalidValue;

  DatabaseTransactionException({
    required this.errorCode,
    this.message = "The database response contained an error",
    this.invalidValue = "",
  });

  @override
  String toString() => "$message: $errorCode, $invalidValue";
}
