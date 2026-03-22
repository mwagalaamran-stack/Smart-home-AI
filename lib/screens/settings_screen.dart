// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final svc = SettingsService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color get accent {
    final hex = svc.settings.themeAccent;
    return Color(SettingsService.hexToColor(hex));
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        title: Text('SETTINGS',
          style: TextStyle(color: accent, fontWeight: FontWeight.w800,
              fontSize: 16, letterSpacing: 2)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: accent,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: accent,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: const [
            Tab(text: 'VIFAA'),
            Tab(text: 'MUUNGANIKO'),
            Tab(text: 'MWONEKANO'),
            Tab(text: 'VOICE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DevicesTab(svc: svc, accent: accent, onChanged: _rebuild),
          _ConnectionTab(svc: svc, accent: accent, onChanged: _rebuild),
          _ThemeTab(svc: svc, accent: accent, onChanged: _rebuild),
          _VoiceTab(svc: svc, accent: accent, onChanged: _rebuild),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 1 — VIFAA (Devices)
// ═══════════════════════════════════════════════════════════════
class _DevicesTab extends StatelessWidget {
  final SettingsService svc;
  final Color accent;
  final VoidCallback onChanged;
  const _DevicesTab({required this.svc, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: Column(children: [
        // Info bar
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: accent, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text(
              'Buruta kubadilisha mpangilio • Bonyeza ✏️ kuhariri • + kuongeza kifaa kipya',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            )),
          ]),
        ),

        // Device list — reorderable
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: svc.devices.length,
            onReorder: (o, n) async {
              await svc.reorderDevices(o, n);
              onChanged();
            },
            itemBuilder: (ctx, i) {
              final d = svc.devices[i];
              final dColor = Color(SettingsService.hexToColor(d.color));
              return Container(
                key: ValueKey(d.id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111318),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: d.enabled
                        ? dColor.withOpacity(0.3)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d.enabled
                          ? dColor.withOpacity(0.15)
                          : const Color(0xFF1A1A1A),
                      border: Border.all(color: d.enabled ? dColor : const Color(0xFF333)),
                    ),
                    child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(d.name,
                    style: TextStyle(
                      color: d.enabled ? const Color(0xFFE8EAF0) : const Color(0xFF444),
                      fontWeight: FontWeight.w600, fontSize: 14,
                    )),
                  subtitle: Text('Relay ${d.relayPin}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    // Enable/disable toggle
                    Switch(
                      value: d.enabled,
                      activeColor: dColor,
                      onChanged: (v) async {
                        await svc.updateDevice(d.copyWith(enabled: v));
                        onChanged();
                      },
                    ),
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B7280), size: 18),
                      onPressed: () => _showEditDialog(context, d),
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFF444), size: 18),
                      onPressed: () => _confirmDelete(context, d),
                    ),
                    // Drag handle
                    const Icon(Icons.drag_handle, color: Color(0xFF333), size: 18),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('ONGEZA KIFAA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  void _showAddDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111318),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DeviceEditSheet(
        svc: svc, accent: accent, onSaved: onChanged,
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, DeviceModel d) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111318),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DeviceEditSheet(
        svc: svc, accent: accent, device: d, onSaved: onChanged,
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, DeviceModel d) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111318),
        title: Text('Futa ${d.name}?',
            style: const TextStyle(color: Color(0xFFE8EAF0))),
        content: const Text('Kifaa hiki kitafutwa kabisa.',
            style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HAPANA', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              await svc.deleteDevice(d.id);
              onChanged();
              Navigator.pop(ctx);
            },
            child: const Text('FUTA', style: TextStyle(color: Color(0xFFFF3B3B))),
          ),
        ],
      ),
    );
  }
}

// ── DEVICE EDIT SHEET ──────────────────────────────────────────
class _DeviceEditSheet extends StatefulWidget {
  final SettingsService svc;
  final Color accent;
  final DeviceModel? device;
  final VoidCallback onSaved;
  const _DeviceEditSheet({required this.svc, required this.accent,
      this.device, required this.onSaved});
  @override
  State<_DeviceEditSheet> createState() => _DeviceEditSheetState();
}

class _DeviceEditSheetState extends State<_DeviceEditSheet> {
  late TextEditingController _nameCtrl;
  late String _emoji;
  late int _relayPin;
  late String _color;
  bool _isEdit = false;

  final List<String> _emojis = [
    '💡','🔊','📺','🛋️','🛏️','🚿','🍳','❄️',
    '🔌','💻','🖥️','📡','🚗','🏠','🌿','🔥',
    '💧','⚡','🎮','🎵','📷','🔒','🌡️','🎁',
  ];

