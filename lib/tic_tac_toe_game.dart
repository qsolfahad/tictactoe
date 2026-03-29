import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/audio_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tictactoe/user_profile.dart';
class TicTacToeGame extends FlameGame with TapDetector, HasGameRef {
  late double cellSize;
  late Vector2 boardOffset;
  List<List<String>> board = List.generate(3, (_) => List.filled(3, ''));
  String currentPlayer = 'X';
  bool isGameOver = false;
  GameMode gameMode = GameMode.pvp;
  Timer? aiTimer;
  final Map<String, PlayerStats> _stats = {};
  List<int>? winningLine;
  bool _gameOverOverlayScheduled = false;
  int sessionWinsX = 0;
  int sessionWinsO = 0;
  int sessionDraws = 0;

  List<PlayerStats> getRankings() {
    final rankings = _stats.values.toList();
    rankings.sort((a, b) {
      if (a.wins != b.wins) return b.wins.compareTo(a.wins);
      if (a.losses != b.losses) return a.losses.compareTo(b.losses);
      return b.draws.compareTo(a.draws);
    });
    return rankings;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _loadUserProfile();
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
    
    final line = _findWinningLine(currentPlayer);
    if (line != null) {
      isGameOver = true;
      winningLine = line;
      _recordWin(currentPlayer);
      AudioManager.instance.playVictory();
      _scheduleGameOverOverlay();
    } else if (isDraw()) {
      isGameOver = true;
      winningLine = null;
      _recordDraw();
      _scheduleGameOverOverlay();
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
    return _findWinningLine(player) != null;
  }

  List<int>? _findWinningLine(String player) {
    for (int row = 0; row < 3; row++) {
      if (board[row][0] == player && board[row][1] == player && board[row][2] == player) {
        return [row * 3, row * 3 + 1, row * 3 + 2];
      }
    }
    for (int col = 0; col < 3; col++) {
      if (board[0][col] == player && board[1][col] == player && board[2][col] == player) {
        return [col, col + 3, col + 6];
      }
    }
    if (board[0][0] == player && board[1][1] == player && board[2][2] == player) {
      return [0, 4, 8];
    }
    if (board[0][2] == player && board[1][1] == player && board[2][0] == player) {
      return [2, 4, 6];
    }
    return null;
  }

  void _scheduleGameOverOverlay() {
    if (_gameOverOverlayScheduled) return;
    _gameOverOverlayScheduled = true;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (isGameOver) {
        overlays.add('GameOver');
      }
    });
  }

  bool isDraw() {
    for (var row in board) {
      if (row.contains('')) return false;
    }
    return true;
  }

  void _recordWin(String winnerSymbol) {
    final winnerName = _playerNameForSymbol(winnerSymbol);
    final loserName = _playerNameForSymbol(winnerSymbol == 'X' ? 'O' : 'X');
    final winnerStats = _stats.putIfAbsent(winnerName, () => PlayerStats(winnerName));
    final loserStats = _stats.putIfAbsent(loserName, () => PlayerStats(loserName));
    winnerStats.wins += 1;
    loserStats.losses += 1;
    _updateFirestoreForUser(
      wins: winnerSymbol == 'X' ? 1 : 0,
      losses: winnerSymbol == 'X' ? 0 : 1,
      draws: 0,
    );
    _updateFirestoreAiResult(
      win: winnerSymbol == 'X' ? 1 : 0,
      loss: winnerSymbol == 'X' ? 0 : 1,
      draw: 0,
    );
    if (winnerSymbol == 'X') {
      sessionWinsX += 1;
    } else {
      sessionWinsO += 1;
    }
  }

  void _recordDraw() {
    final playerX = _stats.putIfAbsent(_playerNameForSymbol('X'), () => PlayerStats(_playerNameForSymbol('X')));
    final playerO = _stats.putIfAbsent(_playerNameForSymbol('O'), () => PlayerStats(_playerNameForSymbol('O')));
    playerX.draws += 1;
    playerO.draws += 1;
    _updateFirestoreForUser(wins: 0, losses: 0, draws: 1);
    _updateFirestoreAiResult(win: 0, loss: 0, draw: 1);
    sessionDraws += 1;
  }

  void resetSessionScore() {
    sessionWinsX = 0;
    sessionWinsO = 0;
    sessionDraws = 0;
  }

  Future<void> _loadUserProfile() async {
    await UserProfile.getUserId();
  }

  void _updateFirestoreForUser({
    required int wins,
    required int losses,
    required int draws,
  }) {
    UserProfile.getUserId().then((userId) async {
      final name = await UserProfile.getDisplayName();
      FirebaseFirestore.instance.collection('leaderboard').doc(userId).set({
        'name': name,
        'wins': FieldValue.increment(wins),
        'losses': FieldValue.increment(losses),
        'draws': FieldValue.increment(draws),
      }, SetOptions(merge: true));
    });
  }

  void _updateFirestoreAiResult({
    required int win,
    required int loss,
    required int draw,
  }) {
    if (gameMode != GameMode.easyAI && gameMode != GameMode.hardAI) return;
    final isEasy = gameMode == GameMode.easyAI;
    UserProfile.getUserId().then((userId) async {
      final name = await UserProfile.getDisplayName();
      FirebaseFirestore.instance.collection('leaderboard').doc(userId).set({
        'name': name,
        isEasy ? 'ai_easy_wins' : 'ai_hard_wins': FieldValue.increment(win),
        isEasy ? 'ai_easy_losses' : 'ai_hard_losses': FieldValue.increment(loss),
        isEasy ? 'ai_easy_draws' : 'ai_hard_draws': FieldValue.increment(draw),
      }, SetOptions(merge: true));
    });
  }

  String _playerNameForSymbol(String symbol) {
    if (gameMode == GameMode.pvp) {
      return symbol == 'X' ? 'Player 1' : 'Player 2';
    }
    if (gameMode == GameMode.easyAI) {
      return symbol == 'X' ? 'Player 1' : 'AI (Easy)';
    }
    if (gameMode == GameMode.hardAI) {
      return symbol == 'X' ? 'Player 1' : 'AI (Hard)';
    }
    return symbol == 'X' ? 'Player 1' : 'Opponent';
  }

  void resetBoard() {
    board = List.generate(3, (_) => List.filled(3, ''));
    currentPlayer = 'X';
    isGameOver = false;
    winningLine = null;
    _gameOverOverlayScheduled = false;
    aiTimer?.stop();
  }

  void setGameMode(GameMode mode) {
    gameMode = mode;
    resetSessionScore();
    resetBoard();
    AudioManager.instance.stopBgm();
      game.overlays.remove('SelectLevel');
    overlays.add('tictactoe');
  //  overlays.remove('SelectLevel');
  }
    void setGameModeOnline(GameMode mode) {
    gameMode = mode;
    resetSessionScore();
    resetBoard();
     AudioManager.instance.stopBgm();
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

class PlayerStats {
  final String name;
  int wins;
  int losses;
  int draws;

  PlayerStats(this.name, {this.wins = 0, this.losses = 0, this.draws = 0});
}