import 'package:flutter/material.dart';
import 'package:tictactoe/audio_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _musicEnabled = AudioManager.instance.bgmEnabled;
    _soundEnabled = AudioManager.instance.sfxEnabled;
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
                    'Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ps2',
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
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
                          SwitchListTile(
                            value: _soundEnabled,
                            onChanged: (value) {
                              setState(() => _soundEnabled = value);
                              AudioManager.instance.setSfxEnabled(value);
                            },
                            activeColor: Colors.amber,
                            activeTrackColor: Colors.amber.shade200,
                            inactiveThumbColor: Colors.black,
                            inactiveTrackColor: Colors.black26,
                            title: const Text(
                              'Sound Effects',
                              style: TextStyle(fontFamily: 'ps2', fontSize: 14),
                            ),
                          ),
                          SwitchListTile(
                            value: _musicEnabled,
                            onChanged: (value) {
                              setState(() => _musicEnabled = value);
                              AudioManager.instance.setBgmEnabled(value);
                              if (value) {
                                AudioManager.instance.startBgm();
                              }
                            },
                            activeColor: Colors.amber,
                            activeTrackColor: Colors.amber.shade200,
                            inactiveThumbColor: Colors.black,
                            inactiveTrackColor: Colors.black26,
                            title: const Text(
                              'Music',
                              style: TextStyle(fontFamily: 'ps2', fontSize: 14),
                            ),
                          ),
                          SwitchListTile(
                            value: _vibrationEnabled,
                            onChanged: (value) {
                              setState(() => _vibrationEnabled = value);
                            },
                            activeColor: Colors.amber,
                            activeTrackColor: Colors.amber.shade200,
                            inactiveThumbColor: Colors.black,
                            inactiveTrackColor: Colors.black26,
                            title: const Text(
                              'Vibration',
                              style: TextStyle(fontFamily: 'ps2', fontSize: 14),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Changes apply instantly',
                            style: TextStyle(
                              fontFamily: 'ps2',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
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
