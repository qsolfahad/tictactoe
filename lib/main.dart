
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/gameOver.dart';
import 'package:tictactoe/gameUI.dart';
import 'package:tictactoe/onlineLobby.dart';
import 'package:tictactoe/playGameScreen.dart';
import 'package:tictactoe/selectLevel.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';
import 'package:tictactoe/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  }
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _NameGate(),
    );
  }
}

class _NameGate extends StatefulWidget {
  const _NameGate();

  @override
  State<_NameGate> createState() => _NameGateState();
}

class _NameGateState extends State<_NameGate> {
  late Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = UserProfile.getDisplayName();
  }

  void _onNameSaved() {
    setState(() {
      _nameFuture = UserProfile.getDisplayName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _nameFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xff299FF0),
            body: Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }
        final name = snapshot.data?.trim() ?? '';
        if (name.isEmpty) {
          return _NamePromptPage(onSaved: _onNameSaved);
        }
        return GameWidget<TicTacToeGame>(
          game: TicTacToeGame(),
          overlayBuilderMap: {
            'GameOver': (context, game) => GameOverOverlay(game: game),
            'playGame': (context, game) => PlayGameOverlay(game: game),
            'tictactoe': (context, game) => GameUIOverlay(game: game),
            'onlineLobby': (context, game) => OnlineLobby(game: game, playerName: ''),
            'SelectLevel': (context, game) => SelectLevelOverlay(game: game),
          },
        );
      },
    );
  }
}

class _NamePromptPage extends StatefulWidget {
  final VoidCallback onSaved;
  const _NamePromptPage({required this.onSaved});

  @override
  State<_NamePromptPage> createState() => _NamePromptPageState();
}

class _NamePromptPageState extends State<_NamePromptPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await UserProfile.setDisplayName(_controller.text);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff299FF0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: 20,
              child: Image.asset('assets/1.png', width: 80),
            ),
            Positioned(
              top: 100,
              right: 0,
              child: Image.asset('assets/2.png', width: 120),
            ),
            Positioned(
              bottom: 60,
              child: Image.asset('assets/3.png', width: 150),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset('assets/4.png', width: 120),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enter Your Name',
                      style: TextStyle(
                        fontFamily: 'ps2',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Your name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'ps2',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


enum GameMode { pvp, easyAI, hardAI, online }




