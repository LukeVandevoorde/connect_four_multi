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
        fontFamily: 'Montserrat',
        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          body1: TextStyle(fontSize: 24.0, fontFamily: 'Hind'),
        ),
      ),
      home: ConnectFourHomePage('Connect Four Test'),
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
        appBar: AppBar(title: Text(title),),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  child: Text('Local', style: TextStyle(color: Colors.brown, fontSize: 30, fontFamily: 'Calibri'),),
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
                  child: Text('Connect', style: TextStyle(color: Colors.brown, fontSize: 30, fontFamily: 'Calibri'),),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                      return OnlineConnectFourPage(false);
                    }));
                  },
                ),
                margin: EdgeInsets.all(20),
              ),
              Container(
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  child: Text('Host', style: TextStyle(color: Colors.brown, fontSize: 30, fontFamily: 'Calibri'),),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  onPressed: () {
                    Navigator.push(context, CupertinoPageRoute(builder: (ctxt) {
                      return OnlineConnectFourPage(true);
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
  OnlineConnectFourPage(this.isHost, {Key key}): super(key: key);

  _OnlineConnectFourPageState createState() => _OnlineConnectFourPageState(isHost);
}

class _OnlineConnectFourPageState extends State<OnlineConnectFourPage> {
  ConnectFourConnection game;

  _OnlineConnectFourPageState(bool isHost) {
    game = ConnectFourConnection(() {setState((){});}, () {setState((){});});
    if (isHost) {
      game.host();
    } else {
      game.connect();
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
            children: [ConnectFourWidget(game, _onTap,)],
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
}
