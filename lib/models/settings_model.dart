// lib/models/settings_model.dart

class AppSettings {
  String espIp;
  String wifiSsid;
  String wifiPassword;
  String language;        // 'sw' au 'en' au 'both'
  String themeAccent;     // hex color
  String themeName;       // 'cyan', 'green', 'orange', 'purple'
  List<String> customVoiceCommands; // commands za ziada

  AppSettings({
    this.espIp = '192.168.4.1',
    this.wifiSsid = 'SMART_HOME',
    this.wifiPassword = '12345678',
    this.language = 'both',
    this.themeAccent = '#00D4FF',
    this.themeName = 'cyan',
    this.customVoiceCommands = const [],
  });

  Map<String, dynamic> toJson() => {
    'espIp': espIp,
    'wifiSsid': wifiSsid,
    'wifiPassword': wifiPassword,
    'language': language,
    'themeAccent': themeAccent,
    'themeName': themeName,
    'customVoiceCommands': customVoiceCommands,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    espIp: j['espIp'] ?? '192.168.4.1',
    wifiSsid: j['wifiSsid'] ?? 'SMART_HOME',
    wifiPassword: j['wifiPassword'] ?? '12345678',
    language: j['language'] ?? 'both',
    themeAccent: j['themeAccent'] ?? '#00D4FF',
    themeName: j['themeName'] ?? 'cyan',
    customVoiceCommands: List<String>.from(j['customVoiceCommands'] ?? []),
  );

  static const Map<String, String> themes = {
    'cyan':   '#00D4FF',
    'green':  '#2ECC71',
    'orange': '#E85A00',
    'purple': '#9B59B6',
    'red':    '#E74C3C',
    'gold':   '#F1C40F',
  };
}
