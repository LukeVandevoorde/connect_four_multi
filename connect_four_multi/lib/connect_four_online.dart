import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';
import 'connect_four.dart';
import 'dart:convert';
import 'dart:io';

enum EventType {
  move,
  reset,
}

class ConnectFourConnection extends ConnectFour {
  static final int DEFAULT_PORT = 7677;

  ServerSocket _server;
  Socket _client;
  Socket _endPoint;

  VoidCallback _onReady, _onUpdate;
  bool _isHost, _ready;

  // P1 is always defined as the user, be they host or client
  ConnectFourConnection(this._onReady, this._onUpdate): super(7,6,true) {
    _isHost = false;
    _ready = false;
  }

  void connect() {
    this.close();
    this.p1turn = false;

    GetIp.ipAddress.then((my_ip) {
      String prefix = my_ip.substring(0, my_ip.lastIndexOf('.'));
      for (int i = 0; i <= 255; i++) {
        Socket.connect('$prefix.$i', DEFAULT_PORT).then((socket) {
          _endPoint = socket;
          _endPoint.listen(_onData).onError(_onError);
          _ready = true;
          _onReady();
        }).catchError((error) {

        });
      }
    });
  }

  void host() async {

    this.close();
    GetIp.ipAddress.then((my_ip) {
      ServerSocket.bind(my_ip, DEFAULT_PORT).then((serverSocket) {
        _server = serverSocket;
        _server.listen((socket) {
          _isHost = true;
          _client = socket;
          _client.listen(_onData).onError(_onError);
          _ready = true;
          _onReady();
        });
//      }).catchError((error) {
//        print('Could not create serversocket');
//        print(StackTrace.current.toString());
      });
    });
  }

  void reset() {
    _sendMessage(_msg(["event"], ["reset"]));
    _applyReset();
  }

  void _applyReset() {
    super.reset();
    this.p1turn = _isHost;
  }

  @override
  MoveStatus move(int column) {
    if (!p1turn || !validMove(column) || !_ready) {
      return (MoveStatus.INVALID_MOVE);
    }
    _sendMessage(_msg(["event", "column"], ["move", column]));
    return super.move(column);
  }

  void close() {
    if (_client != null) {
      _client.close();
    }
    if (_server != null) {
      _server.close();
    }
    if (_endPoint != null) {
      _endPoint.close();
    }
    _ready = false;
  }

  String _msg (List<String> keys, List<dynamic> data) {
    Map<String, dynamic> toEncode = Map();

    for (int i = 0; i < keys.length; i++) {
      toEncode.putIfAbsent(keys[i], () => data[i]);
    }

    return jsonEncode(toEncode) + '\n';
  }

  void _sendMessage(String message) {
    if (_isHost) {
      _client.write(message);
      _client.flush();
    } else {
      _endPoint.write(message);
      _endPoint.flush();
    }
  }

  void _onData(data) {
    String input = String.fromCharCodes(data);
    print('RECEIVED: $input');
    Map<String, dynamic> json = jsonDecode(input);
    print('Parsed: $json');

    switch (json['event']) {
      case 'move':
        if (this.p1turn) {
          _sendMessage(_msg(["event", "type"], ["invalid move", "out of order"]));
        } else {
          super.move(json['column']);
        }
        break;
      case 'reset':
        _applyReset();
        break;
    }

    _onUpdate();
  }

  void _onError(error) {
    this.close();
    this.reset();
    print('Closing connection due to error');
    print(StackTrace.current.toString());
  }
}
