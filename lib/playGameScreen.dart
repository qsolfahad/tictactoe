
import 'package:flutter/material.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tictactoe/settings_page.dart';
import 'package:tictactoe/audio_manager.dart';
import 'package:tictactoe/scoreboard.dart';

class PlayGameOverlay extends StatefulWidget {
  final TicTacToeGame game;
  const PlayGameOverlay({super.key, required this.game});

  @override
  State<PlayGameOverlay> createState() => _PlayGameOverlayState();
}

class _PlayGameOverlayState extends State<PlayGameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;


  @override
  void initState() {
    super.initState();
    AudioManager.instance.startBgm();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xff299FF0),
  body: Stack(
    children: [
     
      Positioned(
        top: 100,
        left: 20,
        child: Image.asset('assets/1.png', width: 80),
      ),

      // Top-right corner
      Positioned(
        top: 100,
        right: 0,
        child: Image.asset('assets/2.png', width: 120),
      ),

      // Bottom-left corner
      Positioned(
        bottom: 60,
       // left: 20,
        child: Image.asset('assets/3.png', width: 150),
      ),

      // Bottom-right corner
      Positioned(
        bottom: 0,
        right: 0,
        child: Image.asset('assets/4.png', width: 120),
      ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset('assets/logo.png', width: 200),
          ),
        ),

      // Main content in the center
      Center(
        child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offsetY = (1 - _floatController.value) * 26;
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: child,
            );
          },
          child: Image.asset('assets/LogoGame.png', width: 200),
        ),
        const SizedBox(height: 50),
        InkWell(
          onTap: () {
            widget.game.resetBoard();
            widget.game.overlays.remove('playGame');
            widget.game.overlays.add('SelectLevel');
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/button.png', width: 300),
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
                  SvgPicture.asset('assets/play.svg', width: 24),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
         InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/button.png', width: 300),
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
                  SvgPicture.asset('assets/setting.svg', width: 24),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ScoreboardPage(game: widget.game)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.blue.withOpacity(0.2),
          highlightColor: Colors.blue.withOpacity(0.1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/button.png', width: 300),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Scoreboard ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'ps2',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.leaderboard, color: Colors.black, size: 22),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    ],
  ),
);

  }
  }
