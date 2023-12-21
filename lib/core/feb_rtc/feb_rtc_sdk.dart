import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:voip_station/core/consts.dart';
import 'package:voip_station/core/local.dart';
import 'package:voip_station/setup.dart';
import 'entity.dart';
import 'feb_rtc_peer.dart';
import 'replay_kit.dart';
import 'package:wakelock/wakelock.dart';
import 'message_payload.dart';
import 'payload_data.dart';
import 'socket_events.dart';
import 'socket_io_transport.dart';

class FebRtcSdk extends ValueNotifier<FebRtcSdkValue> {
  final String socketUrl, roomId, userId;
  late final SocketIOTransport transporter;
  final bool voice, video;
  final Function? onStreamChanged;
  final Function(User)? onUserJoined;
  final Function(User)? onUserLeft;
  final Function(User)? onKicked;
  final Function(String? userId, String? reaction)? onReaction;

  FebRtcSdk(
      {required this.socketUrl,
      required this.roomId,
      this.onUserJoined,
      this.onUserLeft,
      this.onKicked,
      required this.userId,
      this.voice = false,
      this.onReaction,
      this.video = false,
      this.onStreamChanged})
      : super(FebRtcSdkValue(voice: voice, video: video, userId: userId)) {
    transporter = SocketIOTransport(
        url: '$socketUrl?id=$roomId&userid=$userId',
        onMessage: onMessage,
        onConnectStateChanged: onConnectStateChanged,
        onOpen: () {
          joinSignal();
        });
    setDefaultAudioOutput();
    navigator.mediaDevices.ondevicechange = (event) {
      setDefaultAudioOutput();
    };
    Wakelock.enable();
  }

  setDefaultAudioOutput() async {
    // if(destroyed) return;
    await Future.delayed(const Duration(seconds: 3));
    final devices = await navigator.mediaDevices.enumerateDevices();
    for(final e in devices){
      if(e.kind == 'audiooutput'){
        final label = e.label.toLowerCase();
        if(label.contains('speaker')){
          Helper.selectAudioOutput(e.deviceId);
          // audioOut.value = e.deviceId;
          // audioOut.notifyListeners();
          continue;
        }
        continue;
      }
    }
  }

  joinSignal(){
    sendMessage(FebRTCEvents.joinRoom, {
      'name': 'system',
      'userId': userId,
      'config': value.config.toJson(),
    });
  }

  bool joined = false;
  join([bool empty = false]) async {
    await transporter.connect();
    await FebRtcSdk.startForegroundService();
    try {
      await initStreams(empty);
    } catch (_) {}
    joined = true;
    return;
  }

  initStreams([bool empty = false]) async {
    value.stream = await FebRtcSdk.getUserMedia(audio: voice, video: video, empty: empty);
    value.voice = voice;
    value.video = video;
    value.screen = false;
    value.face = false;
    onStreamChanged?.call();
    notifyListeners();
    setDefaultAudioOutput();
    return;
  }

  static initialize() async {
    if (WebRTC.platformIsDesktop) {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    }
    await startForegroundService();
    await Future.delayed(const Duration(milliseconds: 1000));
    await stopForegroundService();
    return;
  }

