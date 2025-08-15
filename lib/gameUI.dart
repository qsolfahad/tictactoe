import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';

class GameUIOverlay extends StatefulWidget {
  final TicTacToeGame game;

  const GameUIOverlay({super.key, required this.game});

  @override
  State<GameUIOverlay> createState() => _GameUIOverlayState();
}
  String gameStatus = "Player X's turn";
class _GameUIOverlayState extends State<GameUIOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;



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
            bool moved = _skipPlayerMove();

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
      } else {
        gameStatus = widget.game.currentPlayer == 'X'
            ? "Player X's turn"
            : widget.game.gameMode == GameMode.pvp
                ? "Player O's turn"
                : "AI is thinking...";
      }
    });
  }

  void _animateButton() {
    _animationController.reset();
    _animationController.forward();
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
              child: Image.asset('asset/back.png', width: 40),
            ),
          ),
          Positioned(top: 100, left: 20, child: Image.asset('asset/1.png', width: 80)),
          Positioned(top: 100, right: 0, child: Image.asset('asset/2.png', width: 120)),
          Positioned(bottom: 60, child: Image.asset('asset/3.png', width: 150)),
          Positioned(bottom: 0, right: 0, child: Image.asset('asset/4.png', width: 120)),

          // Game Board
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset('asset/board.png', fit: BoxFit.fill),
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
                                            child: Image.asset('asset/x.png'),
                                          )
                                        : widget.game.board[row][col] == 'O'
                                            ? Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Image.asset('asset/o.png'),
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
                  child: SizedBox(width: 60, height: 60, child: Image.asset('asset/x.png')),
                )
              : Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: SizedBox(width: 60, height: 60, child: Image.asset('asset/o.png')),
                ),

          // Buttons
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
    _stopTurnTimer();
    super.dispose();
  }
}
