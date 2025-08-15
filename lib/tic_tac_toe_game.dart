import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
class TicTacToeGame extends FlameGame with TapDetector, HasGameRef {
  late double cellSize;
  late Vector2 boardOffset;
  List<List<String>> board = List.generate(3, (_) => List.filled(3, ''));
  String currentPlayer = 'X';
  bool isGameOver = false;
  GameMode gameMode = GameMode.pvp;
  Timer? aiTimer;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    boardOffset = Vector2(size.x * 0.1, size.y * 0.2);
    cellSize = size.x * 0.8 / 3;
    overlays.add('playGame');
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (isGameOver || (currentPlayer == 'O' && gameMode != GameMode.pvp)) return;

    final localPosition = info.eventPosition.global - boardOffset;
    int row = (localPosition.y / cellSize).floor();
    int col = (localPosition.x / cellSize).floor();

    if (row >= 0 && row < 3 && col >= 0 && col < 3 && board[row][col] == '') {
      makeMove(row, col);
      
      if (!isGameOver && gameMode != GameMode.pvp && currentPlayer == 'O') {
        // AI's turn
        aiTimer = Timer(0.5, onTick: () {
          makeAiMove();
          aiTimer = null;
        });
      }
    }
  }

  void makeMove(int row, int col) {
    board[row][col] = currentPlayer;
    
    if (checkWin(currentPlayer)) {
      isGameOver = true;
      overlays.add('GameOver');
    } else if (isDraw()) {
      isGameOver = true;
      overlays.add('GameOver');
    } else {
      currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
    }
  }

  void makeAiMove() {
    if (isGameOver) return;

    List<int> move;
    switch (gameMode) {
      case GameMode.easyAI:
        move = findRandomMove();
        break;
      case GameMode.hardAI:
        move = findBestMove();
        break;
      default:
        return;
    }

    makeMove(move[0], move[1]);
  }

  List<int> findRandomMove() {
    List<List<int>> emptyCells = [];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') emptyCells.add([i, j]);
      }
    }
    return emptyCells.isEmpty ? [0, 0] : emptyCells[Random().nextInt(emptyCells.length)];
  }

  List<int> findBestMove() {
    // Simple minimax implementation
    int bestScore = -1000;
    List<int> bestMove = [-1, -1];

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i][j] == '') {
          board[i][j] = 'O';
          int score = minimax(board, 0, false);
          board[i][j] = '';
          if (score > bestScore) {
            bestScore = score;
            bestMove = [i, j];
          }
        }
      }
    }

    return bestMove;
  }

  int minimax(List<List<String>> board, int depth, bool isMaximizing) {
    if (checkWin('O')) return 10 - depth;
    if (checkWin('X')) return depth - 10;
    if (isDraw()) return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'O';
            int score = minimax(board, depth + 1, false);
            board[i][j] = '';
            bestScore = max(score, bestScore);
          }
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (board[i][j] == '') {
            board[i][j] = 'X';
            int score = minimax(board, depth + 1, true);
            board[i][j] = '';
            bestScore = min(score, bestScore);
          }
        }
      }
      return bestScore;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.white;
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4;

    // Draw grid
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(boardOffset.x + cellSize * i, boardOffset.y),
        Offset(boardOffset.x + cellSize * i, boardOffset.y + cellSize * 3),
        linePaint,
      );
      canvas.drawLine(
        Offset(boardOffset.x, boardOffset.y + cellSize * i),
        Offset(boardOffset.x + cellSize * 3, boardOffset.y + cellSize * i),
        linePaint,
      );
    }

    // Draw X and O
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final symbol = board[row][col];
        if (symbol != '') {
          final textSpan = TextSpan(
            text: symbol,
            style: TextStyle(
              color: symbol == 'X' ? Colors.red : Colors.green,
              fontSize: cellSize * 0.7,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.text = textSpan;
          textPainter.layout();

          final offset = Offset(
            boardOffset.x + col * cellSize + cellSize / 2 - textPainter.width / 2,
            boardOffset.y + row * cellSize + cellSize / 2 - textPainter.height / 2,
          );
          textPainter.paint(canvas, offset);
        }
      }
    }
  }

  bool checkWin(String player) {
    for (int i = 0; i < 3; i++) {
      if ((board[i][0] == player && board[i][1] == player && board[i][2] == player) ||
          (board[0][i] == player && board[1][i] == player && board[2][i] == player)) {
        return true;
      }
    }

    if ((board[0][0] == player && board[1][1] == player && board[2][2] == player) ||
        (board[0][2] == player && board[1][1] == player && board[2][0] == player)) {
      return true;
    }

    return false;
  }

  bool isDraw() {
    for (var row in board) {
      if (row.contains('')) return false;
    }
    return true;
  }

  void resetBoard() {
    board = List.generate(3, (_) => List.filled(3, ''));
    currentPlayer = 'X';
    isGameOver = false;
    aiTimer?.stop();
  }

  void setGameMode(GameMode mode) {
    gameMode = mode;
    resetBoard();
      game.overlays.remove('SelectLevel');
    overlays.add('tictactoe');
  //  overlays.remove('SelectLevel');
  }
    void setGameModeOnline(GameMode mode) {
    gameMode = mode;
    resetBoard();
      game.overlays.remove('SelectLevel');
    overlays.add('onlineLobby');
  //  overlays.remove('SelectLevel');
  }

  @override
  void update(double dt) {
    super.update(dt);
    aiTimer?.update(dt);
  }
}