import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tictactoe/online_game.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';
import 'package:tictactoe/user_profile.dart';

class OnlineLobby extends StatefulWidget {
  final TicTacToeGame game;
  final String playerName;

  const OnlineLobby({Key? key, required this.game, required this.playerName}) : super(key: key);

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  String? lobbyId;
  bool isHost = false;
  bool gameStarted = false;
  String? opponentName;
  bool _navigatedToGame = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _lobbySub;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _joinController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    UserProfile.getDisplayName().then((name) {
      if (!mounted) return;
      if (name.trim().isNotEmpty && _nameController.text.trim().isEmpty) {
        _nameController.text = name;
      }
    });
  }

  Future<void> createLobby() async {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    await UserProfile.setDisplayName(playerName);
    DocumentReference lobbyRef = await _firestore.collection('lobbies').add({
      'host': playerName,
      'guest': null,
      'started': false,
      'board': List.filled(9, ''), // Empty board
      'turn': (DateTime.now().millisecondsSinceEpoch % 2 == 0) ? 'X' : 'O',
      'winner': null,
      'ended': false,
      'scoreX': 0,
      'scoreO': 0,
      'scoreDraws': 0,
      'leftBy': null,
      'scoreUpdated': false,
    });
    setState(() {
      lobbyId = lobbyRef.id;
      isHost = true;
    });
    listenForOpponent(lobbyRef.id);
  }

  Future<void> joinLobby(String id) async {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    await UserProfile.setDisplayName(playerName);
    DocumentReference lobbyRef = _firestore.collection('lobbies').doc(id);
    DocumentSnapshot snapshot = await lobbyRef.get();

    if (snapshot.exists && snapshot['guest'] == null) {
      await lobbyRef.update({'guest': playerName, 'started': true});
      setState(() {
        lobbyId = id;
        isHost = false;
      });
      listenForGameStart(id);
    } else {
      _showMessage('Lobby not found or already full');
    }
  }

  void listenForOpponent(String id) {
    _lobbySub?.cancel();
    _lobbySub = _firestore.collection('lobbies').doc(id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['guest'] != null) {
        setState(() {
          opponentName = snapshot['guest'];
          gameStarted = true;
        });
        _openGame();
      }
    });
  }

  void listenForGameStart(String id) {
    _lobbySub?.cancel();
    _lobbySub = _firestore.collection('lobbies').doc(id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['started'] == true) {
        setState(() {
          opponentName = snapshot['host'];
          gameStarted = true;
        });
        _openGame();
      }
    });
  }

  void _openGame() {
    if (_navigatedToGame || lobbyId == null) return;
    _navigatedToGame = true;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => OnlineGamePage(
          lobbyId: lobbyId!,
          playerSymbol: isHost ? 'X' : 'O',
          playerName: _nameController.text.trim(),
          opponentName: opponentName ?? 'Opponent',
          isHost: isHost,
        ),
      ),
    )
        .then((_) {
      _navigatedToGame = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _copyLobbyCode() async {
    if (lobbyId == null) return;
    await Clipboard.setData(ClipboardData(text: lobbyId!));
    _showMessage('Lobby code copied');
  }

  Future<void> _shareLobbyCode() async {
    if (lobbyId == null) return;
    final message = 'Join my TicTacToe lobby copy and paste the Id: $lobbyId';
    await Share.share(message);
  }

  @override
  void dispose() {
    _lobbySub?.cancel();
    _nameController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff299FF0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: () {
                  widget.game.overlays.remove('onlineLobby');
                  widget.game.overlays.add('SelectLevel');
                },
                child: Image.asset('assets/back.png', width: 40),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                  const Text(
                    'Online Lobby',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ps2',
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff299FF0),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 3),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: createLobby,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Lobby',
                            style: TextStyle(fontFamily: 'ps2', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _joinController,
                          decoration: const InputDecoration(
                            labelText: 'Lobby ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => joinLobby(_joinController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Join Lobby',
                            style: TextStyle(fontFamily: 'ps2', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (lobbyId != null && !gameStarted) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for opponent...\nLobby ID: $lobbyId',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontFamily: 'ps2', fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _copyLobbyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.amber,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.copy),
                                  label: const Text(
                                    'Copy',
                                    style: TextStyle(fontFamily: 'ps2', fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareLobbyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.share),
                                  label: const Text(
                                    'Share',
                                    style: TextStyle(fontFamily: 'ps2', fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
