import 'package:flutter/material.dart';
import 'package:voip_station/splash.dart';

class MApp extends StatelessWidget {
  const MApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashPage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true
      ),
    );
  }
}
