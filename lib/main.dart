// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'screens/voice_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load settings na devices kabla ya app kuanza
  await SettingsService().load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0C10),
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartHomeApp(),
    ),
  );
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0C10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          surface: Color(0xFF111318),
        ),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    VoiceScreen(),
    SchedulerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        elevation: 0,
        titleSpacing: 16,
        title: Consumer<AppState>(
          builder: (_, state, __) => Row(children: [
            // Logo
            RichText(text: const TextSpan(children: [
              TextSpan(text: 'SMART ',
                style: TextStyle(color: Color(0xFF00D4FF), fontSize: 17,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
              TextSpan(text: 'HOME',
                style: TextStyle(color: Color(0xFFE8EAF0), fontSize: 17,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
            ])),
            const Spacer(),
            // Connection badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: state.isConnected
                    ? const Color(0xFF2ECC71).withOpacity(0.1)
                    : const Color(0xFFFF3B3B).withOpacity(0.1),
                border: Border.all(
                  color: state.isConnected
                      ? const Color(0xFF2ECC71).withOpacity(0.4)
                      : const Color(0xFFFF3B3B).withOpacity(0.4),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isConnected
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  state.isConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                    color: state.isConnected
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1A1E26)),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F14),
          border: Border(top: BorderSide(color: Color(0xFF1A1E26))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00D4FF).withOpacity(0.15),
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00D4FF)),
              label: 'HOME',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none),
              selectedIcon: Icon(Icons.mic, color: Color(0xFF00D4FF)),
              label: 'VOICE',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule, color: Color(0xFF00D4FF)),
              label: 'SCHEDULE',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF00D4FF)),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
