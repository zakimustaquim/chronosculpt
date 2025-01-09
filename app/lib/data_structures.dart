class Habit {
  int hid;
  String uid;
  String name;
  String comments;
  int preferredQuadrant;
  DateTime since;
  bool active;

  Habit({
    required this.hid,
    required this.uid,
    required this.name,
    required this.comments,
    required this.preferredQuadrant,
    required this.since,
    required this.active,
  });

  factory Habit.fromMap(Map<String, dynamic> habit) {
    return Habit(
      hid: habit['hid'],
      uid: habit['uid'],
      name: habit['name'],
      comments: habit['comments'],
      preferredQuadrant: habit['preferredQuadrant'],
      since: parseString(habit['since']),
      active: habit['active'],
    );
  }
  
  @override
  String toString() => '$hid | $uid | $name | $comments | $preferredQuadrant | $since | $active';
}

class Entry {
  int eid;
  int rid;
  int hid;
  String habitName;
  String comments;
  bool done;
  int quadrant;
  DateTime? doneAt;
  int? split;

  Entry({
    required this.eid,
    required this.rid,
    required this.hid,
    required this.habitName,
    required this.comments,
    required this.done,
    required this.quadrant,
    this.doneAt,
    this.split,
  });

  factory Entry.fromMap(Map<String, dynamic> entry) {
    DateTime? doneAt;
    int? split;
    if (entry['doneAt'] != null) {
      doneAt = parseString(entry['doneAt']);
    }

    if (entry['split'] != null) {
      split = entry['split'];
    }

    return Entry(
      eid: entry['eid'],
      rid: entry['rid'],
      hid: entry['hid'],
      habitName: entry['habit_name'],
      comments: entry['comments'],
      done: entry['done'],
      quadrant: entry['quadrant'],
      doneAt: doneAt,
      split: split,
    );
  }

  @override
  String toString() => '$eid - $rid - $hid - $habitName - $comments - $done - $quadrant - $doneAt - $split';
}

class Record {
  int rid;
  String uid;
  DateTime date;
  String q1notes;
  String q2notes;
  String q3notes;
  String q4notes;
  List<Entry> entries;

  Record({
    required this.rid,
    required this.uid,
    required this.date,
    required this.q1notes,
    required this.q2notes,
    required this.q3notes,
    required this.q4notes,
    required this.entries,
  });

  factory Record.fromMap(Map<String, dynamic> record) {
    List<Entry> entries = [];
    var entriesList = record['entries'] as List;
    for (var entry in entriesList) {
      entries.add(Entry.fromMap(entry));
    }

    return Record(
      rid: record['rid'],
      uid: record['uid'],
      date: parseString(record['date']),
      q1notes: record['q1notes'],
      q2notes: record['q2notes'],
      q3notes: record['q3notes'],
      q4notes: record['q4notes'],
      entries: entries,
    );
  }

  @override
  String toString() => '$rid | $uid | $date | $entries | $q1notes | $q2notes | $q3notes | $q4notes';
}

// parses a String as returned from the API into a DateTime object
DateTime parseString(String s) {
  List<String> tokens = s.split(', ')[1].split(' ');
  // Example: 08 Jan 2025 20:57:02 GMT
  int day = int.parse(tokens[0]);
  int month = convertStringToDayOfMonth(tokens[1]);
  int year = int.parse(tokens[2]);

  tokens = tokens[3].split(':');
  // Example: 20:57:02
  int hour = int.parse(tokens[0]);
  int minute = int.parse(tokens[1]);
  int second = int.parse(tokens[2]);

  return DateTime(
    year,
    month,
    day,
    hour,
    minute,
    second
  );
}

// The input string should be an abbreviation as in Python's dt toString call
int convertStringToDayOfMonth(String s) {
  switch (s) {
    case 'Jan':
      return 1;
    case 'Feb':
      return 2;
    case 'Mar':
      return 3;
    case 'Apr':
      return 4;
    case 'May':
      return 5;
    case 'Jun':
      return 6;
    case 'Jul':
      return 7;
    case 'Aug':
      return 8;
    case 'Sep':
      return 9;
    case 'Oct':
      return 10;
    case 'Nov':
      return 11;
    case 'Dec':
      return 12;
    default:
      throw MonthNotFoundException(invalidValue: s);
  }
}

class MonthNotFoundException implements Exception {
  final String message;
  final String invalidValue;

  MonthNotFoundException({this.invalidValue = '', this.message = 'Month could not be parsed'});

  @override
  String toString() => '$message: $invalidValue';
}
