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
                  return OnlineConnectFourPage(false, "107.3.143.161");
                }));
              },
              itemBuilder: (BuildContext context) {
                return [PopupMenuItem<String>(value: "connect ip", child: Text("connect to luke lol"),)];
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
            IconButton(icon: Icon(Icons.refresh), onPressed: () {
              setState(() {
                widget.game.reset();
                allowPlayerMove = true;
              });
            })
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

  _OnlineConnectFourPageState createState() => _OnlineConnectFourPageState(isHost, ipAddress);
}

class _OnlineConnectFourPageState extends State<OnlineConnectFourPage> {
  ConnectFourConnection game;

  String _message;

  _OnlineConnectFourPageState(bool isHost, String ipAddress) {
    _message = "Waiting for connection";
    game = ConnectFourConnection(_displayMove, _displayMove, () {setState(() {_message = "Connection lost";});});
    if(ipAddress != null) {
      game.connectIP(ipAddress);
    } else {
      if (isHost) {
        game.host();
      } else {
        game.connect();
      }
    }
  }

  Widget build (BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('Online'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.refresh), onPressed: () {
              setState(() {
                game.reset();
              });
            })
          ],
        ),
        body: Container(
          child: Column(
            children: [Center(child: Text(_message, style: TextStyle(fontSize: 24),),)],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          padding: EdgeInsets.all(6),
        )
    );
  }

  void _onTap(int column) {
    setState(() {
      game.move(column);
    });
  }

  void _displayMove() {
    setState(() {
      _message = game.p1turn?"Your move":"Waiting for opponent";
    });
  }
}