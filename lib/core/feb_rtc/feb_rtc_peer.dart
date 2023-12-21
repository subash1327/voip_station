import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'entity.dart';

class FebRtcPeer extends ValueNotifier<FebRtcPeerValue> {
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCVideoRenderer renderer = RTCVideoRenderer();

  RTCPeerConnection? rtcPeerConnection;
  VoidCallback? onConnected, onStreamChanged;
  Function(RTCPeerConnectionState)? onConnectionStateChanged;
  Function(RTCIceCandidate) onIceCandidate;
  Function(RTCPeerConnection)? onRenegotiationNeeded;

  final FebRtcPeerConfig initialConfig;

  FebRtcPeer(
      {required this.localStream,
      this.onConnected,
        required this.initialConfig,
        required this.onRenegotiationNeeded,
      required this.onIceCandidate,
      this.onConnectionStateChanged})
      : super(FebRtcPeerValue(config: initialConfig));

  final Map<String, dynamic> configuration = {
    'sdpSemantics': 'plan-b',
      'iceServers': [{
        'urls': [
          'stun:webturn.focus.ind.in:443',
          'stun:webturn.focus.ind.in:3478'
        ]
      },
        {
          'urls': [
            'turn:webturn.focus.ind.in:443',
            'turn:webturn.focus.ind.in:3478'
          ],
          "username":"admin",
          "password":"admin112",
          "credential":"admin112",
          "maxRatekbps":"4000"
        }]
  };
  final Map<String, dynamic> loopbackConstraints = {
    "mandatory": {},
    "optional": [
      {"DtlsSrtpKeyAgreement": true},
    ],
  };

  late final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
      // "OfferToReceiveAudio": value.config.voice,
      // "OfferToReceiveVideo": value.config.voice,
    },
    "optional": [],
  };

  Future<void> listen() async {
    final List<RTCRtpReceiver>? receivers = await rtcPeerConnection?.getReceivers();
    for(final receiver in receivers ?? <RTCRtpReceiver>[]){
      if(receiver.track?.kind == 'audio'){
        List<StatsReport>? stats = await rtcPeerConnection?.getStats(receiver.track);
        for(final stat in stats ?? <StatsReport>[]){
          final audioLevel = stat.values['audioLevel'];
          if(audioLevel != null){
            final v = double.tryParse('$audioLevel') ?? 0.0;
            if(v > 0.1){
              value.config.amplitude = AmplitudeData(
                  updatedAt: DateTime.now().toIso8601String(),
                  amplitude: v
              );
              notifyListeners();
            }
          }
        }
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    listen();
  }

  Future<void> start() async {
    try{
      rtcPeerConnection =
      await createPeerConnection(configuration, loopbackConstraints);
      if (rtcPeerConnection?.getConfiguration['sdpSemantics'] == 'plan-b') {
        if(localStream != null) {
          rtcPeerConnection!.addStream(localStream!);
        }
      } else {
        if(!kIsWeb){
          final res = localStream?.getTracks();
          for (final e in res ?? []) {
            rtcPeerConnection!.addTrack(e);
          }
        } else {
          print('running plan-b');
          if(localStream != null){
            rtcPeerConnection!.addStream(localStream!);
          }
        }
      }

      rtcPeerConnection!.onAddTrack = _onAddTrack;
      rtcPeerConnection!.onRemoveTrack = _onRemoveTrack;
      rtcPeerConnection!.onAddStream = _onAddStream;
      rtcPeerConnection!.onRemoveStream = _onRemoveStream;
      rtcPeerConnection!.onRenegotiationNeeded = (){
        renogotiate();
      };
      rtcPeerConnection!.onIceCandidate = (candidate) {
        onIceCandidate.call(candidate);
        onConnectionStateChanged?.call(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
        notifyListeners();
      };
      rtcPeerConnection!.onConnectionState = onConnectionStateChanged;
      await renderer.initialize();
      onConnected?.call();
      notifyListeners();
      listen();
    } catch (e){
      print('error: Future<void> start(){}');
      print(e);
    }
  }

  renogotiate() async {
    try{

    } catch(e){
      print(e);
    }
  }

  updateStream(MediaStream stream) async {
    try{
      // rtcPeerConnection!.getRemoteStreams().clear();
      // rtcPeerConnection!.addStream(stream);

      (await rtcPeerConnection?.senders)?.forEach((sender) {
        if (sender.track!.kind == 'video') {
          sender.replaceTrack(stream.getVideoTracks()[0]);
        }
      });

      localStream = stream;
    } catch(e){
      print(e);
    }

  }

  void _onAddTrack(MediaStream stream, MediaStreamTrack track) {
    remoteStream = stream;
    renderer.srcObject = stream;
    onStreamChanged?.call();
    notifyListeners();
  }

  void _onRemoveTrack(MediaStream stream, MediaStreamTrack track) {
    remoteStream = null;
    notifyListeners();
  }

  void _onAddStream(MediaStream stream) {
    remoteStream = stream;
    renderer.srcObject = stream;
    onStreamChanged?.call();
    notifyListeners();
  }

  void _onRemoveStream(MediaStream stream) {
    remoteStream = null;
  }


  Future<RTCSessionDescription?> createOffer() async {
    try {
      final RTCSessionDescription sdp =
          await rtcPeerConnection!.createOffer(offerSdpConstraints);
      await rtcPeerConnection!.setLocalDescription(sdp);
      return sdp;
    } catch (error) {
      print(error);
    }
    return null;
  }

  int retry = 0;
  int maxRetry = 7;

  Future<void> setOfferSdp(RTCSessionDescription sdp) async {
    if (rtcPeerConnection != null) {
      try{
        await rtcPeerConnection!.setRemoteDescription(sdp);
      } catch(e){
        retry++;
        await Future.delayed(const Duration(seconds: 1));
        if(retry > maxRetry){
          return;
        }
        await start();
      }
    }
  }
  Future<void> setAnswerSdp(RTCSessionDescription sdp) async {
    if (rtcPeerConnection != null) {
      try{
        await rtcPeerConnection!.setRemoteDescription(sdp);
        onStreamChanged?.call();
        notifyListeners();
      } catch(e){
        print(e.toString());
        retry++;
        await Future.delayed(const Duration(seconds: 1));
        if(retry > maxRetry){
          return;
        }
        await start();
      }
    }
  }

  Future<RTCSessionDescription?> createAnswer() async {
    final RTCSessionDescription? sdp =
        await rtcPeerConnection?.createAnswer(offerSdpConstraints);
    if(sdp == null){
      return null;
    }
    await rtcPeerConnection!.setLocalDescription(sdp);
    return sdp;
  }



  Future<void> setCandidate(RTCIceCandidate candidate) async {
    if (rtcPeerConnection != null) {
      await rtcPeerConnection!.addCandidate(candidate);
    }
  }

  Future close() async {
    if (rtcPeerConnection != null) {
      await rtcPeerConnection!.close();
      rtcPeerConnection = null;
    }
    await renderer.dispose();
    await remoteStream?.dispose();
    remoteStream = null;
    return;
  }
}

class FebRtcPeerValue {
  FebRtcPeerConfig config;
  FebRtcPeerValue({required this.config});
}
