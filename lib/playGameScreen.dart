
import 'package:flutter/material.dart';
import 'package:tictactoe/main.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlayGameOverlay extends StatelessWidget {
  final TicTacToeGame game;
  const PlayGameOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xff299FF0),
  body: Stack(
    children: [
     
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
        Image.asset('asset/LogoGame.png', width: 200),
        const SizedBox(height: 50),
        InkWell(
          onTap: () {
            game.resetBoard();
            game.overlays.remove('playGame');
            game.overlays.add('SelectLevel');
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('asset/button.png', width: 300),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                
                children: [
                   Text(
                    'Play ',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'ps2',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SvgPicture.asset('asset/play.svg', width: 24),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
         Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('asset/button.png', width: 300),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Setting ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                        fontFamily: 'ps2',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 SvgPicture.asset('asset/setting.svg', width: 24),
              ],
            ),
          ],
        ),
          ]
        ),
      ),
    ],
  ),
);

  }
  }
