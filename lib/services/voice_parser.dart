// lib/services/voice_parser.dart
import 'esp32_service.dart';

class VoiceResult {
  final bool success;
  final String message;
  VoiceResult({required this.success, required this.message});
}

class VoiceParser {

  // ── TAA NAMES ──────────────────────────────────────────────
  static const Map<String, int> _taaMap = {
    // Kiswahili
    'sabufa': 0,       'subwoofer': 0,
    'tv': 1,           'televisheni': 1,
    'taa ya nje': 2,   'nje': 2,       'outside': 2,  'exterior': 2,
    'taa ya chumba': 3,'chumba': 3,    'bedroom': 3,  'room': 3,
    'taa ya sebule': 4,'sebule': 4,    'living room': 4, 'lounge': 4,
    // zote
    'zote': -1,        'all': -1,      'kila kitu': -1,
  };

  // ── MAIN PARSER ────────────────────────────────────────────
  static Future<VoiceResult> parse(String text) async {
    final t = text.toLowerCase().trim();
    print('[Voice] Parsing: $t');

    // 1. Relay / Taa
    final relayResult = await _handleRelay(t);
    if (relayResult != null) return relayResult;

    // 2. Volume
    final volResult = await _handleVolume(t);
    if (volResult != null) return volResult;

    // 3. Channel
    final chResult = await _handleChannel(t);
    if (chResult != null) return chResult;

    // 4. Power TV
    final pwrResult = await _handlePower(t);
    if (pwrResult != null) return pwrResult;

    // 5. Mute
    final muteResult = await _handleMute(t);
    if (muteResult != null) return muteResult;

    return VoiceResult(
      success: false,
      message: 'Samahani, sikuelewa. Jaribu tena.',
    );
  }

  // ── RELAY / TAA ────────────────────────────────────────────
  static Future<VoiceResult?> _handleRelay(String t) async {
    // Gundua action: washa / zima
    bool? turnOn;
    if (_contains(t, ['washa', 'weka', 'turn on', 'switch on', 'on'])) {
      turnOn = true;
    } else if (_contains(t, ['zima', 'ondoa', 'turn off', 'switch off', 'off'])) {
      turnOn = false;
    }

    if (turnOn == null) return null;

    // Gundua taa gani
    int? relayIdx;
    String taaName = '';

    for (final entry in _taaMap.entries) {
      if (t.contains(entry.key)) {
        relayIdx = entry.value;
        taaName = entry.key;
        break;
      }
    }

    if (relayIdx == null) return null;

    final action = turnOn ? 'imewashwa' : 'imezimwa';
    final actionEn = turnOn ? 'turned on' : 'turned off';

    if (relayIdx == -1) {
      // Zote
      bool ok = true;
      for (int i = 0; i < 5; i++) {
        final r = await Esp32Service.setRelay(i, turnOn);
        if (!r) ok = false;
      }
      return VoiceResult(
        success: ok,
        message: ok ? 'Taa zote $action' : 'Hitilafu ya muunganiko',
      );
    } else {
      final ok = await Esp32Service.setRelay(relayIdx, turnOn);
      return VoiceResult(
        success: ok,
        message: ok ? '${_capitalize(taaName)} $action' : 'Hitilafu ya muunganiko',
      );
    }
  }

  // ── VOLUME ─────────────────────────────────────────────────
  static Future<VoiceResult?> _handleVolume(String t) async {
    bool isUp = _contains(t, ['ongeza', 'panda', 'increase', 'louder', 'up', 'juu']);
    bool isDown = _contains(t, ['punguza', 'shuka', 'decrease', 'lower', 'down', 'chini']);
    bool isMute = _contains(t, ['kimya', 'mute', 'nyamaza']);

    if (!isUp && !isDown && !isMute) return null;
    if (!_contains(t, ['sauti', 'volume', 'vol', 'sound'])) return null;

    // Ni TV gani
    bool isAzam = _contains(t, ['azam', 'decoder', 'satellite', 'setela']);
    bool isHisense = _contains(t, ['hisense', 'tv', 'televisheni']);

    // Steps — angalia namba kwenye maneno
    int steps = _extractNumber(t) ?? 3;
    if (steps > 20) steps = 20;

    if (isMute) {
      if (isAzam) await Esp32Service.sendAzam('AZ_MUTE');
      else await Esp32Service.sendHisense('MUTE');
      return VoiceResult(success: true, message: 'Kimya!');
    }

    final dir = isUp ? 'up' : 'down';
    final label = isUp ? 'imeongezwa' : 'imepunguzwa';

    if (isAzam) {
      await Esp32Service.volumeAzam(dir, steps);
    } else {
      // Default Hisense kama haijasemwa
      await Esp32Service.volumeHisense(dir, steps);
    }

    return VoiceResult(success: true, message: 'Sauti $label (x$steps)');
  }

