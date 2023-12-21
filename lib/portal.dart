import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voip_station/core/feb_rtc/feb_rtc.dart';

import 'core/local.dart';
import 'setup.dart';

class Portal extends StatefulWidget {
  const Portal({super.key});

  @override
  State<Portal> createState() => _PortalState();
}

class _PortalState extends State<Portal> {
  final FebRtcSdk sdk = FebRtcSdk(
    socketUrl: 'https://focus.ind.in', roomId: Local.station,
    userId: '${Local.user?.id}',
    video: false,
    voice: true
  );

  final collection = FirebaseFirestore.instance.collection('station').doc(Local.station).collection('call');
  @override
  void initState() {
    collection.where('new', isEqualTo: true).snapshots().listen((e) async {
      if(e.docChanges.isNotEmpty){
        final doc = e.docChanges.first.doc;
        final data = doc.data();
        if(data is Map<String, dynamic>){
          final phone = data['phone'];
          if(phone is String){
            if(mode == Mode.dialer){
              await call(phone);
              await doc.reference.update({
                'new': false
              });
            }


          }
        }
      }
    });
    if(mode == Mode.receiver) {
      sdk.join();
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      child: StreamBuilder(
        stream: collection.orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length ?? 0,
              itemBuilder: (context, index) {
                DocumentSnapshot? ds = snapshot.data?.docs[index];
                Timestamp? time;
                try{
                  time = ds?['time'] as Timestamp?;
                } catch (_){}
                return ListTile(
                  title: Text(ds?['phone'] ?? ''),
                  subtitle: time != null ? Text(time.toDate().toIso8601String()) : null,
                  style: ListTileStyle.drawer,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.phone_rounded),
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
