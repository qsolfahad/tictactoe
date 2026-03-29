import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';
import 'package:tictactoe/audio_manager.dart';

class GameUIOverlay extends StatefulWidget {
  final TicTacToeGame game;

  const GameUIOverlay({super.key, required this.game});

  @override
  State<GameUIOverlay> createState() => _GameUIOverlayState();
}
  String gameStatus = "Player X's turn";
class _GameUIOverlayState extends State<GameUIOverlay> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _winLineController;
  late AnimationController _winPulseController;
  bool _winAnimationPlayed = false;



  int _remainingSeconds = 10; // per turn countdown
  Timer? _turnTimer;

  void _resetRemainingTime() {
    _turnTimer?.cancel();
    _remainingSeconds = 10;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _winLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _winPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

   // _startTurnTimer(); // start immediately for Player X
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingSeconds = 10;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0 && !widget.game.isGameOver) {
          _remainingSeconds--;
        } else {
          // time up for current player
          timer.cancel();

          // If it's a human turn (X) or PvP mode, skip the human move
          if (widget.game.currentPlayer == 'X' || widget.game.gameMode == GameMode.pvp) {
            // auto play for the human (first empty cell)
            _skipPlayerMove();

            // update status after the auto-move
            _updateGameStatus();

            // If the game ended by the auto-move, stop
            if (widget.game.isGameOver) return;

            // If PvP -> continue with next player's timer
            if (widget.game.gameMode == GameMode.pvp) {
              _startTurnTimer();
              return;
            }

            // If single-player and after the auto-move it's AI's turn, let AI play (with a small delay to simulate thinking)
            if (widget.game.currentPlayer == 'O' && widget.game.gameMode != GameMode.pvp) {
              Future.delayed(const Duration(seconds: 1), () {
                if (!mounted || widget.game.isGameOver) return;
                setState(() {
                  widget.game.makeAiMove();
                  _updateGameStatus();
                  if (!widget.game.isGameOver) {
                    _startTurnTimer();
                  }
                });
              });
              return;
            }

            // Otherwise start next timer
            _startTurnTimer();
          } 
          // If it's the AI's turn and AI timed out -> skip AI move (AI loses its turn)
          else {
            // Show message and switch to next player (human)
            gameStatus = "AI ran out of time!";
            _updateGameStatus();

            // set current player to human 'X' (if your game class has a switchPlayer method, use that instead)
            widget.game.currentPlayer = 'X';

            if (!widget.game.isGameOver) {
              _startTurnTimer();
            }
          }
        }
      });
    });
  }

  void _stopTurnTimer() {

    _turnTimer?.cancel();
  }

  /// Attempts to fill the first empty cell for the current human player.
  /// Returns true if a move was made, false if board full / no move possible.
  bool _skipPlayerMove() {
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        if (widget.game.board[r][c] == '') {
          widget.game.makeMove(r, c);
          return true;
        }
      }
    }
    return false;
  }

  void _onCellTapped(int row, int col) {
    if (widget.game.isGameOver ||
        widget.game.board[row][col] != '' ||
        (widget.game.gameMode != GameMode.pvp &&
            widget.game.currentPlayer == 'O')) {
      return;
    }

    setState(() {
      AudioManager.instance.playTap();
      widget.game.makeMove(row, col);
      _updateGameStatus();

      if (!widget.game.isGameOver &&
          widget.game.gameMode != GameMode.pvp &&
          widget.game.currentPlayer == 'O') {
        // let the AI play after a small delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            widget.game.makeAiMove();
            _updateGameStatus();
            if (!widget.game.isGameOver) {
              _startTurnTimer();
            }
          });
        });
      } else {
        if (!widget.game.isGameOver) {
          _startTurnTimer();
        }
      }
    });
  }

  void _updateGameStatus() {
    setState(() {
      if (widget.game.isGameOver) {
        _stopTurnTimer();
        if (widget.game.checkWin('X')) {
          gameStatus = "Player X wins!";
        } else if (widget.game.checkWin('O')) {
          gameStatus = "Player O wins!";
        } else {
          gameStatus = "It's a draw!";
        }

        if (widget.game.winningLine != null && !_winAnimationPlayed) {
          _winAnimationPlayed = true;
          _winLineController.forward(from: 0);
          _winPulseController.repeat(reverse: true);
        }
      } else {
        gameStatus = widget.game.currentPlayer == 'X'
            ? "Player X's turn"
            : widget.game.gameMode == GameMode.pvp
                ? "Player O's turn"
                : "AI is thinking...";
        if (_winAnimationPlayed) {
          _winAnimationPlayed = false;
          _winLineController.reset();
          _winPulseController.stop();
          _winPulseController.reset();
        }
      }
    });
  }

  void _animateButton() {
    _animationController.reset();
    _animationController.forward();
  }

  String _labelForPlayer(String symbol) {
    switch (widget.game.gameMode) {
      case GameMode.pvp:
        return symbol == 'X' ? 'Player 1' : 'Player 2';
      case GameMode.easyAI:
        return symbol == 'X' ? 'Player 1' : 'AI (Easy)';
      case GameMode.hardAI:
        return symbol == 'X' ? 'Player 1' : 'AI (Hard)';
      case GameMode.online:
        return symbol == 'X' ? 'Player 1' : 'Opponent';
    }
  }

  Widget _buildSessionScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(2, 3),
          )
        ],
      ),
      child: Row(
        children: [
          _scorePill(
            label: _labelForPlayer('X'),
            value: widget.game.sessionWinsX,
            color: const Color(0xff5C6BC0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'D ${widget.game.sessionDraws}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'ps2',
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _scorePill(
            label: _labelForPlayer('O'),
            value: widget.game.sessionWinsO,
            color: const Color(0xff26A69A),
          ),
        ],
      ),
    );
  }

  Widget _scorePill({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ps2',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'ps2',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff299FF0),
      body: Stack(
        children: [
          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () {
               _resetRemainingTime();
                //  _animationController.dispose();
                widget.game.overlays.remove('playGame');
                widget.game.overlays.add('SelectLevel');
              },
              child: Image.asset('assets/back.png', width: 40),
            ),
          ),
          Positioned(top: 100, left: 20, child: Image.asset('assets/1.png', width: 80)),
          Positioned(top: 100, right: 0, child: Image.asset('assets/2.png', width: 120)),
          Positioned(bottom: 60, child: Image.asset('assets/3.png', width: 150)),
          Positioned(bottom: 0, right: 0, child: Image.asset('assets/4.png', width: 120)),

          // Game Board
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/board.png', fit: BoxFit.fill),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _winLineController,
                        _winPulseController,
                      ]),
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _WinningLinePainter(
                            winningLine: widget.game.winningLine,
                            progress: _winLineController.value,
                            pulse: _winPulseController.value,
                          ),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int row = 0; row < 3; row++)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int col = 0; col < 3; col++)
                              GestureDetector(
                                onTap: () => _onCellTapped(row, col),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: row == 0
                                          ? BorderSide.none
                                          : const BorderSide(color: Colors.grey, width: 1),
                                      left: col == 0
                                          ? BorderSide.none
                                          : const BorderSide(color: Colors.grey, width: 1),
                                      right: col == 2
                                          ? BorderSide.none
                                          : const BorderSide(color: Colors.grey, width: 1),
                                      bottom: row == 2
                                          ? BorderSide.none
                                          : const BorderSide(color: Colors.grey, width: 1),
                                    ),
                                  ),
                                  child: Center(
                                    child: widget.game.board[row][col] == 'X'
                                        ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.asset('assets/x.png'),
                                          )
                                        : widget.game.board[row][col] == 'O'
                                            ? Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Image.asset('assets/o.png'),
                                              )
                                            : Container(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Status
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                gameStatus,
                style: const TextStyle(color: Colors.white,fontFamily: 'ps2', fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Countdown
            // Countdown over board image, centered
             Positioned(
            top: 220,
            left: 0,
            right: 0,
            child:  Center(
            child: SizedBox(
              width: 150,
              height: 80,
              child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '0:$_remainingSeconds s',
                  style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ps2',
                  shadows: [
                    Shadow(
                    blurRadius: 8,
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    ),
                  ],
                  ),
                ),
              ),
              ),
            ),
            ),),

          // Current player image
          widget.game.currentPlayer == 'X'
              ? Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: SizedBox(width: 60, height: 60, child: Image.asset('assets/x.png')),
                )
              : Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: SizedBox(width: 60, height: 60, child: Image.asset('assets/o.png')),
                ),

          // Buttons
          Positioned(
            bottom: 96,
            left: 0,
            right: 0,
            child: Center(child: _buildSessionScore()),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: ElevatedButton(
                    onPressed: () {
                      _animateButton();
                      widget.game.resetBoard();
                      _stopTurnTimer();
                      _updateGameStatus();
                      _startTurnTimer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Restart', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {

    _animationController.dispose();
    _winLineController.dispose();
    _winPulseController.dispose();
    _stopTurnTimer();
    super.dispose();
  }
}

class _WinningLinePainter extends CustomPainter {
  final List<int>? winningLine;
  final double progress;
  final double pulse;

  _WinningLinePainter({
    required this.winningLine,
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (winningLine == null || winningLine!.length < 2) return;
    final glowPaint = Paint()
      ..color = Colors.amber.withOpacity(0.45 + 0.25 * pulse)
      ..strokeWidth = 14 + 4 * pulse
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final linePaint = Paint()
      ..color = Colors.amber.withOpacity(0.9)
      ..strokeWidth = 6 + 2 * pulse
      ..strokeCap = StrokeCap.round;

    final start = _centerForIndex(winningLine!.first, size);
    final end = _centerForIndex(winningLine!.last, size);
    final current = Offset.lerp(start, end, progress) ?? start;
    canvas.drawLine(start, current, glowPaint);
    canvas.drawLine(start, current, linePaint);
  }

  Offset _centerForIndex(int index, Size size) {
    final row = index ~/ 3;
    final col = index % 3;
    final cellSize = size.width / 3;
    return Offset(
      (col + 0.5) * cellSize,
      (row + 0.5) * cellSize,
    );
  }

  @override
  bool shouldRepaint(covariant _WinningLinePainter oldDelegate) {
    return oldDelegate.winningLine != winningLine ||
        oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse;
  }
}
