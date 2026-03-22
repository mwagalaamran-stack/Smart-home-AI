// lib/models/device_model.dart

class DeviceModel {
  final String id;
  String name;
  String emoji;
  int relayPin;   // index ya relay kwenye ESP32 (0-7)
  bool enabled;
  String color;   // hex color string

  DeviceModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.relayPin,
    this.enabled = true,
    this.color = '#00D4FF',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'relayPin': relayPin,
    'enabled': enabled,
    'color': color,
  };

  factory DeviceModel.fromJson(Map<String, dynamic> j) => DeviceModel(
    id: j['id'],
    name: j['name'],
    emoji: j['emoji'] ?? '💡',
    relayPin: j['relayPin'],
    enabled: j['enabled'] ?? true,
    color: j['color'] ?? '#00D4FF',
  );

  DeviceModel copyWith({
    String? name, String? emoji, int? relayPin,
    bool? enabled, String? color,
  }) => DeviceModel(
    id: id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    relayPin: relayPin ?? this.relayPin,
    enabled: enabled ?? this.enabled,
    color: color ?? this.color,
  );

  // Default devices
  static List<DeviceModel> defaults() => [
    DeviceModel(id: 'd0', name: 'Sabufa',        emoji: '🔊', relayPin: 0, color: '#9B59B6'),
    DeviceModel(id: 'd1', name: 'TV',             emoji: '📺', relayPin: 1, color: '#2980B9'),
    DeviceModel(id: 'd2', name: 'Taa ya Nje',     emoji: '💡', relayPin: 2, color: '#F39C12'),
    DeviceModel(id: 'd3', name: 'Taa Chumbani',   emoji: '🛏️', relayPin: 3, color: '#27AE60'),
    DeviceModel(id: 'd4', name: 'Taa Sebuleni',   emoji: '🛋️', relayPin: 4, color: '#E67E22'),
  ];
}
