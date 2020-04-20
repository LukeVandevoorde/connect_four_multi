import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';
import 'package:connectivity/connectivity.dart';
import 'connect_four.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

enum EventType {
  move,
  reset,
}

class ConnectFourConnection extends ConnectFour {
  static const int DEFAULT_PORT = 27677;

  ServerSocket _server;
  Socket _client;
  Socket _endPoint;

  VoidCallback _onReady, _onUpdate;
  Function(String) _onConnectionEnd;
  bool _isHost, _ready;

  // P1 is always defined as the user, whether host or client
  ConnectFourConnection(this._onReady, this._onUpdate, this._onConnectionEnd): super(7,6,true) {
    _isHost = false;
    _ready = false;
  }

  void connect() {
    this.close();
    this.p1turn = false;

    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      if(result == ConnectivityResult.wifi) {
        GetIp.ipAddress.then((my_ip) {
          print('got my ip $my_ip');
          String subnet = my_ip.substring(0, my_ip.lastIndexOf('.'));
          for(int i =  1; i < 256; i++) {
            Socket.connect('$subnet.$i', DEFAULT_PORT).then((socket) {
              _endPoint = socket;
              _endPoint.listen(_onData).onError(_onError);
              _endPoint.done.whenComplete(() {
                print('Destroying my sockets');
                this.destroy();
              });
              _ready = true;
              _onReady();
              print('done connecting');
            }).catchError((error) {
//          print('error while connecting: ');
//          print(error.toString());
            });
          }
        });
      } else {
        _onConnectionEnd("Connection failed: you are not connected to a wifi network");
      }
    });

  }

  void connectIP(String ipAddress) {
    this.close();
    this.p1turn = false;

    Socket.connect(ipAddress, DEFAULT_PORT).then((socket) {
      _endPoint = socket;
      _endPoint.listen(_onData).onError(_onError);
      _endPoint.done.whenComplete(() {
        print('Destroying my sockets');
        this.destroy();
      });
      _ready = true;
      _onReady();
    }).catchError((error) {
      print(error.toString());
    });
  }

  void host() async {

    this.close();
    GetIp.ipAddress.then((my_ip) {
      print('got my ip: $my_ip');
      ServerSocket.bind(my_ip, DEFAULT_PORT).then((serverSocket) {
        print('bound');
        _server = serverSocket;
        _server.listen((socket) {
          print('client connected in theory');
          _isHost = true;
          _client = socket;
          _client.listen(_onData).onError(_onError);
          _client.done.then((value) {
            this._onConnectionEnd("The connection was closed");
            this.close();
          });
          _ready = true;
          _onReady();
          _server.close();
        }).onError((error) {
          print(error.toString());
        });
//      }).catchError((error) {
//        print('Could not create serversocket');
//        print(StackTrace.current.toString());
      });
    });
  }

  void setStartingPlayer(bool playerOneStart) {
    super.setStartingPlayer(playerOneStart);
    print('For some reason the child class method is being called');
    this._sendMessage(_msg(["event", "start"], ["switchStartingPlayer", (!playerOneStart)]));
  }

  void reset() {
    _sendMessage(_msg(["event"], ["reset"]));
    _applyReset();
  }

  void _applyReset() {
    super.reset();
    this.p1turn = this.p1start;
  }

  @override
  MoveStatus move(int column) {
    if (!p1turn || !validMove(column) || !_ready) {
      return (MoveStatus.INVALID_MOVE);
    }
    _sendMessage(_msg(["event", "column"], ["move", column]));
    return super.move(column);
  }

  Future<void> close() async {
    print('Closing sockets');
    if (_client != null) {
      await _client.close();
    }
    if (_server != null) {
      await _server.close();
    }
    if (_endPoint != null) {
      await _endPoint.close();
    }
    _ready = false;
  }

  void destroy() {
    print('Destroying sockets');
    if (_client != null) {
      _client.destroy();
    }
    if (_server != null) {
      _server.close();
    }
    if (_endPoint != null) {
      _endPoint.destroy();
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
      case 'switchStartingPlayer':
        super.setStartingPlayer(json['start']);
        this._onUpdate();
        break;
    }

    _onUpdate();
  }

  void _onError(error) {
    this.close();
    this.reset();
    this._onConnectionEnd("An error occurred");
    print('Closing connection due to error (this might be logged twice sorry line connect_four_online.dart line 218)' + error.toString());
    print(StackTrace.current.toString());
  }
}
