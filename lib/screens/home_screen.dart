// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> _loads = [
    {'name': 'Sabufa',       'icon': Icons.speaker,         'emoji': '🔊'},
    {'name': 'TV',           'icon': Icons.tv,               'emoji': '📺'},
    {'name': 'Taa ya Nje',   'icon': Icons.lightbulb,        'emoji': '💡'},
    {'name': 'Taa Chumbani', 'icon': Icons.bed,              'emoji': '🛏️'},
    {'name': 'Taa Sebuleni', 'icon': Icons.chair,            'emoji': '🛋️'},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // HEADER
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('SMART HOME',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Color(0xFF00D4FF), letterSpacing: 2,
              )),
            Text(
              '${state.relayStates.where((s) => s).length}/5 ON',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ]),

          const SizedBox(height: 6),

          // ALL ON / ALL OFF
          Row(children: [
            Expanded(child: _quickBtn('Washa Zote', const Color(0xFF2ECC71), () async {
              HapticFeedback.mediumImpact();
              for (int i = 0; i < 5; i++) {
                await state.toggleRelay(i);
              }
            })),
            const SizedBox(width: 10),
            Expanded(child: _quickBtn('Zima Zote', const Color(0xFFFF3B3B), () async {
              HapticFeedback.mediumImpact();
              for (int i = 0; i < 5; i++) {
                await state.toggleRelay(i);
              }
            })),
          ]),

          const SizedBox(height: 16),

          // RELAY GRID
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 1.2,
              ),
              itemCount: 5,
              itemBuilder: (ctx, i) {
                final on = i < state.relayStates.length
                    ? state.relayStates[i]
                    : false;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    state.toggleRelay(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: on
                          ? const Color(0xFF0D2B1A)
                          : const Color(0xFF111318),
                      border: Border.all(
                        color: on
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFF252A35),
                        width: on ? 1.5 : 1,
                      ),
                      boxShadow: on ? [BoxShadow(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                        blurRadius: 16, spreadRadius: 2,
                      )] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_loads[i]['emoji'],
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(_loads[i]['name'],
                          style: TextStyle(
                            color: on
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600, fontSize: 13,
                          )),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: on
                                ? const Color(0xFF2ECC71).withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                          ),
                          child: Text(on ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: on
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFF444),
                            )),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _quickBtn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700,
              fontSize: 12, letterSpacing: 0.5))),
      ),
    );
}
