import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chronosculpt/data_structures.dart';
import 'package:chronosculpt/config.dart';

/// Class which facilitates database connections.
class DatabaseHelper {
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  DatabaseHelper();

  Future<List<Habit>> getHabits(String uid) async {
    final response = await http.get(Uri.parse('$backendPath/habits/a23/'));
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

  Future<List<Record>> getPast30Days(String uid) async {
    var date = DateTime.now().subtract(const Duration(days: 31));
    var recordsList =
        await getRecordsByTimestamp(uid, date.millisecondsSinceEpoch);
    recordsList
        .removeWhere((element) => element.date.day == DateTime.now().day);
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
      headers: headers,
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
      headers: headers,
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
    };

    final response = await http.put(
      Uri.parse('$backendPath/habits/${h.hid}/'),
      body: json.encode(requestBody),
      headers: headers,
    );
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Habit.fromMap(data);
  }

  Future<Record> createRecordForCurrentDay(String uid) async {
    final response = await http.post(Uri.parse('$backendPath/records/$uid/'));
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Record.fromMap(data);
  }

  Future<Habit> createHabit(
    String uid, {
    required String name,
    required String comments,
    required int preferredQuadrant,
  }) async {
    var requestBody = {
      'name': name,
      'comments': comments,
      'preferredQuadrant': preferredQuadrant,
    };

    final response = await http.post(
      Uri.parse('$backendPath/habits/$uid/add/'),
      body: json.encode(requestBody),
      headers: headers,
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
    switch (response.statusCode) {
      case 400:
        throw DatabaseTransactionException(
            errorCode: 400, invalidValue: response.body);
      case 404:
        throw DatabaseTransactionException(
            errorCode: 404, invalidValue: response.body);
      case 406:
        throw DatabaseTransactionException(
            errorCode: 406, invalidValue: response.body);
      case 500:
        throw DatabaseTransactionException(
            errorCode: 500, invalidValue: response.body);
    }
  }
}

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
