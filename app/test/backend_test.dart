import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  const String baseUrl = 'http://localhost:5000';

  group('GET /habits/<user_id>/ tests', () {
    test('should return habits for user with multiple habits', () async {
      final response = await http.get(Uri.parse('$baseUrl/habits/a23/'));
      expect(response.statusCode, equals(200));

      final Map<String, dynamic> data = json.decode(response.body);
      expect(data['habits'], isA<List>());
      expect(data['habits'].length, equals(2));

      // Verify first habit
      expect(data['habits'][0]['uid'], equals('a23'));
      expect(data['habits'][0]['name'], equals('Habit 1'));
      expect(data['habits'][0]['comments'], equals('Example comment for 1'));
      expect(data['habits'][0]['preferredQuadrant'], equals(0));
      expect(data['habits'][0]['active'], isTrue);
      expect(data['habits'][0]['since'], isNotNull);

      // Verify second habit
      expect(data['habits'][1]['uid'], equals('a23'));
      expect(data['habits'][1]['name'], equals('Habit 2'));
      expect(data['habits'][1]['comments'], equals('Example comment for 2'));
      expect(data['habits'][1]['preferredQuadrant'], equals(4));
      expect(data['habits'][1]['active'], isTrue);
      expect(data['habits'][1]['since'], isNotNull);
    });

    test('should return single habit for user with one habit', () async {
      final response = await http.get(Uri.parse('$baseUrl/habits/a22/'));
      expect(response.statusCode, equals(200));

      final Map<String, dynamic> data = json.decode(response.body);
      expect(data['habits'], isA<List>());
      expect(data['habits'].length, equals(1));

      expect(data['habits'][0]['uid'], equals('a22'));
      expect(data['habits'][0]['name'], equals('Habit 3'));
      expect(data['habits'][0]['comments'], equals('Example comment for 3'));
      expect(data['habits'][0]['preferredQuadrant'], equals(3));
    });

    test('should return empty list for non-existent user', () async {
      final response = await http.get(Uri.parse('$baseUrl/habits/non_existent_user/'));
      expect(response.statusCode, equals(200));

      final Map<String, dynamic> data = json.decode(response.body);
      expect(data['habits'], isA<List>());
      expect(data['habits'], isEmpty);
    });

    test('validates habit structure', () async {
      final response = await http.get(Uri.parse('$baseUrl/habits/a23/'));
      expect(response.statusCode, equals(200));

      final Map<String, dynamic> data = json.decode(response.body);
      final habit = data['habits'][0];

      // Verify habit has all required fields
      expect(habit.containsKey('hid'), isTrue);
      expect(habit.containsKey('uid'), isTrue);
      expect(habit.containsKey('name'), isTrue);
      expect(habit.containsKey('comments'), isTrue);
      expect(habit.containsKey('preferredQuadrant'), isTrue);
      expect(habit.containsKey('since'), isTrue);
      expect(habit.containsKey('active'), isTrue);

      // Verify data types
      expect(habit['hid'], isA<int>());
      expect(habit['uid'], isA<String>());
      expect(habit['name'], isA<String>());
      expect(habit['comments'], isA<String>());
      expect(habit['preferredQuadrant'], isA<int>());
      expect(habit['active'], isA<bool>());
    });
  });
}