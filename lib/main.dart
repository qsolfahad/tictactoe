
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/gameOver.dart';
import 'package:tictactoe/gameUI.dart';
import 'package:tictactoe/onlineLobby.dart';
import 'package:tictactoe/playGameScreen.dart';
import 'package:tictactoe/selectLevel.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
await  Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "1:357199107879:android:2ae60e695071f0751b7b02",
      messagingSenderId: "357199107879",
      projectId: "tictactoe-345b9",
    ),
);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget<TicTacToeGame>(
        game: TicTacToeGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverOverlay(game: game as TicTacToeGame),
          'playGame': (context, game) => PlayGameOverlay(game: game as TicTacToeGame),
          'tictactoe': (context, game) => GameUIOverlay(game: game as TicTacToeGame),
          'onlineLobby': (context, game) => OnlineLobby(playerName: ''),
          'SelectLevel': (context, game) => SelectLevelOverlay(game: game as TicTacToeGame),
        },
      ),
    ),
  );
}


enum GameMode { pvp, easyAI, hardAI, online }




