/// Abstract class declaring that implementing
/// members should be able to clone themselves
/// (i.e. return a new object that is identical)
abstract class Cloneable {
  Cloneable clone();
}

/// Responses from the server regarding the habits table
/// are mapped onto this class.
class Habit extends Cloneable {
  int hid;
  int length;
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
    required this.length,
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
      length: habit['length'],
    );
  }

  @override
  String toString() =>
      '$hid | $uid | $name | $comments | $preferredQuadrant | $since | $active';

  @override
  Habit clone() {
    return Habit(
      active: active,
      since: since,
      preferredQuadrant: preferredQuadrant,
      comments: comments,
      name: name,
      uid: uid,
      hid: hid,
      length: length,
    );
  }

  void updateFrom(Habit h) {
    hid = h.hid;
    uid = h.uid;
    name = h.name;
    comments = h.comments;
    preferredQuadrant = h.preferredQuadrant;
    since = h.since;
    active = h.active;
    length = h.length;
  }
}

/// Responses from the server regarding the entries table
/// are mapped onto this class.
class Entry extends Cloneable {
  int eid;
  int rid;
  int hid;
  String habitName;
  String comments;
  bool done;
  int quadrant;
  DateTime? doneAt;
  int? split;
  DateTime? dateOfOccurrence;
  int length;

  Entry({
    required this.eid,
    required this.rid,
    required this.hid,
    required this.habitName,
    required this.comments,
    required this.done,
    required this.quadrant,
    required this.length,
    this.doneAt,
    this.split,
    this.dateOfOccurrence,
  });

  factory Entry.fromMap(Map<String, dynamic> entry) {
    DateTime? doneAt;
    int? split;
    if (entry['doneAt'] != null) {
      doneAt = DateTime.fromMillisecondsSinceEpoch(entry['doneAt']);
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
      length: entry['length'],
    );
  }

  @override
  String toString() =>
      '$eid - $rid - $hid - $habitName - $comments - $done - $quadrant - $doneAt - $split';

  @override
  Entry clone() {
    return Entry(
      comments: comments,
      eid: eid,
      rid: rid,
      hid: hid,
      habitName: habitName,
      done: done,
      doneAt: doneAt,
      split: split,
      quadrant: quadrant,
      length: length,
    );
  }

  void updateFrom(Entry e) {
    eid = e.eid;
    rid = e.rid;
    hid = e.hid;
    habitName = e.habitName;
    comments = e.comments;
    done = e.done;
    doneAt = e.doneAt;
    split = e.split;
    quadrant = e.quadrant;
    length = e.length;
  }

  int getSearchPriority() {
    if (doneAt == null) {
      return length;
    } else {
      return doneAt!.millisecondsSinceEpoch;
    }
  }
}

/// Responses from the server regarding the records table
/// are mapped onto this class.
class Record extends Cloneable {
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
    entries.sort((a, b) => a.getSearchPriority() - b.getSearchPriority());

    return Record(
      rid: record['rid'],
      uid: record['uid'],
      date: DateTime.fromMillisecondsSinceEpoch(record['date']),
      q1notes: record['q1notes'],
      q2notes: record['q2notes'],
      q3notes: record['q3notes'],
      q4notes: record['q4notes'],
      entries: entries,
    );
  }

  @override
  String toString() =>
      '$rid | $uid | $date | $entries | $q1notes | $q2notes | $q3notes | $q4notes';

  @override
  Record clone() {
    return Record(
      date: date,
      rid: rid,
      uid: uid,
      q1notes: q1notes,
      q2notes: q2notes,
      q3notes: q3notes,
      q4notes: q4notes,
      entries: deepCopyList<Entry>(entries),
    );
  }

  void updateFrom(Record r) {
    date = r.date;
    rid = r.rid;
    uid = r.uid;
    q1notes = r.q1notes;
    q2notes = r.q2notes;
    q3notes = r.q3notes;
    q4notes = r.q4notes;
  }
}

/// parses a String as returned from the API into a DateTime object
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

  DateTime date = DateTime.utc(year, month, day, hour, minute, second);
  return date; // keep in utc for now
}

/// Gets the equivalent month as an int for a given String abbreviation.
/// The input string should be an abbreviation as in Python's dt toString call.
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

