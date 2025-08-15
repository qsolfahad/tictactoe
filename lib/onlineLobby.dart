import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineLobby extends StatefulWidget {
  final String playerName;

  const OnlineLobby({Key? key, required this.playerName}) : super(key: key);

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  String? lobbyId;
  bool isHost = false;
  bool gameStarted = false;
  String? opponentName;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createLobby() async {
    DocumentReference lobbyRef = await _firestore.collection('lobbies').add({
      'host': widget.playerName,
      'guest': null,
      'started': false,
      'board': List.filled(9, ''), // Empty board
      'turn': 'X',
    });
    setState(() {
      lobbyId = lobbyRef.id;
      isHost = true;
    });
    listenForOpponent(lobbyRef.id);
  }

  Future<void> joinLobby(String id) async {
    DocumentReference lobbyRef = _firestore.collection('lobbies').doc(id);
    DocumentSnapshot snapshot = await lobbyRef.get();

    if (snapshot.exists && snapshot['guest'] == null) {
      await lobbyRef.update({'guest': widget.playerName, 'started': true});
      setState(() {
        lobbyId = id;
        isHost = false;
      });
      listenForGameStart(id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lobby not found or already full")),
      );
    }
  }

  void listenForOpponent(String id) {
    _firestore.collection('lobbies').doc(id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['guest'] != null) {
        setState(() {
          opponentName = snapshot['guest'];
          gameStarted = true;
        });
        // Navigate to game screen here
      }
    });
  }

  void listenForGameStart(String id) {
    _firestore.collection('lobbies').doc(id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['started'] == true) {
        setState(() {
          opponentName = snapshot['host'];
          gameStarted = true;
        });
        // Navigate to game screen here
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameStarted) {
      return Center(
        child: Text(
          "Game starting with $opponentName...",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Online Lobby")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: createLobby,
              child: const Text("Create Lobby"),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: "Enter Lobby ID"),
              onSubmitted: joinLobby,
            ),
            const SizedBox(height: 20),
            if (lobbyId != null && !gameStarted)
              Text("Waiting for opponent... Lobby ID: $lobbyId"),
          ],
        ),
      ),
    );
  }
}
