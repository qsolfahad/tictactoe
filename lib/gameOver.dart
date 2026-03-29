import 'package:flutter/material.dart';
import 'package:tictactoe/gameUI.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/scoreboard.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';

class GameOverOverlay extends StatelessWidget {
  final TicTacToeGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    String winnerText;
    if (game.checkWin('X')) {
      winnerText = 'Player 1\nYOU WON';
    } else if (game.checkWin('O')) {
      winnerText = game.gameMode == GameMode.pvp
          ? 'Player 2\nYOU WON'
          : 'AI\nWON';
    } else {
      winnerText = 'IT\'S A DRAW';
    }

    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),

    
            // Winner card
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/board.png',
                          width: 100,
                          height: 100,
                        ),
                        Image.asset(
                          'assets/trophy.png',
                       
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      winnerText.split('\n').first,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      winnerText.contains('\n') ? winnerText.split('\n').last : '',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRoundButton(
                          icon: Icons.home,
                          onTap: () {
                            game.resetBoard();
                            gameStatus = "Player X's turn";
                            game.overlays.remove('GameOver');
                            game.overlays.add('SelectLevel');
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildRoundButton(
                          icon: Icons.refresh,
                          onTap: () {
                            game.resetBoard();
                              gameStatus = "Player X's turn";
                     
                             game.overlays.remove('GameOver');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scoreboard button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScoreboardPage(game: game),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text(
                  "Scoreboard",
                  style: TextStyle(fontSize: 18,fontFamily: 'ps2',   fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 28),
      ),
    );
  }
}
