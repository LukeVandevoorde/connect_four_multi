import 'package:flutter/material.dart';
import 'dart:math';

enum MoveStatus {
  VALID_MOVE,
  INVALID_MOVE,
  PLAYER_ONE_WIN,
  PLAYER_TWO_WIN,
}

class ConnectFourWidget extends StatelessWidget {
  final ConnectFour game;
  final Function(int) onTap;

  ConnectFourWidget(this.game, this.onTap);

  Widget build (BuildContext context) {

    return LayoutBuilder(
      builder: (BuildContext ctxt, BoxConstraints constraints) {
        List<Widget> columns = List(game.width);
        double size = min((constraints.maxWidth)/game.width, (constraints.maxHeight)/game.height);

        double margin = 1;
        size -= (2*margin);

        for (int i = 0; i < game.width; i++) {
          List<Widget> children = List(game.height);
          for (int j = 0; j < game.height; j++) {
            int tile = game.get(i, j);
            if (tile == ConnectFour.EMPTY) {
              children[game.height - 1 - j] = Container(
                width: size,
                height: size,
                margin: EdgeInsets.all(margin),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              );
            } else if (tile == ConnectFour.PLAYER_ONE) {
              children[game.height - 1 - j] = Container(
                width: size,
                height: size,
                margin: EdgeInsets.all(margin),
                decoration: BoxDecoration(
                  border: (game.winLine != null && game.winLine.contains(i, j))?Border.all(color: Colors.black, width: 5):null,
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              );
            } else if (tile == ConnectFour.PLAYER_TWO) {
              children[game.height - 1 - j] = Container(
                width: size,
                height: size,
                margin: EdgeInsets.all(margin),
                decoration: BoxDecoration(
                  border: (game.winLine != null && game.winLine.contains(i, j))?Border.all(color: Colors.black, width: 5):null,
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              );
            }
          }
          columns[i] = GestureDetector(
            child: Column(
              children: children,
            ),
            onTap: () {
              onTap(i);
            },
          );

        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: columns,
        );
      },
    );
  }
}

class ConnectFour {
  static const int EMPTY = 0;
  static const int PLAYER_ONE = 1;
  static const int PLAYER_TWO = 2;

  static const int EXTREME_SCORE = 100000;

  int playCount;
  int difficulty;
  int width, height;
  List<List<int>> tiles;
  List<_Line> usefulLines;
  bool p1turn, won;
  _Line winLine;

  ConnectFour (this.width, this.height, bool playerOneStart) {
    this.p1turn = playerOneStart;
    playCount = 0;
    won = false;
    tiles = List(width);
    for (int i = 0; i < width; i++) {
      tiles[i] = List(height);
      for (int j = 0; j < height; j++) {
        tiles[i][j] = EMPTY;
      }
    }

    usefulLines = List<_Line>();
  }

  ConnectFour.copy(ConnectFour other) {
    this.playCount = other.playCount;
    this.p1turn = other.p1turn;
    this.width = other.width;
    this.height = other.height;
    this.won = other.won;
    this.winLine = other.winLine;

    this.tiles = List(width);

    for (int i = 0; i < width; i++) {
      this.tiles[i] = List(height);
      for (int j = 0; j < height; j++) {
        this.tiles[i][j] = other.tiles[i][j];
      }
    }

    this.usefulLines = List<_Line>();
    for (int i = 0; i < other.usefulLines.length; i++) {
      this.usefulLines.add(other.usefulLines[i]);
    }
  }

  void setDifficulty(int difficulty) {
    this.difficulty = difficulty;
  }

  int get(int x, int y) {
    return tiles[x][y];
  }

  bool inbound (int x, int y) {
    return (x >= 0 && x < width && y >= 0 && y < height);
  }

  MoveStatus move(int column) {
    int y = height - 1;
    if (column < 0 || column >= width || tiles[column][y] != EMPTY || won) {
      return MoveStatus.INVALID_MOVE;
    }
    playCount += 1;
    while (y-1 >= 0 && tiles[column][y-1] == EMPTY) {
      y -= 1;
    }

    tiles[column][y] = p1turn?PLAYER_ONE:PLAYER_TWO;

    for (int i = 0; i < 4; i++) {
      _Line check = _Line(column, y, i, this);

      usefulLines.add(check);

      if (check.length >= 4) {
        won = true;
        winLine = check;
        return p1turn ? MoveStatus.PLAYER_ONE_WIN : MoveStatus.PLAYER_TWO_WIN;
      }
    }

    p1turn = !p1turn;
    return MoveStatus.VALID_MOVE;
  }

  void reset() {
    this.p1turn = true; // todo Have this return to original setting as specified by construction
    this.winLine = null;
    won = false;
    tiles = List(width);
    for (int i = 0; i < width; i++) {
      tiles[i] = List(height);
      for (int j = 0; j < height; j++) {
        tiles[i][j] = EMPTY;
      }
    }
  }

  bool validMove(int column) {
    return !won && this.tiles[column][this.height - 1] == EMPTY;
  }

  static Future<int> bestMove(ConnectFour game) async {
    int minScore = -EXTREME_SCORE - 1;
    int bestMove = 0;
    for (int i = 0; i < game.width; i++) {
      if (game.validMove(i)) {
//        int tentativeScore = _scoreMove(i, (game.difficulty == null ? 5: game.difficulty), (game.p1turn ? PLAYER_ONE : PLAYER_TWO), true, game);
        int tentativeScore = _alphaBeta(i, (game.difficulty == null ? 7: game.difficulty), (game.p1turn ? PLAYER_ONE : PLAYER_TWO), true, game, EXTREME_SCORE, -EXTREME_SCORE);

        if (tentativeScore > minScore) {
          bestMove = i;
          minScore = tentativeScore;
        } else if (tentativeScore == minScore) {
          if (Random().nextInt(i + 1) == 0) {
            bestMove = i;
            minScore = tentativeScore;
          }
        }
      }
    }
    print('found bestMove $bestMove, $minScore');
    return bestMove;
  }

  static int _alphaBeta(int column, int searchDepth, int team, bool turn, ConnectFour game, int minScore, int maxScore) {
    int score = 0;
    ConnectFour gameCopy = ConnectFour.copy(game);
    gameCopy.move(column);

    if (turn) {
      if (gameCopy.won) {
        return EXTREME_SCORE;
      }
      if (searchDepth <= 0) {
        return gameCopy._scoreState(team) - gameCopy._scoreState(3 - team);
      }

      score = EXTREME_SCORE;
      for (int i = 0; i < gameCopy.width; i++) {
        if (gameCopy.validMove(i)) {
          score = min(score, _alphaBeta(i, searchDepth - 1, team, !turn, gameCopy, minScore, maxScore));
          minScore = min(score, minScore);
          if (maxScore >= minScore) {
            return score;
          }
        }
      }
    } else {
      if (gameCopy.won) {
        return -EXTREME_SCORE;
      }
      if (searchDepth <= 0) {
        return -gameCopy._scoreState(team) + gameCopy._scoreState(3 - team);
      }

      score = -EXTREME_SCORE;
      for (int i = 0; i < gameCopy.width; i++) {
        if (gameCopy.validMove(i)) {
          score = max(score, _alphaBeta(i, searchDepth - 1, team, !turn, gameCopy, minScore, maxScore));
          maxScore = max(score, maxScore);
          if (maxScore >= minScore) {
            return score;
          }
        }
      }
    }

    return score;
  }

  static int _scoreMove(int column, int searchDepth, int team, bool turn, ConnectFour game) {
    int score = 0;
    ConnectFour gameCopy = ConnectFour.copy(game);
    gameCopy.move(column);

    if (turn) {
      if (gameCopy.won) {
        return EXTREME_SCORE;
      }
      if (searchDepth <= 0) {
        return gameCopy._scoreState(team) - gameCopy._scoreState(3 - team);
      }

      score = EXTREME_SCORE;
      for (int i = 0; i < gameCopy.width; i++) {
        if (gameCopy.validMove(i)) {
          score = min(score, _scoreMove(i, searchDepth - 1, team, !turn, gameCopy));
        }
      }
    } else {
      if (gameCopy.won) {
        return -EXTREME_SCORE;
      }
      if (searchDepth <= 0) {
        return -gameCopy._scoreState(team) + gameCopy._scoreState(3 - team);
      }

      score = -EXTREME_SCORE;
      for (int i = 0; i < gameCopy.width; i++) {
        if (gameCopy.validMove(i)) {
          score = max(score, _scoreMove(i, searchDepth - 1, team, !turn, gameCopy));
        }
      }
    }

    return score;
  }

  // counts [multiple of, consistently, which is OK] [actually, honestly, idk, depending on implementation] the number of incomplete-by-1 four-in-a-rows exist for <team>
  // Now that I think about it, it may count a potential 5 or higher in-a-row the same as multiple different 'spaces' for a potential 4 in a row, but for now, this is prob ok
  // this is due to semi-duplicate lines in UsefulLines
  int _scoreState (int team) {
    int score = 0;

    for (int i = 0; i < usefulLines.length; i++) {
      _Line line = usefulLines[i];
      if (line.team == team && line.length > 2) {
        if (line.pre(this, 1) == EMPTY) {
          score += 3;
        }
        if (line.next(this, 1) == EMPTY) {
          score += 3;
        }
      }
      if (line.length > 1 && line.team == team) {
        int pre2 = line.pre(this, 2);
        int pre1 = line.pre(this, 1);
        int next1 = line.next(this, 1);
        int next2 = line.next(this, 2);
        if (pre1 == EMPTY) {
          if (pre2 == team) {
            score += 3;
          } else if (pre2 == EMPTY) {
            score += 1;
          }
        }
        if (next1 == EMPTY) {
          if (next2 == team) {
            score += 3;
          } else if (next2 == EMPTY) {
            score += 1;
          }
        }
        if (pre1 == EMPTY && next1 == EMPTY) {
          score += 1;
        }
      }
    }

    return score;
  }
}

class _Line {
  // 8 total directions, starting in +x direction and rotating counter-clockwise around the coordinate plane
  static const List<int> SHIFT_X = [1, 1, 0, -1];
  static const List<int> SHIFT_Y = [0, 1, 1, 1];

  int x1, y1, x2, y2;
  int direction;
  int team;
  int length;

  _Line(int x, int y, int direction, ConnectFour game) {
    x1 = x;
    x2 = x;
    y1 = y;
    y2 = y;
    this.direction = direction;
    length = 1;
    team = game.get(x, y);

    int shiftX = SHIFT_X[direction];
    int shiftY = SHIFT_Y[direction];

//    print('start construction of dat line');

    while (game.inbound(x1 - shiftX, y1 - shiftY) && game.get(x1 - shiftX, y1 - shiftY) == team) {
      x1 -= shiftX;
      y1 -= shiftY;
      length += 1;
    }
    while (game.inbound(x2 + shiftX, y2 + shiftY) && game.get(x2 + shiftX, y2 + shiftY) == team) {
      x2 += shiftX;
      y2 += shiftY;
      length += 1;
    }
//    print('end construction of dat line');
  }

  _Line.copy(_Line other) {
    this.x1 = other.x1;
    this.x2 = other.x2;
    this.y1 = other.y1;
    this.y2 = other.y2;
    this.team = other.team;
    this.direction = other.direction;
    this.length = other.length;
  }

  bool equals(_Line other) {
    return (other.team == team && other.x1 == x1 && other.y1 == y1 && other.x2 == x2 && other.y2 == y2);
  }

  int pre(ConnectFour game, int dist) {
    int x = preX(dist);
    int y = preY(dist);
    if (game.inbound(x, y)) {
      return game.get(x, y);
    }
    return -1;
  }

  int next(ConnectFour game, int dist) {
    int x = nextX(dist);
    int y = nextY(dist);
    if (game.inbound(x, y)) {
      return game.get(x, y);
    }
    return -1;
  }

  int preX(int dist) {
    return x1 - dist*SHIFT_X[direction];
  }

  int preY(int dist) {
    return y1 - dist*SHIFT_Y[direction];
  }

  int nextX(int dist) {
    return x2 + dist*SHIFT_X[direction];
  }

  int nextY(int dist) {
    return y2 + dist*SHIFT_Y[direction];
  }

  bool contains(int x, int y) {
    for (int i = 0; i < this.length; i++) {
      if (x == x1 + i*SHIFT_X[this.direction] && y == y1 + i*SHIFT_Y[this.direction]) {
        return true;
      }
    }

    return false;
  }
}