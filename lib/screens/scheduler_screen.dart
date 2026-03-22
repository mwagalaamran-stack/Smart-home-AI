// lib/screens/scheduler_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../services/app_state.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});
  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheduler = context.read<AppState>().scheduler;
    final schedules = scheduler.schedules;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: schedules.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _scheduleCard(schedules[i], scheduler),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00D4FF),
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.schedule, color: Color(0xFF252A35), size: 60),
      const SizedBox(height: 16),
      const Text('Hakuna schedule bado',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
      const SizedBox(height: 8),
      const Text('Bonyeza + kuongeza',
          style: TextStyle(color: Color(0xFF252A35), fontSize: 12)),
    ],
  ));

  Widget _scheduleCard(ScheduleItem s, scheduler) {
    final relayName = s.relayIndex == -1
        ? 'Zote'
        : ScheduleItem.relayNames[s.relayIndex];
    final action = s.turnOn ? 'WASHA' : 'ZIMA';
    final actionColor = s.turnOn
        ? const Color(0xFF2ECC71)
        : const Color(0xFFFF3B3B);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111318),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.enabled ? const Color(0xFF252A35) : const Color(0xFF1A1A1A),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [

          // TIME
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.timeString,
              style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: s.enabled ? const Color(0xFFE8EAF0) : const Color(0xFF444),
                fontFamily: 'monospace',
              )),
            Text(s.daysString,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),

          const SizedBox(width: 14),

          // INFO
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: s.enabled ? const Color(0xFFE8EAF0) : const Color(0xFF444),
              )),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: actionColor.withOpacity(0.3)),
                ),
                child: Text(action,
                  style: TextStyle(fontSize: 10, color: actionColor, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Text(relayName,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ]),
          ])),

          // CONTROLS
          Column(children: [
            Switch(
              value: s.enabled,
              activeColor: const Color(0xFF00D4FF),
              onChanged: (_) async {
                await scheduler.toggle(s.id);
                _refresh();
              },
            ),
            GestureDetector(
              onTap: () async {
                await scheduler.delete(s.id);
                _refresh();
              },
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFF444), size: 20),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111318),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddScheduleSheet(onSaved: _refresh),
    );
  }
}

// ── ADD SCHEDULE SHEET ─────────────────────────────────────────
class _AddScheduleSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddScheduleSheet({required this.onSaved});
  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  TimeOfDay _time = TimeOfDay.now();
  int _relayIndex = 2; // taa ya nje default
  bool _turnOn = true;
  List<bool> _days = List.filled(7, true);
  final _labelCtrl = TextEditingController(text: 'Schedule yangu');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // HEADER
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('SCHEDULE MPYA',
              style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w700,
                  fontSize: 16, letterSpacing: 1.5)),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              onPressed: () => Navigator.pop(context),
            ),
          ]),

          const SizedBox(height: 16),

          // LABEL
          _label('Jina'),
          TextField(
            controller: _labelCtrl,
            style: const TextStyle(color: Color(0xFFE8EAF0)),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFF181C23),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF252A35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF252A35)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TIME
          _label('Muda'),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF181C23),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF252A35)),
              ),
              child: Row(children: [
                const Icon(Icons.access_time, color: Color(0xFF00D4FF), size: 20),
                const SizedBox(width: 10),
                Text(_time.format(context),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: Color(0xFFE8EAF0), fontFamily: 'monospace')),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ACTION
          _label('Action'),
          Row(children: [
            Expanded(child: _actionBtn('WASHA', true)),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('ZIMA', false)),
          ]),

          const SizedBox(height: 16),

          // RELAY
          _label('Taa / Kifaa'),
          DropdownButtonFormField<int>(
            value: _relayIndex,
            dropdownColor: const Color(0xFF181C23),
            style: const TextStyle(color: Color(0xFFE8EAF0)),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFF181C23),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF252A35))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF252A35))),
            ),
            items: [
              ...List.generate(5, (i) => DropdownMenuItem(
                value: i,
                child: Text(ScheduleItem.relayNames[i]),
              )),
              const DropdownMenuItem(value: -1, child: Text('Zote (taa zote 5)')),
            ],
            onChanged: (v) => setState(() => _relayIndex = v!),
          ),

          const SizedBox(height: 16),

          // DAYS
          _label('Siku'),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) => GestureDetector(
              onTap: () => setState(() => _days[i] = !_days[i]),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _days[i]
                      ? const Color(0xFF00D4FF).withOpacity(0.2)
                      : const Color(0xFF181C23),
                  border: Border.all(
                    color: _days[i]
                        ? const Color(0xFF00D4FF)
                        : const Color(0xFF252A35),
                  ),
                ),
                child: Center(child: Text(
                  ScheduleItem.dayNames[i],
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: _days[i]
                        ? const Color(0xFF00D4FF)
                        : const Color(0xFF6B7280),
                  ),
                )),
              ),
            )),
          ),

          const SizedBox(height: 24),

          // SAVE
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: const Text('HIFADHI SCHEDULE',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.5)),
  );

  Widget _actionBtn(String label, bool value) => GestureDetector(
    onTap: () => setState(() => _turnOn = value),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _turnOn == value
            ? (value ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B)).withOpacity(0.15)
            : const Color(0xFF181C23),
        border: Border.all(
          color: _turnOn == value
              ? (value ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B))
              : const Color(0xFF252A35),
        ),
      ),
      child: Center(child: Text(label,
        style: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13,
          color: _turnOn == value
              ? (value ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B))
              : const Color(0xFF6B7280),
        ))),
    ),
  );

  Future<void> _save() async {
    final scheduler = context.read<AppState>().scheduler;
    final item = ScheduleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.isEmpty ? 'Schedule' : _labelCtrl.text,
      relayIndex: _relayIndex,
      turnOn: _turnOn,
      hour: _time.hour,
      minute: _time.minute,
      days: _days,
    );
    await scheduler.add(item);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}