  static Future<bool> startForegroundService() async {

    try {
      if(WebRTC.platformIsAndroid) {
        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: Consts.appName,
          notificationText: '${Consts.appName} is running in background',
          notificationImportance: AndroidNotificationImportance.Default,
        );
        await FlutterBackground.initialize(androidConfig: androidConfig);
        await Future.delayed(const Duration(milliseconds: 500));
        return await FlutterBackground.enableBackgroundExecution();
      } else {
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopForegroundService() async {
    try {
      if(FlutterBackground.isBackgroundExecutionEnabled && WebRTC.platformIsAndroid) {
        await FlutterBackground.disableBackgroundExecution();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> presentScreen() async {
    // await stopStream();
    ReplayKitChannel.startReplayKit();
    final Map<String, dynamic> constraints = {'video': true, 'audio': false};
    if(!kIsWeb && Platform.isIOS) {
      constraints['video'] = {
        'deviceId': 'broadcast'
      };
      constraints.remove('audio');
      if (kDebugMode) {
        print('iOS: $constraints');
      }
    }
    final res = await navigator.mediaDevices
        .getDisplayMedia(constraints);
    final tracks = res.getVideoTracks();
    if (tracks.isNotEmpty) {
      print(res.id);
      // await removeAllVideo();

      value.stream = res;

      print(tracks.length);
      updateStreams();
      value.screen = true;
      value.silence = false;
      value.stopped = false;
      onStreamChanged?.call();
      notifyListeners();
      onConfigChanged();
      renegotiateAll();
      // if(MApp.context.mounted){
      //   MApp.context.showSnackBar('Screen sharing started');
      // }
      return;
    }
  }

  renegotiateAll(){
    if(!joined) return;
    joinSignal();
    // for(final e in value.connections.values){
    //   e.renogotiate();
    // }
  }

  Future<void> updateStreams() async {
    for (final e in value.connections.values) {
      if (e.rtcPeerConnection != null) {
        e.updateStream(value.stream!);
      }
    }
  }

  Future<void> stopPresenting() async {
    await stopStream();
    removeAllVideo();

    if (value.video) {
      final stream =
          await FebRtcSdk.getUserMedia(audio: value.voice, video: value.video);

      value.stream = stream;
      updateStreams();
      onStreamChanged?.call();
    } else {
      value.video = true;
      final stream =
      await FebRtcSdk.getUserMedia(audio: value.voice, video: value.video);

      value.stream = stream;
      updateStreams();
      onStreamChanged?.call();
      await Future.delayed(const Duration(milliseconds: 1000));
      toggleVideo();
    }
    value.screen = false;
    value.silence = false;
    value.stopped = true;
    onStreamChanged?.call();
    notifyListeners();
    onConfigChanged();
    renegotiateAll();
    // if(MApp.context.mounted){
    //   MApp.context.showSnackBar('Screen sharing stopped');
    // }
    return;
  }

  void switchCamera() {
    if (value.stream != null) {
      if (!value.video) {
        toggleVideo();
      }
      final videoTrack = value.stream!.getVideoTracks()[0];
      value.face = !value.face;
      Helper.switchCamera(videoTrack);
    }
    notifyListeners();
    onConfigChanged();
    onStreamChanged?.call();
  }

  Future<void> removeAllVideo() async {
    try {
      final videoTrack = value.stream!.getVideoTracks();
      for (final e in videoTrack) {
        await e.stop();
      }
      if (videoTrack.isNotEmpty) {
        value.stream!.removeTrack(videoTrack[0]);
      }
      return;
    } catch (e) {
      print(e);
    }
  }

  void raiseHand() {
    value.hand = !value.hand;
    notifyListeners();
    onConfigChanged();
  }

  void toggleVideo() async {
    // if(needCamStart){
    //   needCamStart = false;
    //   startCamera();
    //   return true;
    // }
    if (value.stream != null) {
      final tracks = value.stream!.getVideoTracks();
      MediaStreamTrack? video;
      if (tracks.isNotEmpty) {
        video = tracks.first;
      } else {
        await stopStream();
        final stream = await FebRtcSdk.getUserMedia(audio: voice, video: true);
        value.stream = stream;
        updateStreams();
        onStreamChanged?.call();

        // if (stream.getVideoTracks().isNotEmpty) {
        //   video = stream.getVideoTracks().first;
        //   value.stream!.addTrack(video);
        // }
      }
      final videoTrack = video;

      if(tracks.isNotEmpty){
        final bool? videoEnabled = videoTrack?.enabled = !(videoTrack.enabled);
        value.video = videoEnabled ?? false;
      } else {
        value.video = true;
      }

    }
    value.silence = true;
    value.stopped = false;
    value.screen = false;
    notifyListeners();
    onConfigChanged();
    onStreamChanged?.call();
    renegotiateAll();
  }

  void toggleAudio([bool? force]) async {
    if (value.stream != null) {
      final audioTracks = value.stream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final audioTrack = audioTracks.first;
        if (force != null) {
          audioTrack.enabled = force;
          value.voice = force;
        } else {
          final bool audioEnabled = audioTrack.enabled = !audioTrack.enabled;
          value.voice = audioEnabled;
        }
      } else {
        value.voice = !value.voice;

        final tracks = await getAudioTrack();
        if (tracks.isNotEmpty) {
          print(tracks);
          value.stream?.addTrack(tracks.first);
        }
      }
    } else {
      value.voice = !value.voice;
      value.stream = await FebRtcSdk.getUserMedia(audio: true, video: false);
      broadcast(FebRTCEvents.negotiate, {
        'userId': value.userId,
        'otherUserId': value.userId,
      });
    }
    notifyListeners();
    onConfigChanged();
    onStreamChanged?.call();
  }

  onMessage(data) async {
    final payload = MessagePayload.fromJson(jsonDecode(data));
    switch (payload.type) {
      case FebRTCEvents.joinedRoom:
        value.joined = true;
        notifyListeners();
        break;
      case FebRTCEvents.userJoined:
        await Future.delayed(const Duration(seconds: 1));
        final data = payload.data;
        final config = data?['config'];
        if (config != null) {
          final user = config?['user'];
          if (user != null) {
            onUserJoined?.call(User.fromJson(user));
          }
        }

        final u = UserJoinedData.fromJson(payload.data);

        await userJoined(u);
        break;
      case FebRTCEvents.connectionRequest:
        await receivedConnectionRequest(UserJoinedData.fromJson(payload.data));
        break;
      case FebRTCEvents.offerSdp:
        await receivedOfferSdp(OfferSdpData.fromJson(payload.data));
        break;
      case FebRTCEvents.answerSdp:
        receivedAnswerSdp(AnswerSdpData.fromJson(payload.data));
        break;
      case FebRTCEvents.userLeft:
        // final data = payload.data;
        // final config = data?['config'];
        // if(config != null){
        //   final user = config?['user'];
        //   if(user != null){
        //     onUserJoined?.call(User.fromJson(user));
        //   }
        // }
        userLeft(UserLeftData.fromJson(payload.data));
        break;
      case FebRTCEvents.configChanged:
        configChangedForUser(payload.userId!,
            FebRtcPeerConfig.fromJson(payload.data?['config'] ?? {}));
        break;
      case FebRTCEvents.react:
        onReaction?.call(payload.userId, payload.data?['reaction']);
        break;
      case FebRTCEvents.mute:
      case FebRTCEvents.muteAll:
        toggleAudio(false);
        break;
      case FebRTCEvents.unMute:
      case FebRTCEvents.unMuteAll:
        toggleAudio(true);
        break;
      case FebRTCEvents.kick:
        leave();
        final connection = getConnection(payload.data?['userId']);
        onKicked?.call(connection!.value.config.user!);
        break;
      // case 'meeting-ended':
      //   meetingEnded(MeetingEndedData.fromJson(payload.data));
      //   break;
      case FebRTCEvents.candidate:
        setIceCandidate(IceCandidateData.fromJson(payload.data));
        break;
      case FebRTCEvents.negotiate:
        // if('${payload.data?['otherUserId']}' == userId) break;
        sendConnectionRequest(payload.data?['otherUserId']);
        break;
      case FebRTCEvents.amplitudeChanged:
        final user = payload.userId;
        final amp = AmplitudeData.fromJson(payload.data ?? {});
        final connection = getConnection(user!);
        if (connection != null) {
          final v = connection.value;
          final c = v.config;
          c.amplitude = amp;
          v.config = c;
          connection.value = v;
          connection.notifyListeners();
        }
        break;
      // case 'video-toggle':
      //   listenVideoToggle(VideoToggleData.fromJson(payload.data));
      //   break;
      // case 'audio-toggle':
      //   listenAudioToggle(AudioToggleData.fromJson(payload.data));
      //   break;
      // case 'not-found':
      //   handleNotFound();
      //   break;
      default:
        break;
    }
    final res = value.connections.remove(userId);
    notifyListeners();
    // res?.close();
  }

  onConnectStateChanged(SocketConnectState state) {
    value.connectState = state;
  }

  void leave() {
    FebRtcSdk.stopForegroundService();
    destroy();
    sendMessage(FebRTCEvents.leaveRoom, {
      'userId': userId,
    });
  }

  void amplitudeChanged(double amp) {
    if (!value.voice) return;
    broadcast(FebRTCEvents.amplitudeChanged, {
      'userId': userId,
      'amplitude': amp,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  bool destroyed = false;
  void destroy() async {

    destroyed = true;
    transporter.destroy();
    for (var connection in value.connections.values) {
      connection.close();
    }
    await Wakelock.disable();
    stopStream();
  }

  void react(String reaction) {
    broadcast(FebRTCEvents.react, {
      'userId': userId,
      'reaction': reaction,
    });
  }

  void kickUser(User user) {
    notify(user.id.toString(), FebRTCEvents.kick, {
      'userId': userId,
      'otherUserId': user.id,
    });
  }

  void muteUser(User user) {
    notify(user.id.toString(), FebRTCEvents.mute, {
      'userId': userId,
      'otherUserId': user.id,
    });
  }

  void unMuteUser(User user) {
    notify(user.id.toString(), FebRTCEvents.unMute, {
      'userId': userId,
      'otherUserId': user.id,
    });
  }

  void muteAll() {
    broadcast(FebRTCEvents.mute, {
      'userId': userId,
    });
  }

  void unMuteAll() {
    broadcast(FebRTCEvents.unMute, {
      'userId': userId,
    });
  }

  void sendInvite(List<String> invtMailIds) {
    emitEvent(FebRTCEvents.sendInvite, {
      'type': 1,
      'roomId': roomId,
      'userId': userId,
      'inviteId': [],
      'invtMailId': invtMailIds,
      'invtPhNo': [],
    }, (result) {
      log('sendInvite');
      log(result.toString());
    });
  }

  stopStream() async {
    return value.stream?.dispose();
  }

  void onConfigChanged() {
    broadcast(FebRTCEvents.configChanged, {
      'userId': userId,
      'config': value.config.toJson(),
    });
  }

  void configChangedForUser(String userId, FebRtcPeerConfig config) {
    final connection = getConnection(userId);
    if (connection != null) {
      connection.value.config = config;
      connection.notifyListeners();
    }
  }

  userJoined(UserJoinedData data) async {
    final old = getConnection(data.userId.toString() ?? '');
    if (old != null) {
      await old.close();
      value.connections.remove(data.userId.toString());
      notifyListeners();
    }
    final connection = await createConnection(data);
    if (connection != null) {
      await sendConnectionRequest(data.userId.toString());
    }
    setDefaultAudioOutput();
  }

  void sendIceCandidate(String otherUserId, RTCIceCandidate candidate) {
    sendMessage(FebRTCEvents.candidate, {
      'userId': userId,
      'otherUserId': otherUserId,
      'candidate': candidate.toMap(),
    });
  }

  sendConnectionRequest(String otherUserId) {
    sendMessage(FebRTCEvents.connectionRequest, {
      'name': 'system',
      'userId': userId,
      'sending': true,
      'otherUserId': otherUserId,
      'config': value.config.toJson(),
    });
  }

  receivedConnectionRequest(UserJoinedData data) async {
    final connection = await createConnection(data);
    if (connection != null) {
      sendOfferSdp(data.userId!);
    }
  }

  Future<FebRtcPeer?>? createConnection(UserJoinedData data) async {
    final old = getConnection(data.userId!);
    if (old != null) {
      return old;
    }

    // if (value.stream != null) {
    final connection = FebRtcPeer(
      localStream: value.stream,
      onIceCandidate: (RTCIceCandidate candidate) {
        print('onIceCandidate');
        sendIceCandidate(data.userId!, candidate);
      },
      onRenegotiationNeeded: (rtcPeerConnection) {
        print('onRenegotiationNeeded');
        broadcast(FebRTCEvents.negotiate, {
          'userId': userId,
          'otherUserId': data.userId,
        });
        // sendOfferSdp(data.userId!);
      },
      initialConfig: data.config ?? FebRtcPeerConfig(),
    );
    value.connections[data.userId!] = connection;
    notifyListeners();
    await connection.start();
    setDefaultAudioOutput();
    return connection;
    // }
    return null;
  }

  void sendOfferSdp(String otherUserId) async {
    final connection = getConnection(otherUserId);
    final sdp = await connection?.createOffer();
    sendMessage('offer-sdp', {
      'userId': userId,
      'otherUserId': otherUserId,
      'sdp': sdp?.toMap(),
    });
  }

  receivedOfferSdp(OfferSdpData data) {
    sendAnswerSdp(data.userId!, data.sdp!);
  }

  void sendAnswerSdp(String otherUserId, RTCSessionDescription sdp) async {
    final connection = getConnection(otherUserId);
    if (connection != null) {
      await connection.setOfferSdp(sdp);
      final answerSdp = await connection.createAnswer();
      if(answerSdp != null) {
        sendMessage(FebRTCEvents.answerSdp, {
          'userId': userId,
          'otherUserId': otherUserId,
          'sdp': answerSdp.toMap(),
        });
      } else {
        await Future.delayed(const Duration(seconds: 1));
        sendAnswerSdp(otherUserId, sdp);
      }
    }
  }

  FebRtcPeer? getConnection(String otherUserId) {
    return value.connections[otherUserId];
  }

  void receivedAnswerSdp(AnswerSdpData data) async {
    final connection = getConnection(data.userId!);
    await connection?.setAnswerSdp(data.sdp!);
  }

  void setIceCandidate(IceCandidateData data) async {
    final connection = getConnection(data.userId!);
    await connection?.setCandidate(data.candidate!);
  }

  void userLeft(UserLeftData data) async {
    final connection = getConnection(data.userId!);
    await connection?.close();

    value.connections.remove(data.userId!);
    notifyListeners();
    try {
      onUserLeft?.call(connection!.value.config.user!);
    } catch (_) {}
  }

  void sendMessage(String type, dynamic data) {
    try {
      final String payload = json.encode({'type': type, 'data': data});
      transporter.send(payload);
    } catch (_) {}
  }

  void notify(String userId, String type, Map<String, dynamic> data) {
    try {
      final String payload = json.encode({
        'userId': this.userId,
        'otherUserId': userId,
        'type': type,
        'data': data
      });
      transporter.notify(payload);
    } catch (_) {}
  }

  void emitEvent(String event, dynamic data, [Function? ack]) {
    try {
      final String payload = json.encode(data);
      print(payload);
      if (ack != null) {
        return transporter.emitWithAck(event, payload, ack);
      }
      transporter.emit(event, payload);
    } catch (_) {}
  }

  void broadcast(String type, Map<String, dynamic> data) {
    try {
      final String payload =
          json.encode({'userId': userId, 'type': type, 'data': data});
      transporter.broadcast(payload);
    } catch (_) {}
  }

  static Future<MediaStream> getUserMedia(
      {required bool audio, required bool video, bool empty = false}) async {

    if(empty){
      // return MediaStream();
      return EmptyStream('Vooo', 'ownerTag');
    }
    // check if camera is present
    // final c = navigator.mediaDevices.getSupportedConstraints();
    bool hasCamera = false, hasMic = false;
    final devices = await navigator.mediaDevices.enumerateDevices();
    
    for(final e in devices){
      if(e.kind == 'videoinput'){
        hasCamera = true;
        continue;
      }
      if(e.kind == 'audioinput'){
        hasMic = true;
        continue;
      }

    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true
    };



    print(mediaConstraints);
    try {
      if (kIsWeb) {
        if(!hasCamera){
          mediaConstraints.remove('video');
        }
        if(!hasMic){
          mediaConstraints.remove('audio');
        }
        print(mediaConstraints);
        // if(MApp.context.width < 400){
        //   return await navigator.mediaDevices
        //       .getDisplayMedia(mediaConstraints);
        // }
        final stream =
            await navigator.mediaDevices.getUserMedia(mediaConstraints);
        print(stream.getVideoTracks().length);
        return stream;
      } else {
        mediaConstraints['video'] = {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'maxFrameRate': '20',
          },
          'facingMode': 'user',
          'optional': [],
        };
        if(Platform.isIOS){

          mediaConstraints['audio'] = true;
          final videoStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
          // final audioStream = await navigator.mediaDevices.getUserMedia({
          //   'audio': true,
          //   'video': false,
          // });
          // final audioTrack = audioStream.getAudioTracks();
          // print('got audioTrack: ${audioTrack.length}');
          // if(audioTrack.isNotEmpty){
          //   videoStream.addTrack(audioTrack.first);
          // }
          return videoStream;
        } else {
          final stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
          return stream;
        }

      }
    } catch (e) {
      print(e);
      //'audio': true
      return navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
    }
  }

  static Future<List<MediaStreamTrack>> getAudioTrack() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    try {
      final stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return stream.getAudioTracks();
    } catch (e) {
      print(e);
      return [];
    }
  }
}

class FebRtcSdkValue {
  final String userId;
  MediaStream? stream;
  SocketConnectState connectState = SocketConnectState.connecting;
  RTCVideoRenderer? renderer;
  Map<String, FebRtcPeer> connections = {};

  bool voice = false;
  bool video = true;
  bool screen = false;
  bool hand = false;
  bool face = true;
  bool socket = false;
  bool stopped = false;
  bool joined = false;
  bool silence = false;
  bool host = true;

  FebRtcPeerConfig get config => FebRtcPeerConfig(
      userId: userId,
      voice: voice,
      video: video,
      screen: screen,
      stopped: stopped,
      hand: hand,
      silence: silence,
      face: face,
      user: Local.user);

  FebRtcSdkValue(
      {this.stream,
      this.renderer,
      this.voice = false,
      this.video = false,
      required this.userId});
}

class EmptyStream extends MediaStream {
  EmptyStream(super.id, super.ownerTag);

  @override
  // TODO: implement active
  bool? get active => true;

  @override
  Future<void> addTrack(MediaStreamTrack track, {bool addToNative = true}) async {
    return;
  }

  @override
  List<MediaStreamTrack> getAudioTracks() {
    return [];
  }

  @override
  Future<void> getMediaTracks() async {
    return;
  }

  @override
  List<MediaStreamTrack> getTracks() {
    return [];
  }

  @override
  List<MediaStreamTrack> getVideoTracks() {
    return [];
  }

  @override
  Future<void> removeTrack(MediaStreamTrack track, {bool removeFromNative = true}) async {
    return;
  }

}