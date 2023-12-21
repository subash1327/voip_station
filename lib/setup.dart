import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:direct_dialer/direct_dialer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voip_station/portal.dart';
import 'package:voip_station/widget/ping_widget.dart';

import 'core/consts.dart';
import 'core/local.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  TextEditingController station = TextEditingController();

  @override
  void initState() {
    station.text = Local.station;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Consts.appName),
        actions: const [
          PingWidget(),
          SizedBox(width: 16,)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: station,
              decoration: const InputDecoration(
                  labelText: 'Station',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16)
              ),
              onFieldSubmitted: (_) => setup(),
            ),
            const SizedBox(height: 16,),
            FilledButton(onPressed: setup, child: const Text('Submit')),
            const Spacer(),
            FilledButton.tonal(onPressed: () async {
              station.text = 'KwylZgIWpnYHP6DZFhJn';
              setup();
            }, child: const Text('Setup Default Station')),
            FilledButton.tonal(onPressed: () async {
              final res = await FirebaseFirestore.instance.collection('station').add({
                'name': station.text
              });
              station.text = res.id;
              setup();
            }, child: const Text('Setup New Station'))
          ],
        ),
      )
    );
  }
  setup(){
    Local.station = station.text;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ModeSelector()));
  }
}
Mode mode = Mode.dialer;

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mode'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: (){
                  mode = Mode.dialer;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DialPage()));
                },
                child: const Text('Dialer'),
              ),
              TextButton(
                onPressed: (){
                  mode = Mode.receiver;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DialPage()));
                },
                child: const Text('Receiver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


enum Mode {
  dialer, receiver
}

class DialPage extends StatefulWidget {
  const DialPage({super.key});

  @override
  State<DialPage> createState() => _DialPageState();
}

class _DialPageState extends State<DialPage> {
  final TextEditingController phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Consts.appName),
        actions: const [
          PingWidget(),
          SizedBox(width: 16,)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(child: Portal()),
            const SizedBox(height: 16,),
            TextFormField(
              controller: phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16)
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              maxLength: 10,
              onFieldSubmitted: add,
            ),
            const SizedBox(height: 16,),
            ElevatedButton.icon(
              onPressed: (){
                add(phone.text);
              },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ) ,
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call')
            )
          ],
        ),
      )
    );
  }
}

add(String phone) async {
  final collection = FirebaseFirestore.instance.collection('station').doc(Local.station).collection('call');
  await collection.add({
    'phone': phone,
    'time': Timestamp.now(),
    'station': Local.station,
    'new': true
  });
}

call(String number) async {
  final dialer = await DirectDialer.instance;
  return await dialer.dial(number);
}