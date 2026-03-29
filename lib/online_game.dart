import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/audio_manager.dart';
import 'package:tictactoe/user_profile.dart';

class OnlineGamePage extends StatefulWidget {
  final String lobbyId;
  final String playerSymbol;
  final String playerName;
  final String opponentName;
  final bool isHost;

  const OnlineGamePage({
    super.key,
    required this.lobbyId,
    required this.playerSymbol,
    required this.playerName,
    required this.opponentName,
    required this.isHost,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _victoryPlayed = false;
  bool _resultRecorded = false;
  bool _leftHandled = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  final Set<String> _seenMessageIds = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestMessageDocs = [];
  int _unreadCount = 0;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  List<String> _parseBoard(dynamic value) {
    if (value is List) {
      return value.map((cell) => cell?.toString() ?? '').toList(growable: false);
    }
    return List.filled(9, '');
  }

  String? _checkWinner(List<String> board) {
    const wins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final combo in wins) {
      final a = board[combo[0]];
      if (a.isNotEmpty && a == board[combo[1]] && a == board[combo[2]]) {
        return a;
      }
    }
    return null;
  }

  Future<void> _makeMove({
    required int index,
    required List<String> board,
    required String turn,
    required bool ended,
  }) async {
    if (ended || board[index].isNotEmpty || turn != widget.playerSymbol) return;

    final nextBoard = List<String>.from(board);
    nextBoard[index] = widget.playerSymbol;
    AudioManager.instance.playTap();

    final winner = _checkWinner(nextBoard);
    final isDraw = winner == null && !nextBoard.contains('');
    final nextTurn = widget.playerSymbol == 'X' ? 'O' : 'X';

    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'board': nextBoard,
      'turn': (winner != null || isDraw) ? turn : nextTurn,
      'winner': winner ?? (isDraw ? 'draw' : null),
      'ended': winner != null || isDraw,
    });
  }

  void _listenForMessages() {
    _messagesSub = _firestore
        .collection('lobbies')
        .doc(widget.lobbyId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _latestMessageDocs = snapshot.docs;
      if (_isChatOpen) {
        _markAllSeen();
        if (mounted) {
          setState(() => _unreadCount = 0);
        }
        return;
      }
      final unread = snapshot.docs.where((doc) {
        final data = doc.data();
        final sender = (data['sender'] ?? '').toString();
        return sender.isNotEmpty &&
            sender != widget.playerName &&
            !_seenMessageIds.contains(doc.id);
      }).length;
      print('unread: $unread');
      if (mounted) {
        setState(() => _unreadCount = unread);
      }
    });
  }

  void _markAllSeen() {
    for (final doc in _latestMessageDocs) {
      _seenMessageIds.add(doc.id);
    }
  }

  Future<void> _openChat() async {
    _isChatOpen = true;
    _markAllSeen();
    setState(() => _unreadCount = 0);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineChatPage(
          lobbyId: widget.lobbyId,
          playerName: widget.playerName,
        ),
      ),
    );
    _isChatOpen = false;
    _markAllSeen();
    if (mounted) {
      setState(() => _unreadCount = 0);
    }
  }

  String _statusText(String turn, String? winner) {
    if (winner == 'draw') {
      return "It's a draw!";
    }
    if (winner == widget.playerSymbol) {
      return 'You won!';
    }
    if (winner != null) {
      return 'You lost!';
    }
    return turn == widget.playerSymbol ? "Your turn" : "${widget.opponentName}'s turn";
  }

  Future<void> _restartGame() async {
    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'board': List.filled(9, ''),
      'turn': 'X',
      'winner': null,
      'ended': false,
      'leftBy': null,
      'scoreUpdated': false,
    });
  }

  Future<void> _leaveMatch() async {
    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'leftBy': widget.playerName,
      'ended': true,
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _updateFirestoreResult({
    required int win,
    required int loss,
    required int draw,
  }) {
    UserProfile.getUserId().then((userId) async {
      final name = await UserProfile.getDisplayName();
      FirebaseFirestore.instance.collection('leaderboard').doc(userId).set({
        'name': name,
        'wins': FieldValue.increment(win),
        'losses': FieldValue.increment(loss),
        'draws': FieldValue.increment(draw),
      }, SetOptions(merge: true));
    });
  }

  void _updateLobbyScore({required String winner}) {
    final update = <String, Object>{};
    if (winner == 'X') {
      update['scoreX'] = FieldValue.increment(1);
    } else if (winner == 'O') {
      update['scoreO'] = FieldValue.increment(1);
    } else if (winner == 'draw') {
      update['scoreDraws'] = FieldValue.increment(1);
    }
    if (update.isNotEmpty) {
      print('updateLobbyScore: ${update['scoreX']}');
      update['scoreUpdated'] = true;
      _firestore.collection('lobbies').doc(widget.lobbyId).update(update);
    }
  }

  Widget _buildMatchScore(Map<String, dynamic> data) {
    final scoreX = (data['scoreX'] ?? 0) as num;
    final scoreO = (data['scoreO'] ?? 0) as num;
    final scoreDraws = (data['scoreDraws'] ?? 0) as num;
    final xName = widget.playerSymbol == 'X' ? widget.playerName : widget.opponentName;
    final oName = widget.playerSymbol == 'O' ? widget.playerName : widget.opponentName;

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
          _scorePill(label: xName, value: scoreX.toInt(), color: const Color(0xff5C6BC0)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'D ${scoreDraws.toInt()}',
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
          _scorePill(label: oName, value: scoreO.toInt(), color: const Color(0xff26A69A)),
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
            style: const TextStyle(
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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: _leaveMatch,
                child: Image.asset('assets/back.png', width: 40),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: InkWell(
                onTap: _openChat,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chat, color: Colors.amber),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('lobbies').doc(widget.lobbyId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                }
                final data = snapshot.data?.data();
                if (data == null) {
                  return const Center(
                    child: Text(
                      'Lobby not found',
                      style: TextStyle(fontFamily: 'ps2', color: Colors.white),
                    ),
                  );
                }

                final board = _parseBoard(data['board']);
                final turn = (data['turn'] ?? 'X').toString();
                final winner = data['winner']?.toString();
                final ended = data['ended'] == true || winner != null;
                final leftBy = (data['leftBy'] ?? '').toString();
                final scoreUpdated = data['scoreUpdated'] == true;

                if (!_leftHandled && leftBy.isNotEmpty && leftBy != widget.playerName) {
                  _leftHandled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Opponent disconnected'),
                        content: Text('$leftBy left the match.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  });
                }

                if (winner == widget.playerSymbol && !_victoryPlayed) {
                  _victoryPlayed = true;
                  AudioManager.instance.playVictory();
                  if (!_resultRecorded) {
                    _resultRecorded = true;
                    _updateFirestoreResult(win: 1, loss: 0, draw: 0);
                    if (widget.isHost && !scoreUpdated) {
                      final winnerSymbol = winner ?? widget.playerSymbol;
                      _updateLobbyScore(winner: winnerSymbol);
                    }
                  }
                } else if (winner == null || winner == 'draw') {
                  _victoryPlayed = false;
                  if (winner == null) {
                    _resultRecorded = false;
                  } else if (!_resultRecorded) {
                    _resultRecorded = true;
                    if (turn == widget.playerSymbol) {
                      _updateFirestoreResult(win: 0, loss: 0, draw: 1);
                    }
                    if (widget.isHost && !scoreUpdated) {
                      _updateLobbyScore(winner: 'draw');
                    }
                  }
                } else if (winner != widget.playerSymbol) {
                  if (!_resultRecorded) {
                    _resultRecorded = true;
                    if (widget.isHost && !scoreUpdated) {
                      _updateLobbyScore(winner: winner);
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.playerName} (${widget.playerSymbol}) vs ${widget.opponentName} (${widget.playerSymbol == 'X' ? 'O' : 'X'})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ps2',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMatchScore(data),
                      const SizedBox(height: 12),
                      Text(
                        _statusText(turn, winner),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ps2',
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset('assets/board.png', fit: BoxFit.fill),
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
                                              onTap: () => _makeMove(
                                                index: row * 3 + col,
                                                board: board,
                                                turn: turn,
                                                ended: ended,
                                              ),
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
                                                  child: board[row * 3 + col] == 'X'
                                                      ? Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Image.asset('assets/x.png'),
                                                        )
                                                      : board[row * 3 + col] == 'O'
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
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: ended ? _restartGame : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Restart',
                                style: TextStyle(
                                  fontFamily: 'ps2',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.amber,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _leaveMatch,
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text(
                                'Leave',
                                style: TextStyle(
                                  fontFamily: 'ps2',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }

}

class OnlineChatPage extends StatefulWidget {
  final String lobbyId;
  final String playerName;

  const OnlineChatPage({
    super.key,
    required this.lobbyId,
    required this.playerName,
  });

  @override
  State<OnlineChatPage> createState() => _OnlineChatPageState();
}

class _OnlineChatPageState extends State<OnlineChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _chatController = TextEditingController();
  final List<String> _quickEmojis = const ['😀', '😅', '😎', '🔥', '👏', '😢', '😡', '❤️'];

  Future<void> _sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty) return;
    await _firestore
        .collection('lobbies')
        .doc(widget.lobbyId)
        .collection('messages')
        .add({
      'sender': widget.playerName,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _chatController.clear();
  }

  @override
  void dispose() {
    _chatController.dispose();
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
                onTap: () => Navigator.of(context).pop(),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ps2',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          )
                        ],
                      ),
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _firestore
                            .collection('lobbies')
                            .doc(widget.lobbyId)
                            .collection('messages')
                            .orderBy('createdAt', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, msgSnapshot) {
                          final docs = msgSnapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontFamily: 'ps2',
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            reverse: true,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final sender = (data['sender'] ?? '').toString();
                              final text = (data['text'] ?? '').toString();
                              final isMe = sender == widget.playerName;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Colors.amber.shade200
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isMe ? text : '$sender: $text',
                                            softWrap: true,
                                            style: const TextStyle(
                                              fontFamily: 'ps2',
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickEmojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final emoji = _quickEmojis[index];
                        return InkWell(
                          onTap: () => _sendMessage(emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'Type message',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _sendMessage(_chatController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.amber,
                          minimumSize: const Size(48, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
