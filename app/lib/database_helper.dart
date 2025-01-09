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
    // TODO - calculate timestamp
    return await getRecordsByTimestamp(uid, 0);
  }

  Future<List<Record>> getPast30Days(String uid) async {
    // TODO - calculate timestamp
    return await getRecordsByTimestamp(uid, 0);
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
    // TODO
    throw Exception();
  }

  Future<Record> createRecordForCurrentDay(String uid) async {
    final response = await http.post(Uri.parse('$backendPath/records/$uid/'));
    checkResponse(response);

    final Map<String, dynamic> data = json.decode(response.body);
    return Record.fromMap(data);
  }

  Future<void> deleteHabit(Habit h) async {
    // TODO
  }

  void checkResponse(http.Response response) {
    switch (response.statusCode) {
      case 404:
        throw DatabaseTransactionException(
            invalidValue: '404, ${response.body}');
      case 500:
        throw DatabaseTransactionException(
            invalidValue: '500, ${response.body}');
    }
  }
}

class DatabaseTransactionException {
  String? message;
  String? invalidValue;

  DatabaseTransactionException({
    this.message = "The database response contained an error",
    this.invalidValue = "",
  });

  @override
  String toString() => "$message: $invalidValue";
}
