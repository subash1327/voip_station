import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart';

enum SocketConnectState { connecting, connected, disconnected, reconnecting }

class SocketIOTransport {
  final String url;
  int retryCount = 0;
  int maxRetryCount = 5;
  bool closed = false;
  Socket? socket;
  final VoidCallback? onOpen;
  final Function(dynamic data)? onMessage;
  final Function(SocketConnectState state)? onConnectStateChanged;

  SocketIOTransport({required this.url, this.onOpen, this.onMessage, this.onConnectStateChanged}) {

    socket = io(url, <String, dynamic>{
      'transports': ['websocket'],
      'forceNew': true,
      // 'autoConnect': true,
    });
  }

  Future<bool> connect() async {
    try {
      if (retryCount <= maxRetryCount) {
        retryCount++;
        socket = socket?.connect();
        socket?.onConnect((data) {
          onOpen?.call();
          onConnectStateChanged?.call(SocketConnectState.connected);
          // if(kDebugMode){
            print('${url} Connect: ${socket?.id} ${socket?.query}');
          // }
        });
        socket?.onDisconnect((data) {
          onConnectStateChanged?.call(SocketConnectState.disconnected);
          if(kDebugMode){
            print('Disconnect: ${socket?.id} ${url}');
          }
        });
        socket?.onReconnecting((data) => onConnectStateChanged?.call(SocketConnectState.reconnecting));
        socket?.onReconnect((data) => onConnectStateChanged?.call(SocketConnectState.connected));
        socket?.on("message", handleMessage);
        socket?.onAny((event, data){
          log('Event: ${event} Data: ${data}');
        });
        return true;
      } else {
        throw Exception('Failed to connect to Socket IO');
      }
    } catch (error) {
      print(error);
      return await connect();
    }
  }

  void listenEvents() {

    handleOpen();
  }

  void handleOpen() {
    if (onOpen != null) {
      onOpen?.call();
    }
  }

  void handleMessage(dynamic data) {
    print(data);
    if (onMessage != null) {
      onMessage?.call(data);
    }
  }

  void handleClose() {
    reset();
    if (!closed) {
      connect();
    }
  }

  void handleError(Object error) {
    reset();
    if (!closed) {
      connect();
    }
  }

  void send(dynamic data) {
    print(data);
    socket?.emit("message", data);
  }

  void notify(dynamic data) {
    print(data);
    socket?.emit("notify", data);
  }
  void broadcast(dynamic data) {
    print(data);
    socket?.emit("broadcast", data);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }
  void emitWithAck(String event, dynamic data, Function? ack) {
    socket?.emitWithAck(event, data, ack: ack);
  }

  void reset() {


  }

  void close() {
    closed = true;
    destroy();
  }

  void destroy() {
    socket?.close();
    socket?.disconnect();
    socket?.dispose();
    reset();
  }

  void reconnect() {
    retryCount = 0;
    connect();
  }
}