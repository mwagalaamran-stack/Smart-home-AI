// lib/screens/voice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/app_state.dart';
import '../services/voice_parser.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Mifano ya commands
  final List<String> _examples = [
    'Washa taa ya nje',
    'Zima taa zote',
    'Punguza sauti',
    'Ongeza sauti tano',
    'Washa TV',
    'Channel inayofuata',
    'Kimya azam',
    'Turn on bedroom light',
    'Decrease volume',
    'Channel 11',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initStt();
    _initTts();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => print('[STT] Error: $e'),
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('sw-KE');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) {
      _speak('Microphone haipatikani');
      return;
    }

    final state = context.read<AppState>();
    if (!state.isConnected) {
      _speak('Hakuna muunganiko na ESP32');
      return;
    }

    HapticFeedback.mediumImpact();
    state.setListening(true);
    state.setVoiceText('');

    await _stt.listen(
      localeId: 'sw_KE', // Kiswahili — itajaribu English pia kama haielewi
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      onResult: (result) async {
        final text = result.recognizedWords;
        state.setVoiceText(text);

        if (result.finalResult && text.isNotEmpty) {
          state.setListening(false);
          await _stt.stop();
          await _processCommand(text);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    context.read<AppState>().setListening(false);
  }

  Future<void> _processCommand(String text) async {
    HapticFeedback.lightImpact();
    final result = await VoiceParser.parse(text);
    context.read<AppState>().setActionResult(result.message, result.success);
    await _speak(result.message);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // CONNECTION STATUS
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: state.isConnected
                    ? const Color(0xFF0D2B1A)
                    : const Color(0xFF2A0808),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.isConnected
                      ? const Color(0xFF2ECC71)
                      : const Color(0xFFFF3B3B),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isConnected
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.isConnected ? 'ESP32 IMEUNGANISHWA' : 'HAKUNA MUUNGANIKO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: state.isConnected
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 32),

            // MIC BUTTON
            GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: () => _stopListening(),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) {
                  final scale = state.isListening ? _pulseAnim.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isListening
                            ? const Color(0xFF00D4FF).withOpacity(0.15)
                            : const Color(0xFF181C23),
                        border: Border.all(
                          color: state.isListening
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF252A35),
                          width: state.isListening ? 3 : 1.5,
                        ),
                        boxShadow: state.isListening
                            ? [BoxShadow(
                                color: const Color(0xFF00D4FF).withOpacity(0.3),
                                blurRadius: 30, spreadRadius: 5)]
                            : [],
                      ),
                      child: Icon(
                        state.isListening ? Icons.mic : Icons.mic_none,
                        color: state.isListening
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFF6B7280),
                        size: 50,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Text(
              state.isListening ? 'Sikiliza...' : 'Shikilia kusema',
              style: TextStyle(
                fontSize: 14,
                color: state.isListening
                    ? const Color(0xFF00D4FF)
                    : const Color(0xFF6B7280),
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 24),

            // VOICE TEXT
            if (state.lastVoiceText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF181C23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF252A35)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ulisema:', style: TextStyle(
                      fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('"${state.lastVoiceText}"',
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFFE8EAF0), fontStyle: FontStyle.italic)),
                ]),
              ),

            const SizedBox(height: 12),

            // ACTION RESULT
            if (state.lastActionMsg.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: state.lastActionSuccess
                      ? const Color(0xFF0D2B1A)
                      : const Color(0xFF2A0808),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.lastActionSuccess
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    state.lastActionSuccess ? Icons.check_circle : Icons.error,
                    color: state.lastActionSuccess
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.lastActionMsg,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: state.lastActionSuccess
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFFF3B3B),
                      ),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF252A35)),
            const SizedBox(height: 12),

            // EXAMPLES
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('MIFANO YA COMMANDS',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 2.8,
                  crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemCount: _examples.length,
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _processCommand(_examples[i]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF181C23),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF252A35)),
                    ),
                    child: Center(
                      child: Text(
                        _examples[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
