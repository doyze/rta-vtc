import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RtaVtcApp());
}

class RtaVtcApp extends StatelessWidget {
  const RtaVtcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RTA VTC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          primaryContainer: const Color(0xFFE8F5E9),
        ),
        useMaterial3: true,
        fontFamily: 'NotoSansThai',
      ),
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
