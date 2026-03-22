// lib/services/app_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'esp32_service.dart';
import 'scheduler_service.dart';

class AppState extends ChangeNotifier {
  List<bool> relayStates = List.filled(5, false);
  bool isConnected = false;
  bool isListening = false;
  String lastVoiceText = '';
  String lastActionMsg = '';
  bool lastActionSuccess = true;
  Timer? _stateTimer;

  final SchedulerService scheduler = SchedulerService();

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await scheduler.load();
    scheduler.onActionFired = (msg) {
      lastActionMsg = msg;
      lastActionSuccess = true;
      notifyListeners();
      _fetchState();
    };
    scheduler.start();
    _startPolling();
  }

  void _startPolling() {
    _stateTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchState());
    _fetchState();
  }

  Future<void> _fetchState() async {
    final connected = await Esp32Service.isConnected();
    if (connected != isConnected) {
      isConnected = connected;
      notifyListeners();
    }
    if (connected) {
      final states = await Esp32Service.getState();
      relayStates = states;
      notifyListeners();
    }
  }

  Future<void> toggleRelay(int index) async {
    await Esp32Service.toggleRelay(index);
    await _fetchState();
  }

  void setListening(bool val) {
    isListening = val;
    notifyListeners();
  }

  void setVoiceText(String text) {
    lastVoiceText = text;
    notifyListeners();
  }

  void setActionResult(String msg, bool success) {
    lastActionMsg = msg;
    lastActionSuccess = success;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    scheduler.stop();
    super.dispose();
  }
}
