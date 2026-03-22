// lib/services/scheduler_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'esp32_service.dart';

class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  List<ScheduleItem> schedules = [];
  Timer? _ticker;
  Function(String)? onActionFired; // callback kuonyesha toast

  // ── LOAD / SAVE ────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('schedules') ?? [];
    schedules = raw
        .map((s) => ScheduleItem.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'schedules',
      schedules.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  // ── START TICKER ───────────────────────────────────────────
  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _checkSchedules());
    _checkSchedules(); // angalia mara moja sasa hivi
  }

  void stop() => _ticker?.cancel();

  // ── CHECK ──────────────────────────────────────────────────
  void _checkSchedules() async {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0=Mon...6=Sun

    for (final s in schedules) {
      if (!s.enabled) continue;
      if (!s.days[todayIndex]) continue;
      if (s.hour != now.hour) continue;

      // Angalia dakika — within 1 dakika
      final diff = (s.minute - now.minute).abs();
      if (diff > 1) continue;

      await _fire(s);
    }
  }

  Future<void> _fire(ScheduleItem s) async {
    print('[Scheduler] Firing: ${s.label}');

    if (s.relayIndex == -1) {
      for (int i = 0; i < 5; i++) {
        await Esp32Service.setRelay(i, s.turnOn);
      }
    } else {
      await Esp32Service.setRelay(s.relayIndex, s.turnOn);
    }

    final action = s.turnOn ? 'imewashwa' : 'imezimwa';
    final name = s.relayIndex == -1
        ? 'Taa zote'
        : ScheduleItem.relayNames[s.relayIndex];

    onActionFired?.call('⏰ $name $action (Schedule)');
  }

  // ── CRUD ───────────────────────────────────────────────────
  Future<void> add(ScheduleItem item) async {
    schedules.add(item);
    await save();
  }

  Future<void> update(ScheduleItem item) async {
    final idx = schedules.indexWhere((s) => s.id == item.id);
    if (idx >= 0) schedules[idx] = item;
    await save();
  }

  Future<void> delete(String id) async {
    schedules.removeWhere((s) => s.id == id);
    await save();
  }

  Future<void> toggle(String id) async {
    final idx = schedules.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      schedules[idx] = schedules[idx].copyWith(enabled: !schedules[idx].enabled);
      await save();
    }
  }
}