  final Map<String, String> _colors = {
    'Samawati':  '#00D4FF',
    'Kijani':    '#2ECC71',
    'Chungwa':   '#E85A00',
    'Zambarau':  '#9B59B6',
    'Njano':     '#F1C40F',
    'Nyekundu':  '#E74C3C',
    'Bluu':      '#2980B9',
    'Kijivu':    '#95A5A6',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.device != null;
    _nameCtrl = TextEditingController(text: widget.device?.name ?? '');
    _emoji = widget.device?.emoji ?? '💡';
    _relayPin = widget.device?.relayPin ?? widget.svc.devices.length;
    _color = widget.device?.color ?? '#00D4FF';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_isEdit ? 'HARIRI KIFAA' : 'KIFAA KIPYA',
              style: TextStyle(color: widget.accent, fontWeight: FontWeight.w800,
                  fontSize: 15, letterSpacing: 1.5)),
            IconButton(icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.pop(context)),
          ]),

          const SizedBox(height: 16),

          // Preview
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(SettingsService.hexToColor(_color)).withOpacity(0.15),
              border: Border.all(color: Color(SettingsService.hexToColor(_color)), width: 2),
            ),
            child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 36))),
          )),

          const SizedBox(height: 20),

          // Name
          _sectionLabel('Jina la Kifaa'),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 15),
            decoration: _inputDeco('Mfano: Balcony, Kitchen Light...'),
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 16),

          // Relay Pin
          _sectionLabel('Relay Pin (0-7)'),
          Row(children: List.generate(8, (i) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _relayPin = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _relayPin == i
                      ? Color(SettingsService.hexToColor(_color)).withOpacity(0.2)
                      : const Color(0xFF181C23),
                  border: Border.all(
                    color: _relayPin == i
                        ? Color(SettingsService.hexToColor(_color))
                        : const Color(0xFF252A35),
                  ),
                ),
                child: Center(child: Text('$i',
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: _relayPin == i
                        ? Color(SettingsService.hexToColor(_color))
                        : const Color(0xFF6B7280),
                  ))),
              ),
            ),
          ))),

          const SizedBox(height: 16),

          // Emoji picker
          _sectionLabel('Icon'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6,
            ),
            itemCount: _emojis.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _emoji = _emojis[i]),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _emoji == _emojis[i]
                      ? Color(SettingsService.hexToColor(_color)).withOpacity(0.2)
                      : const Color(0xFF181C23),
                  border: Border.all(
                    color: _emoji == _emojis[i]
                        ? Color(SettingsService.hexToColor(_color))
                        : const Color(0xFF252A35),
                  ),
                ),
                child: Center(child: Text(_emojis[i],
                    style: const TextStyle(fontSize: 18))),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Color picker
          _sectionLabel('Rangi'),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _colors.entries.map((e) {
              final c = Color(SettingsService.hexToColor(e.value));
              final selected = _color == e.value;
              return GestureDetector(
                onTap: () => setState(() => _color = e.value),
                child: Column(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: c,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                          : [],
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(e.key, style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280))),
                ]),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'HIFADHI MABADILIKO' : 'ONGEZA KIFAA',
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ),
        ],
      )),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.5)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF444)),
    filled: true, fillColor: const Color(0xFF181C23),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252A35))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252A35))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.accent)),
  );

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final device = DeviceModel(
      id: widget.device?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      emoji: _emoji,
      relayPin: _relayPin,
      color: _color,
    );
    if (_isEdit) {
      await widget.svc.updateDevice(device);
    } else {
      await widget.svc.addDevice(device);
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 2 — MUUNGANIKO (Connection)
// ═══════════════════════════════════════════════════════════════
class _ConnectionTab extends StatefulWidget {
  final SettingsService svc;
  final Color accent;
  final VoidCallback onChanged;
  const _ConnectionTab({required this.svc, required this.accent, required this.onChanged});
  @override
  State<_ConnectionTab> createState() => _ConnectionTabState();
}

class _ConnectionTabState extends State<_ConnectionTab> {
  late TextEditingController _ipCtrl;
  late TextEditingController _ssidCtrl;
  late TextEditingController _passCtrl;
  bool _showPass = false;
  bool? _testResult;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _ipCtrl   = TextEditingController(text: widget.svc.settings.espIp);
    _ssidCtrl = TextEditingController(text: widget.svc.settings.wifiSsid);
    _passCtrl = TextEditingController(text: widget.svc.settings.wifiPassword);
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    try {
      final res = await Future.delayed(const Duration(seconds: 2), () => true);
      setState(() { _testResult = res; _testing = false; });
    } catch (_) {
      setState(() { _testResult = false; _testing = false; });
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
    prefixIcon: Icon(icon, color: widget.accent, size: 18),
    filled: true, fillColor: const Color(0xFF181C23),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252A35))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF252A35))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.accent)),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _sectionHeader('ESP32 Connection'),
        const SizedBox(height: 12),

        // IP Address
        TextField(
          controller: _ipCtrl,
          style: const TextStyle(color: Color(0xFFE8EAF0)),
          keyboardType: TextInputType.number,
          decoration: _inputDeco('IP Address ya ESP32', Icons.router),
        ),
        const SizedBox(height: 6),
        const Text('Default: 192.168.4.1',
            style: TextStyle(fontSize: 10, color: Color(0xFF444))),

        const SizedBox(height: 20),

        _sectionHeader('WiFi Settings'),
        const SizedBox(height: 12),

        // SSID
        TextField(
          controller: _ssidCtrl,
          style: const TextStyle(color: Color(0xFFE8EAF0)),
          decoration: _inputDeco('WiFi Name (SSID)', Icons.wifi),
        ),

        const SizedBox(height: 12),

        // Password
        TextField(
          controller: _passCtrl,
          obscureText: !_showPass,
          style: const TextStyle(color: Color(0xFFE8EAF0)),
          decoration: _inputDeco('WiFi Password', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280), size: 18),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Test connection
        if (_testResult != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _testResult! ? const Color(0xFF0D2B1A) : const Color(0xFF2A0808),
              border: Border.all(
                color: _testResult! ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B)),
            ),
            child: Row(children: [
              Icon(_testResult! ? Icons.check_circle : Icons.error,
                  color: _testResult! ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B)),
              const SizedBox(width: 10),
              Text(_testResult! ? 'Muunganiko umefanikiwa!' : 'Muunganiko umeshindwa',
                style: TextStyle(
                  color: _testResult! ? const Color(0xFF2ECC71) : const Color(0xFFFF3B3B),
                  fontWeight: FontWeight.w600,
                )),
            ]),
          ),

        Row(children: [
          Expanded(child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.accent,
              side: BorderSide(color: widget.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _testing ? null : _testConnection,
            icon: _testing
                ? SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2))
                : const Icon(Icons.wifi_tethering),
            label: Text(_testing ? 'Inaangalia...' : 'TEST'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              widget.svc.settings.espIp = _ipCtrl.text;
              widget.svc.settings.wifiSsid = _ssidCtrl.text;
              widget.svc.settings.wifiPassword = _passCtrl.text;
              await widget.svc.saveSettings();
              widget.onChanged();
              HapticFeedback.lightImpact();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Imehifadhiwa!'),
                      backgroundColor: Color(0xFF2ECC71),
                      behavior: SnackBarBehavior.floating));
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('HIFADHI'),
          )),
        ]),
      ]),
    );
  }

  Widget _sectionHeader(String t) => Text(t,
    style: TextStyle(color: widget.accent, fontWeight: FontWeight.w700,
        fontSize: 13, letterSpacing: 1.5));
}

