import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/feb_rtc/feb_rtc_sdk.dart';
import 'core/local.dart';
import 'setup.dart';

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  final FebRtcSdk sdk = FebRtcSdk(
      socketUrl: 'https://focus.ind.in', roomId: Local.station,
      userId: '${Local.user?.id}',
      video: false,
      voice: true
  );
  String phone = '';

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(kIsWeb){
        final base = Uri.base;
        setState(() {
          phone = base.queryParameters['phone'] ?? '8610346904';
        });
        Local.station = base.queryParameters['station'] ?? Local.station;
        sdk.join();
        add(phone);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  ValueListenableBuilder(
      valueListenable: sdk,
      builder: (context, value, child) {
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(32),
                height: 80,
                  child: const FittedBox(child: CircleAvatar(child: Icon(Icons.person_rounded)))),
              Text(phone, style: Theme.of(context).textTheme.headlineLarge,),
              const Spacer(),
              const Row(),
              if(value.voice) ...[
                IconButton(onPressed: (){
                  sdk.toggleAudio(false);
                }, icon: const Icon(Icons.mic_off)),
                Text('Mute', style: Theme.of(context).textTheme.labelMedium,),
              ] else ...[
                IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: (){
                  sdk.toggleAudio(true);
                }, icon: const Icon(Icons.mic, color: Colors.white,)),
                Text('Unmute', style: Theme.of(context).textTheme.labelMedium,),
              ],
              Padding(
                padding: const EdgeInsets.all(32),
                child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      elevation: 8,
                      shadowColor: Colors.red.shade800,
                    ),
                    iconSize: 32,
                    onPressed: (){
                      sdk.leave();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CallEndedPage()));
                    }, icon: const Icon(Icons.call_end_rounded, color: Colors.white)),
              )
            ],
          ),
        );
      }
    );
  }
}



class CallEndedPage extends StatelessWidget {
  const CallEndedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AlertDialog(
        title: Text('Call Ended'),
        content: Text('The call has ended.'),
      ),
    );
  }
}
