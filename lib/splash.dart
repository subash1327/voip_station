import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:voip_station/core/feb_rtc/entity.dart';
import 'package:voip_station/setup.dart';
import 'package:voip_station/web_app.dart';

import 'core/local.dart';
// KwylZgIWpnYHP6DZFhJn

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(kDebugMode){
        Local.station = 'KwylZgIWpnYHP6DZFhJn';
        Local.user = User(id: 'dialer');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WebApp()));
        return;
      }
      if(kIsWeb){
        Local.station = 'KwylZgIWpnYHP6DZFhJn';
        Local.user = User(id: 'dialer');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WebApp()));
      } else {
        Local.user = User(id: 'station');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupPage()));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}

