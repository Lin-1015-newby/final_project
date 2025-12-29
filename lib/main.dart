import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: PomodoroTimer(),
));

class PomodoroTimer extends StatefulWidget {
  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int defaultTime = 1500;
  int _seconds = defaultTime;
  Timer? _timer;
  bool _isRunning = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundOn = true;

  String _currentCategory = 'rain';
  int _currentLevel = 1; // 1, 2, 3 輪流

  @override
  void initState() {
    super.initState();

    // 重點：監聽播放結束事件，實作自動輪流播放
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRunning && _isSoundOn) {
        _playNextSound();
      }
    });
  }

  // 核心邏輯：計算下一個音檔編號並播放
  void _playNextSound() async {
    setState(() {
      // 1 -> 2 -> 3 -> 1 循環
      _currentLevel = (_currentLevel % 3) + 1;
    });
    await _audioPlayer.play(AssetSource('sounds/$_currentFileName'));
  }

  String get _currentFileName => '${_currentCategory}_$_currentLevel.mp3';

  void _toggleTimer() async {
    if (_isRunning) {
      _timer?.cancel();
      await _audioPlayer.pause();
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _audioPlayer.stop();
          }
        });
      });
      if (_isSoundOn) {
        await _audioPlayer.play(AssetSource('sounds/$_currentFileName'));
      }
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _seconds = defaultTime;
      _isRunning = false;
      _currentLevel = 1; // 重置時回到第一個音檔
    });
  }

  // 手動切換
  void _manualUpdateSound(String category, int level) async {
    setState(() {
      _currentCategory = category;
      _currentLevel = level;
    });
    if (_isRunning && _isSoundOn) {
      await _audioPlayer.play(AssetSource('sounds/$_currentFileName'));
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _seconds / defaultTime;
    Color activeColor = _currentCategory == 'rain' ? Colors.blueAccent : Colors.greenAccent;

    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40),
            Text("FOCUS FLOW", style: TextStyle(letterSpacing: 4, color: Colors.white38)),
            Spacer(),

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260, height: 260,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTime(_seconds), style: TextStyle(fontSize: 72, fontWeight: FontWeight.w200)),
                    // 顯示目前正在播放哪一個音檔
                    Text("Playing: $_currentFileName", style: TextStyle(fontSize: 12, color: activeColor.withOpacity(0.5))),
                  ],
                ),
              ],
            ),

            Spacer(),

            Container(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _categoryIcon(Icons.umbrella, 'rain', Colors.blueAccent),
                      _categoryIcon(Icons.forest, 'forest', Colors.greenAccent),
                      _volumeToggle(),
                    ],
                  ),
                  SizedBox(height: 25),
                  Text("點擊下方切換起始音檔 (目前會自動輪播)", style: TextStyle(fontSize: 10, color: Colors.white24)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 2, 3].map((level) => _levelButton(level)).toList(),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _mainActionButton(),
                      SizedBox(width: 20),
                      IconButton(icon: Icon(Icons.refresh, color: Colors.white38), onPressed: _resetTimer),
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

  // --- UI Helper Widgets (與先前邏輯相同，僅修改回傳函式) ---
  Widget _categoryIcon(IconData icon, String category, Color color) {
    bool isSelected = _currentCategory == category;
    return GestureDetector(
      onTap: () => _manualUpdateSound(category, _currentLevel),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? color : Colors.white10),
        ),
        child: Icon(icon, color: isSelected ? color : Colors.white38, size: 28),
      ),
    );
  }

  Widget _levelButton(int level) {
    bool isSelected = _currentLevel == level;
    return GestureDetector(
      onTap: () => _manualUpdateSound(_currentCategory, level),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10), width: 50, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.white : Colors.white10),
        ),
        child: Text("L$level", style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _volumeToggle() {
    return IconButton(
      icon: Icon(_isSoundOn ? Icons.volume_up : Icons.volume_off),
      color: _isSoundOn ? Colors.orangeAccent : Colors.white24,
      onPressed: () {
        setState(() => _isSoundOn = !_isSoundOn);
        if (!_isSoundOn) _audioPlayer.pause();
        else if (_isRunning) _audioPlayer.play(AssetSource('sounds/$_currentFileName'));
      },
    );
  }

  Widget _mainActionButton() {
    return ElevatedButton(
      onPressed: _toggleTimer,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(_isRunning ? "PAUSE" : "FOCUS"),
    );
  }
}