/// Thrown if the month abbreviation wasn't able to be mapped.
class MonthNotFoundException implements Exception {
  final String message;
  final String invalidValue;

  MonthNotFoundException({
    this.invalidValue = '',
    this.message = 'Month could not be parsed',
  });

  @override
  String toString() => '$message: $invalidValue';
}

/// Returns a deep copy of a given list.
List<T> deepCopyList<T>(List<T> inputList) {
  return inputList.map((element) {
    if (element is Cloneable) {
      return element.clone() as T;
    } else {
      // If elements are not Cloneable, assume they are immutable (like int, String, etc.)
      return element;
    }
  }).toList();
}

/// Used by PastHabitsWIdget for calculating statistics
/// on a given habit. Contains all the occurrences of
/// a given habit.
class HabitRetrospective {
  final String name;
  final int hid;
  final List<Entry> occurrences;

  HabitRetrospective({
    required this.name,
    required this.occurrences,
    required this.hid,
  });

  double get averageSplit {
    int totalTime = 0;
    int totalRecordedSplits = 0;

    for (var occurrence in occurrences) {
      if (occurrence.split != null) {
        totalTime += occurrence.split!;
        totalRecordedSplits++;
      }
    }

    if (totalRecordedSplits == 0) return 0;

    double average = totalTime / totalRecordedSplits;
    return average;
  }

  int get minSplit {
    int min = -1 >>> 1;
    for (var occurrence in occurrences) {
      if (occurrence.split != null && occurrence.split! < min) {
        min = occurrence.split!;
      }
    }
    return min == -1 >>> 1 ? 0 : min;
  }

  double get donePercentage {
    int totalDone = 0;
    for (var occurrence in occurrences) {
      if (occurrence.done) totalDone++;
    }
    return totalDone / occurrences.length;
  }

  @override
  String toString() => "$name $occurrences";
}

/// Holds the status of the tile in the Live Splitter.
enum LiveSplitStatus {
  waiting,
  inProgress,
  uploading,
  uploadSuccess,
  uploadFailure
}

/// Used by Live Splitter to manage independent timers.
class LiveSplitUnit {
  Entry entry;
  DateTime? startTime;
  Duration elapsed;
  double averageSplit;
  int minSplit;
  LiveSplitStatus status;

  LiveSplitUnit({
    required this.entry,
    this.startTime,
    this.elapsed = Duration.zero,
    required this.averageSplit,
    required this.minSplit,
    this.status = LiveSplitStatus.waiting,
  });

  String get name => entry.habitName;
}

/// Gets the total length of a list of entries.
/// Used by Interactive Scheduler to display the
/// total time remaining for a given quadrant.
int getTimesink(List<Entry> entries) {
  int res = 0;
  for (var entry in entries) {
    res += entry.length;
  }
  return res;
}

/// Formats a given duration into HH:MM:SS format.
String formatSplit(double milliseconds) {
  Duration d = Duration(milliseconds: milliseconds.round());
  String noMilliseconds = d.toString().split('.')[0];
  if (d.inHours >= 1) {
    return noMilliseconds;
  } else {
    return noMilliseconds.substring(2);
  }
}

/// Formats a date to HH:MM [AM/PM] format.
String formatDateForPastRecord(DateTime date) {
  bool isPm = (date.hour >= 12);
  if (isPm && date.hour > 12) date = date.subtract(const Duration(hours: 12));
  if (date.hour == 0) date = date.add(const Duration(hours: 12));
  String mainString = date.toString().split(' ')[1].split('.')[0];
  if (isPm) {
    return "$mainString PM";
  } else {
    return "$mainString AM";
  }
}

/// Finds the average split associated with a given entry.
double getAverageSplit(int hid, Map<int, HabitRetrospective> hrs) {
  if (hrs[hid] != null) {
    return hrs[hid]!.averageSplit;
  } else {
    return 0;
  }
}

/// Finds the average split associated with a given entry.
int getMinSplit(int hid, Map<int, HabitRetrospective> hrs) {
  if (hrs[hid] != null) {
    return hrs[hid]!.minSplit;
  } else {
    return 0;
  }
}