  // ── CHANNEL ────────────────────────────────────────────────
  static Future<VoiceResult?> _handleChannel(String t) async {
    bool isUp = _contains(t, ['channel inayofuata', 'next channel', 'channel juu', 'channel up', 'ongeza channel']);
    bool isDown = _contains(t, ['channel iliyopita', 'prev channel', 'channel chini', 'channel down', 'punguza channel']);

    // Namba ya channel moja kwa moja
    int? chNum = _extractNumber(t);
    bool hasChannel = _contains(t, ['channel', 'kituo', 'namba']);

    if (!isUp && !isDown && (chNum == null || !hasChannel)) return null;

    bool isAzam = _contains(t, ['azam', 'decoder', 'satellite']);

    if (chNum != null && hasChannel) {
      // Nenda channel namba fulani
      final digits = chNum.toString().split('');
      for (final d in digits) {
        if (isAzam) {
          await Esp32Service.sendAzam('AZ_NUM_$d');
        } else {
          await Esp32Service.sendHisense('NUM_$d');
        }
        await Future.delayed(const Duration(milliseconds: 400));
      }
      return VoiceResult(success: true, message: 'Channel $chNum');
    }

    final dir = isUp ? 'up' : 'down';
    if (isAzam) {
      await Esp32Service.channelAzam(dir);
    } else {
      await Esp32Service.channelHisense(dir);
    }
    return VoiceResult(
      success: true,
      message: isUp ? 'Channel inayofuata' : 'Channel iliyopita',
    );
  }

  // ── POWER TV ───────────────────────────────────────────────
  static Future<VoiceResult?> _handlePower(String t) async {
    bool hasPower = _contains(t, ['washa tv', 'zima tv', 'turn on tv', 'turn off tv',
        'washa hisense', 'zima hisense', 'washa televisheni', 'zima televisheni']);
    if (!hasPower) return null;

    bool isAzam = _contains(t, ['azam', 'decoder']);
    if (isAzam) {
      await Esp32Service.sendAzam('AZ_STANDBY');
    } else {
      await Esp32Service.sendHisense('POWER');
    }
    return VoiceResult(success: true, message: 'TV imewashwa/zimwa');
  }

  // ── MUTE ───────────────────────────────────────────────────
  static Future<VoiceResult?> _handleMute(String t) async {
    if (!_contains(t, ['kimya', 'mute', 'nyamaza', 'silence'])) return null;
    bool isAzam = _contains(t, ['azam', 'decoder']);
    if (isAzam) {
      await Esp32Service.sendAzam('AZ_MUTE');
    } else {
      await Esp32Service.sendHisense('MUTE');
    }
    return VoiceResult(success: true, message: 'Kimya!');
  }

  // ── HELPERS ────────────────────────────────────────────────
  static bool _contains(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  static int? _extractNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    if (match != null) return int.tryParse(match.group(0)!);

    // Maneno ya namba
    const wordNums = {
      'moja': 1, 'one': 1,
      'mbili': 2, 'two': 2,
      'tatu': 3, 'three': 3,
      'nne': 4, 'four': 4,
      'tano': 5, 'five': 5,
      'kumi': 10, 'ten': 10,
    };
    for (final e in wordNums.entries) {
      if (text.contains(e.key)) return e.value;
    }
    return null;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
