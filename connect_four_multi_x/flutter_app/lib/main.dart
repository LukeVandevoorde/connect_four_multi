//import 'dart:html';

import 'package:flutter/material.dart';
import 'connect_four_online.dart';
import 'package:flutter/foundation.dart';
import 'connect_four.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ConnectFourHomePage('Connect Four'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ConnectFourHomePage extends StatelessWidget {

  final String title;

  ConnectFourHomePage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String option) {
                Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                  // 107.3.143.161
                  TextEditingController ipController = TextEditingController(text: "107.3.143.161");

                  return Scaffold(
                    appBar: AppBar(
                      title: Text("Connect IP"),
                    ),
                    body: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          child: TextField(
                            textAlign: TextAlign.center,
                            controller: ipController,
                            onSubmitted: (String ip) {
                              Navigator.push(context, CupertinoPageRoute(builder: (BuildContext context) {
                                return OnlineConnectFourPage(false, ip);
                              }));
                            },
                          ),
                          padding: EdgeInsets.all(20),
                        )
                      ],
                    ),
                  );
                }));
              },
              itemBuilder: (BuildContext context) {
                return [PopupMenuItem<String>(value: "connect ip", child: Text("Connect IP"),)];
              },
            )
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  child: Text('Local', style: TextStyle(color: Colors.black, fontSize: 30, fontFamily: 'Calibri'),),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                      return SinglePlayerConnectFourPage();
                    }));
                  },
                ),
                margin: EdgeInsets.all(20),
              ),
              Container(
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  child: Text('Connect', style: TextStyle(color: Colors.black, fontSize: 30, fontFamily: 'Calibri'),),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                      return OnlineConnectFourPage(false, null);
                    }));
                  },
                ),
                margin: EdgeInsets.all(20),
              ),
              Container(
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  child: Text('Host', style: TextStyle(color: Colors.black, fontSize: 30, fontFamily: 'Calibri'),),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                      return OnlineConnectFourPage(true, null);
                    }));
                  },
                ),
                margin: EdgeInsets.all(20),
              ),
            ],
          ),
        )
    );
  }
}

class SinglePlayerConnectFourPage extends StatefulWidget {
  final ConnectFour game;

  SinglePlayerConnectFourPage({Key key}): this.game = ConnectFour(7, 6, true), super(key: key);

  _SinglePlayerConnectFourPageState createState() => _SinglePlayerConnectFourPageState();
}

class _SinglePlayerConnectFourPageState extends State<SinglePlayerConnectFourPage> {

  bool allowPlayerMove = true;

  Widget build (BuildContext context) {

    print('rebuilding $allowPlayerMove');
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('Single Player'),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String option) {
                if(option == "reset") {
                  setState(() {
                    widget.game.reset();
                    if(widget.game.p1turn) {
                      allowPlayerMove = true;
                    } else {
                      compute(ConnectFour.bestMove, widget.game).then((int bestMove) {
                            widget.game.move(bestMove);
                            setState(() {
                              allowPlayerMove = true;
                            });
                          }
                      );
                    }
                    allowPlayerMove = widget.game.p1turn;
                  });
                } else if (option == "switch starting player") {
                  widget.game.setStartingPlayer(!widget.game.p1start);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(value: "reset", child: Text("reset"),),
                  PopupMenuItem<String>(value: "switch starting player", child: Text(widget.game.p1start?"Starting player: you":"Starting player: computer"),),
                ];
              },
            )
          ],
        ),
        body: Container(
          child: Column(
            children: [ConnectFourWidget(widget.game, _onTap,)],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          padding: EdgeInsets.all(6),
        )
    );
  }

  void _onTap(int column) {
    if (allowPlayerMove) {
      MoveStatus move = widget.game.move(column);
      setState(() {
        if (move == MoveStatus.VALID_MOVE) {
          allowPlayerMove = false;

          compute(ConnectFour.bestMove, widget.game).then(
                  (int bestMove) {
                widget.game.move(bestMove);
                setState(() {
                  allowPlayerMove = true;
                });
              }
          );
        }
      });
    }
  }
}

class OnlineConnectFourPage extends StatefulWidget {
  final bool isHost;
  final String ipAddress;

  OnlineConnectFourPage(this.isHost, this.ipAddress, {Key key}): super(key: key);

  _OnlineConnectFourPageState createState() => _OnlineConnectFourPageState(this.isHost, this.ipAddress);
}

class _OnlineConnectFourPageState extends State<OnlineConnectFourPage> {
  ConnectFourConnection game;

  String _message;
  bool _ready;

  _OnlineConnectFourPageState(bool isHost, String ipAddress) {
    this._ready = false;
    _message = "Waiting for connection";
    game = ConnectFourConnection(() {setState(() {_ready = true; _displayMove();});}, _displayMove, (String connectionEndMessage) {setState(() {_message = connectionEndMessage;});});
    if(ipAddress != null) {
      game.connectIP(ipAddress);
    } else {
      print('doing null ipaddress tings');
      if (isHost) {
        game.host();
      } else {
        game.connect();
      }
    }
  }

  Widget build (BuildContext context) {
    List<Widget> children = [
      Container(
        child: Center(child: Text(_message, style: TextStyle(fontSize: 24),),),
        padding: EdgeInsets.only(top: 50),
      )
    ];
    if (_ready) {
      children.insert(0, ConnectFourWidget(this.game, this._onTap));
    }
    return WillPopScope(
      onWillPop: () async {
        await game.close();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('Online'),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String option) {
                if(option == "reset") {
                  setState(() {
                    game.reset();
                  });
                } else if (option == "switch starting player") {
                  setState(() {
                    game.setStartingPlayer(!game.p1start);
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(value: "reset", child: Text("reset"),),
                  PopupMenuItem<String>(value: "switch starting player", child: Text(game.p1start?"Starting player: you":"Starting player: opponent"),),
                ];
              },
            ),
//            IconButton(icon: Icon(Icons.refresh), onPressed: () {
//              setState(() {
//                game.reset();
//              });
//            })
          ],
        ),
        body: Container(
          child: Column(
            children: children,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          padding: EdgeInsets.all(6),
        )
    )
    );
  }

  void _onTap(int column) {
    setState(() {
      game.move(column);
      _message = game.p1turn?"Your move":"Waiting for opponent";
    });
  }

  void _displayMove() {
    setState(() {
      _message = game.p1turn?"Your move":"Waiting for opponent";
    });
  }
}