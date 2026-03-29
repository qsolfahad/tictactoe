import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tictactoe/tic_tac_toe_game.dart';

class ScoreboardPage extends StatelessWidget {
  final TicTacToeGame game;
  const ScoreboardPage({super.key, required this.game});

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
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Image.asset('assets/back.png', width: 40),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Image.asset('assets/trophy.png', width: 40),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Scoreboard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ps2',
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 3),
                          )
                        ],
                      ),
                      child: _RankingsList(game: game),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      game.resetBoard();
                      game.overlays.remove('GameOver');
                      game.overlays.add('SelectLevel');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'ps2',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.grey.shade400;
    } else if (rank == 3) {
      color = const Color(0xffcd7f32);
    } else {
      color = Colors.blueGrey.shade200;
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          fontFamily: 'ps2',
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RankingsList extends StatelessWidget {
  final TicTacToeGame game;
  const _RankingsList({required this.game});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('wins', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No games played yet',
              style: TextStyle(
                fontFamily: 'ps2',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final rawName = (data['name'] ?? '').toString().trim();
            final name = rawName.isEmpty ? 'Anonymous' : rawName;
            final wins = (data['wins'] ?? 0) as num;
            final losses = (data['losses'] ?? 0) as num;
            final draws = (data['draws'] ?? 0) as num;
            return Row(
              children: [
                _RankBadge(rank: index + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'ps2',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  'W ${wins.toInt()}  L ${losses.toInt()}  D ${draws.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'ps2',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Opponents list removed