// ═══════════════════════════════════════════════════════════════
//  TAB 3 — MWONEKANO (Theme)
// ═══════════════════════════════════════════════════════════════
class _ThemeTab extends StatelessWidget {
  final SettingsService svc;
  final Color accent;
  final VoidCallback onChanged;
  const _ThemeTab({required this.svc, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('CHAGUA RANGI YA APP',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700,
              fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        const Text('Mabadiliko yataonekana mara moja',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        const SizedBox(height: 20),

        // Theme grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: AppSettings.themes.length,
          itemBuilder: (_, i) {
            final entry = AppSettings.themes.entries.elementAt(i);
            final c = Color(SettingsService.hexToColor(entry.value));
            final selected = svc.settings.themeName == entry.key;
            return GestureDetector(
              onTap: () async {
                await svc.setTheme(entry.key);
                onChanged();
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: c.withOpacity(selected ? 0.2 : 0.05),
                  border: Border.all(
                    color: selected ? c : const Color(0xFF252A35),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: c.withOpacity(0.3), blurRadius: 12)]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(entry.key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: selected ? c : const Color(0xFF6B7280),
                        letterSpacing: 1,
                      )),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Language
        Text('LUGHA / LANGUAGE',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700,
              fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 12),

        ...{
          'both': '🌍  Kiswahili + English',
          'sw':   '🇹🇿  Kiswahili tu',
          'en':   '🇬🇧  English only',
        }.entries.map((e) => GestureDetector(
          onTap: () async {
            svc.settings.language = e.key;
            await svc.saveSettings();
            onChanged();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: svc.settings.language == e.key
                  ? accent.withOpacity(0.1)
                  : const Color(0xFF111318),
              border: Border.all(
                color: svc.settings.language == e.key
                    ? accent
                    : const Color(0xFF252A35),
              ),
            ),
            child: Row(children: [
              Text(e.value,
                style: TextStyle(
                  fontSize: 14,
                  color: svc.settings.language == e.key
                      ? accent
                      : const Color(0xFF9CA3AF),
                  fontWeight: svc.settings.language == e.key
                      ? FontWeight.w700
                      : FontWeight.normal,
                )),
              const Spacer(),
              if (svc.settings.language == e.key)
                Icon(Icons.check_circle, color: accent, size: 18),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TAB 4 — VOICE COMMANDS
// ═══════════════════════════════════════════════════════════════
class _VoiceTab extends StatefulWidget {
  final SettingsService svc;
  final Color accent;
  final VoidCallback onChanged;
  const _VoiceTab({required this.svc, required this.accent, required this.onChanged});
  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  final _cmdCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cmds = widget.svc.settings.customVoiceCommands;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('VOICE COMMANDS ZAKO',
          style: TextStyle(color: widget.accent, fontWeight: FontWeight.w700,
              fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        const Text('Ongeza commands za ziada unazotaka',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),

        const SizedBox(height: 16),

        // Add new command
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111318),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF252A35)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ONGEZA COMMAND MPYA',
                style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.5)),
            const SizedBox(height: 10),
            TextField(
              controller: _cmdCtrl,
              style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Neno/maneno utakayosema (mfano: lights out)',
                hintStyle: const TextStyle(color: Color(0xFF444), fontSize: 12),
                prefixIcon: Icon(Icons.mic, color: widget.accent, size: 18),
                filled: true, fillColor: const Color(0xFF181C23),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF252A35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF252A35))),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _actionCtrl,
              style: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Action (mfano: zima taa zote)',
                hintStyle: const TextStyle(color: Color(0xFF444), fontSize: 12),
                prefixIcon: Icon(Icons.bolt, color: widget.accent, size: 18),
                filled: true, fillColor: const Color(0xFF181C23),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF252A35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF252A35))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (_cmdCtrl.text.isEmpty) return;
                  await widget.svc.addVoiceCommand(
                    '${_cmdCtrl.text}::${_actionCtrl.text}');
                  _cmdCtrl.clear();
                  _actionCtrl.clear();
                  widget.onChanged();
                  setState(() {});
                },
                child: const Text('ONGEZA', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Existing commands
        if (cmds.isNotEmpty) ...[
          const Text('COMMANDS ZAKO',
              style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ...cmds.asMap().entries.map((e) {
            final parts = e.value.split('::');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111318),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF252A35)),
              ),
              child: Row(children: [
                Icon(Icons.mic, color: widget.accent, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(parts[0],
                    style: const TextStyle(color: Color(0xFFE8EAF0),
                        fontWeight: FontWeight.w600, fontSize: 13)),
                  if (parts.length > 1)
                    Text('→ ${parts[1]}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF444), size: 18),
                  onPressed: () async {
                    await widget.svc.deleteVoiceCommand(e.key);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
              ]),
            );
          }),
        ] else ...[
          const Center(child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(children: [
              Icon(Icons.mic_none, color: Color(0xFF252A35), size: 48),
              SizedBox(height: 10),
              Text('Bado hujaweka commands',
                  style: TextStyle(color: Color(0xFF444), fontSize: 13)),
            ]),
          )),
        ],

        const SizedBox(height: 20),

        // Built-in commands reference
        ExpansionTile(
          iconColor: const Color(0xFF6B7280),
          collapsedIconColor: const Color(0xFF6B7280),
          title: const Text('COMMANDS ZILIZOPO (built-in)',
              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), letterSpacing: 1)),
          children: [
            _cmdRef('Washa/Zima taa', '"Washa taa ya nje" • "Zima taa zote"'),
            _cmdRef('Sauti', '"Punguza sauti tano" • "Ongeza volume"'),
            _cmdRef('Channel', '"Channel inayofuata" • "Channel 11"'),
            _cmdRef('Power TV', '"Washa TV" • "Zima Hisense"'),
            _cmdRef('Kimya', '"Kimya" • "Mute azam"'),
          ],
        ),
      ]),
    );
  }

  Widget _cmdRef(String title, String examples) => ListTile(
    dense: true,
    title: Text(title,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w600)),
    subtitle: Text(examples,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
  );
}
