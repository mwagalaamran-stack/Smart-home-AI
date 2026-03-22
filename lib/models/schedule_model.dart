// lib/models/schedule_model.dart
class ScheduleItem {
  final String id;
  final String label;
  final int relayIndex;      // 0-4 au -1 kwa zote
  final bool turnOn;         // true=washa, false=zima
  final int hour;
  final int minute;
  final List<bool> days;     // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final bool enabled;

  ScheduleItem({
    required this.id,
    required this.label,
    required this.relayIndex,
    required this.turnOn,
    required this.hour,
    required this.minute,
    required this.days,
    this.enabled = true,
  });

  static const List<String> dayNames = ['Ju2', 'Ju3', 'Ju4', 'Ala', 'Ij', 'Moi', 'Jp'];
  static const List<String> dayNamesFull = [
    'Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Moisosi', 'Jumapili'
  ];

  static const List<String> relayNames = [
    'Sabufa', 'TV', 'Taa ya Nje', 'Taa Chumbani', 'Taa Sebuleni', 'Zote'
  ];

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get daysString {
    if (days.every((d) => d)) return 'Kila siku';
    if (days.sublist(0, 5).every((d) => d) && !days[5] && !days[6]) return 'Siku za kazi';
    if (!days.sublist(0, 5).any((d) => d) && days[5] && days[6]) return 'Wikendi';
    return days.asMap().entries
        .where((e) => e.value)
        .map((e) => dayNames[e.key])
        .join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'relayIndex': relayIndex,
    'turnOn': turnOn,
    'hour': hour,
    'minute': minute,
    'days': days,
    'enabled': enabled,
  };

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
    id: j['id'],
    label: j['label'],
    relayIndex: j['relayIndex'],
    turnOn: j['turnOn'],
    hour: j['hour'],
    minute: j['minute'],
    days: List<bool>.from(j['days']),
    enabled: j['enabled'] ?? true,
  );

  ScheduleItem copyWith({
    String? label, int? relayIndex, bool? turnOn,
    int? hour, int? minute, List<bool>? days, bool? enabled,
  }) => ScheduleItem(
    id: id,
    label: label ?? this.label,
    relayIndex: relayIndex ?? this.relayIndex,
    turnOn: turnOn ?? this.turnOn,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    days: days ?? this.days,
    enabled: enabled ?? this.enabled,
  );
}
