import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';

class SelectLevelOverlay extends StatelessWidget {
  final TicTacToeGame game;
  const SelectLevelOverlay({super.key, required this.game});

  Widget _buildLevelButton(TicTacToeGame game, String prefix, String label, VoidCallback onPressed) {
    return SizedBox(
      width: 320,
      child: GestureDetector(
        onTap: onPressed,
        
     
        child: Column(
          children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('asset/button.png', width: 400),
              
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                    fontFamily: 'ps2',
                fontSize: 12,
              ),
            ),
            ])
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xff299FF0),
  body: Stack(
    children: [
      // Top-left corner
    
       Positioned(
         top: 50,
         left: 20,
         child: InkWell(
           onTap: () {
             game.overlays.remove('SelectLevel');
             game.overlays.add('playGame');
           },
           child: Image.asset('asset/back.png', width: 40),
         ),
       ),
      Positioned(
        top: 100,
        left: 20,
        child: Image.asset('asset/1.png', width: 80),
      ),

      // Top-right corner
      Positioned(
        top: 100,
        right: 0,
        child: Image.asset('asset/2.png', width: 120),
      ),

      // Bottom-left corner
      Positioned(
        bottom: 60,
       // left: 20,
        child: Image.asset('asset/3.png', width: 150),
      ),

      // Bottom-right corner
      Positioned(
        bottom: 0,
        right: 0,
        child: Image.asset('asset/4.png', width: 120),
      ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset('asset/logo.png', width: 200),
          ),
        ),

      // Main content in the center
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
        Image.asset('asset/selectlevel.png',width: 250,),
            const SizedBox(height: 60),
             _buildLevelButton(game, 'VS', 'Online Multiplayer', () {
  game.setGameModeOnline(GameMode.online);
  // You’d create this overlay
}),
const SizedBox(height: 30),
            _buildLevelButton(game, 'VS', 'Player vs Player', () {
              game.setGameMode(GameMode.pvp);
            }),
            const SizedBox(height: 30),
            _buildLevelButton(game, 'VS', 'Player vs AI (Easy)', () {
              game.setGameMode(GameMode.easyAI);
            }),
            const SizedBox(height: 30),
            _buildLevelButton(game, 'VS', 'Player vs AI (Hard)', () {
              game.setGameMode(GameMode.hardAI);
            }),
           

          ],
        ),
      ),
    ],
  ),
);

  }
  }