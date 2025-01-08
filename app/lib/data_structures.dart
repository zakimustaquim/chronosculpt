// entry in the habits table
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

  // factory Habit.fromMap()
}

class Entry {
  int eid;
  int rid;
  int hid;
  String habitName;
  String comments;
  bool done;
  int quadrant;
  int doneAt;
  int split;

  Entry({
    required this.eid,
    required this.rid,
    required this.hid,
    required this.habitName,
    required this.comments,
    required this.done,
    required this.quadrant,
    required this.doneAt,
    required this.split,
  });
}

class Record {
  int rid;
  String uid;
  DateTime date;
  String q1notes;
  String q2notes;
  String q3notes;
  String q4notes;

  Record({
    required this.rid,
    required this.uid,
    required this.date,
    required this.q1notes,
    required this.q2notes,
    required this.q3notes,
    required this.q4notes,
  });
}
