// lib/services/settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';
import '../models/settings_model.dart';

class SettingsService {
  static final SettingsService _i = SettingsService._();
  factory SettingsService() => _i;
  SettingsService._();

  AppSettings settings = AppSettings();
  List<DeviceModel> devices = DeviceModel.defaults();

  // ── LOAD ───────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Settings
    final rawSettings = prefs.getString('app_settings');
    if (rawSettings != null) {
      settings = AppSettings.fromJson(jsonDecode(rawSettings));
    }

    // Devices
    final rawDevices = prefs.getStringList('devices');
    if (rawDevices != null && rawDevices.isNotEmpty) {
      devices = rawDevices
          .map((d) => DeviceModel.fromJson(jsonDecode(d)))
          .toList();
    }
  }

  // ── SAVE ───────────────────────────────────────────────────
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(settings.toJson()));
  }

  Future<void> saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'devices',
      devices.map((d) => jsonEncode(d.toJson())).toList(),
    );
  }

  // ── DEVICE CRUD ────────────────────────────────────────────
  Future<void> addDevice(DeviceModel d) async {
    devices.add(d);
    await saveDevices();
  }

  Future<void> updateDevice(DeviceModel d) async {
    final idx = devices.indexWhere((x) => x.id == d.id);
    if (idx >= 0) devices[idx] = d;
    await saveDevices();
  }

  Future<void> deleteDevice(String id) async {
    devices.removeWhere((d) => d.id == id);
    await saveDevices();
  }

  Future<void> reorderDevices(int oldIdx, int newIdx) async {
    final d = devices.removeAt(oldIdx);
    devices.insert(newIdx, d);
    await saveDevices();
  }

  // ── VOICE COMMANDS ─────────────────────────────────────────
  Future<void> addVoiceCommand(String cmd) async {
    settings.customVoiceCommands.add(cmd);
    await saveSettings();
  }

  Future<void> deleteVoiceCommand(int idx) async {
    settings.customVoiceCommands.removeAt(idx);
    await saveSettings();
  }

  // ── THEME ──────────────────────────────────────────────────
  Future<void> setTheme(String name) async {
    settings.themeName = name;
    settings.themeAccent = AppSettings.themes[name] ?? '#00D4FF';
    await saveSettings();
  }

  // ── RESET ──────────────────────────────────────────────────
  Future<void> resetDevices() async {
    devices = DeviceModel.defaults();
    await saveDevices();
  }

  Future<void> resetAll() async {
    settings = AppSettings();
    devices = DeviceModel.defaults();
    await saveSettings();
    await saveDevices();
  }

  // Helper — hex string to Color int
  static int hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return int.parse('FF$h', radix: 16);
  }
}
