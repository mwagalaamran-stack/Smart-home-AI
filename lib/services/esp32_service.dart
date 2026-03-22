// lib/services/esp32_service.dart
import 'package:http/http.dart' as http;

class Esp32Service {
  static const String baseUrl = 'http://192.168.4.1';
  static const Duration _timeout = Duration(seconds: 4);

  // ── RELAY ──────────────────────────────────────────────────
  static Future<bool> toggleRelay(int index) async {
    try {
      await http.get(Uri.parse('$baseUrl/toggle$index')).timeout(_timeout);
      return true;
    } catch (_) { return false; }
  }

  static Future<bool> setRelay(int index, bool on) async {
    try {
      await http.get(Uri.parse('$baseUrl/set$index?state=${on ? 1 : 0}')).timeout(_timeout);
      return true;
    } catch (_) { return false; }
  }

  static Future<List<bool>> getState() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/state')).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = res.body.replaceAll('[','').replaceAll(']','');
        return body.split(',').map((e) => e.trim() == 'true').toList();
      }
    } catch (_) {}
    return List.filled(5, false);
  }

  // ── IR HISENSE ─────────────────────────────────────────────
  static Future<bool> sendHisense(String key) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ir/hisense?key=$key'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── IR AZAM ────────────────────────────────────────────────
  static Future<bool> sendAzam(String key) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ir/azam?key=$key'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── VOLUME (multiple taps) ──────────────────────────────────
  static Future<void> volumeHisense(String direction, int steps) async {
    final key = direction == 'up' ? 'VOL_UP' : 'VOL_DOWN';
    for (int i = 0; i < steps; i++) {
      await sendHisense(key);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  static Future<void> volumeAzam(String direction, int steps) async {
    final key = direction == 'up' ? 'AZ_VOL_RIGHT' : 'AZ_VOL_LEFT';
    for (int i = 0; i < steps; i++) {
      await sendAzam(key);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ── CHANNEL ────────────────────────────────────────────────
  static Future<void> channelHisense(String direction) async {
    await sendHisense(direction == 'up' ? 'CH_UP' : 'CH_DOWN');
  }

  static Future<void> channelAzam(String direction) async {
    await sendAzam(direction == 'up' ? 'AZ_CH_UP' : 'AZ_CH_DOWN');
  }

  // ── CONNECTION CHECK ────────────────────────────────────────
  static Future<bool> isConnected() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/state'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }
}
