import 'package:flutter/material.dart';
import 'package:voip_station/core/local.dart';
import 'package:voip_station/firebase.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Local.initialize();
  await FirebaseService.initialize();
  runApp(const MApp());
}
