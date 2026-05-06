import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'navigation/app_navigator.dart';
import 'screens/session/session_gate_screen.dart';

void main() {
  runApp(const VooApp());
}

class VooApp extends StatelessWidget {
  const VooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'VOO',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFF05051C),
        ),
        home: const SessionGateScreen(),
      ),
    );
  }
}