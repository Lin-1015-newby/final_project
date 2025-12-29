import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PomodoroTimer(),
    );
  }
}

/// ===============================
/// 設定模型
/// ===============================
class PomodoroSettings {
  int focusMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int longBreakInterval;

  PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakInterval = 4,
  });
}

/// ===============================
/// 番茄鐘階段
/// ===============================
enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  final PomodoroSettings _settings = PomodoroSettings();

  PomodoroPhase _phase = PomodoroPhase.focus;
  int _seconds = 25 * 60;
  int _completedPomodoros = 0;
  bool _isRunning = false;

  Timer? _timer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundOn = true;
  String _currentCategory = 'rain';
  int _currentLevel = 1;

  int get focusTime => _settings.focusMinutes * 60;
  int get shortBreakTime => _settings.shortBreakMinutes * 60;
  int get longBreakTime => _settings.longBreakMinutes * 60;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isRunning && _isSoundOn) _playNextSound();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// ===============================
  /// Timer
  /// ===============================
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 0) {
        _handlePhaseComplete();
        return;
      }
      setState(() => _seconds--);
    });
    _playSound();
  }

  void _pauseTimer() {
    _timer?.cancel();
    _audioPlayer.pause();
    setState(() => _isRunning = false);
  }

  void _toggleTimer() {
    setState(() => _isRunning = !_isRunning);
    _isRunning ? _startTimer() : _pauseTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _phase = PomodoroPhase.focus;
      _seconds = focusTime;
      _completedPomodoros = 0;
      _isRunning = false;
      _currentLevel = 1;
    });
  }

  /// ===============================
  /// 階段切換
  /// ===============================
  void _handlePhaseComplete() {
    _timer?.cancel();
    _audioPlayer.stop();

    setState(() {
      if (_phase == PomodoroPhase.focus) {
        _completedPomodoros++;
        if (_completedPomodoros % _settings.longBreakInterval == 0) {
          _phase = PomodoroPhase.longBreak;
          _seconds = longBreakTime;
        } else {
          _phase = PomodoroPhase.shortBreak;
          _seconds = shortBreakTime;
        }
      } else {
        _phase = PomodoroPhase.focus;
        _seconds = focusTime;
      }
    });

    _startTimer();
  }

  /// ===============================
  /// 音效
  /// ===============================
  String get _currentFileName => '${_currentCategory}_$_currentLevel.mp3';

  Future<void> _playSound() async {
    if (_isRunning && _isSoundOn) {
      await _audioPlayer.play(
        AssetSource('sounds/$_currentFileName'),
      );
    }
  }

  void _playNextSound() {
    setState(() {
      _currentLevel = (_currentLevel % 3) + 1;
    });
    _playSound();
  }

  void _updateSound({String? category, int? level}) {
    setState(() {
      if (category != null) _currentCategory = category;
      if (level != null) _currentLevel = level;
    });
    _playSound();
  }

  /// ===============================
  /// UI Helper
  /// ===============================
  String get _phaseText {
    switch (_phase) {
      case PomodoroPhase.focus:
        return "FOCUS";
      case PomodoroPhase.shortBreak:
        return "SHORT BREAK";
      case PomodoroPhase.longBreak:
        return "LONG BREAK";
    }
  }

  Color get _phaseColor {
    if (_phase == PomodoroPhase.focus) return Colors.redAccent;
    if (_phase == PomodoroPhase.shortBreak) return Colors.greenAccent;
    return Colors.blueAccent;
  }

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final maxTime = _phase == PomodoroPhase.focus
        ? focusTime
        : _phase == PomodoroPhase.shortBreak
        ? shortBreakTime
        : longBreakTime;

    Color activeColor = _currentCategory == 'rain' ? Colors.blueAccent : Colors.greenAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pomodoro"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(settings: _settings),
                ),
              );
              if (_phase == PomodoroPhase.focus) {
                setState(() => _seconds = focusTime);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(_phaseText, style: TextStyle(color: _phaseColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text("🍅 $_completedPomodoros", style: const TextStyle(fontSize: 16)),
          const Spacer(),

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: _seconds / maxTime,
                  strokeWidth: 5,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(fontSize: 64),
                  ),
                  Text(
                    "Playing: $_currentFileName",
                    style: TextStyle(fontSize: 11, color: activeColor.withAlpha(128)),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // 音樂控制區域
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // 類別切換（rain / forest）和音量控制
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _categoryButton(Icons.umbrella, 'rain', Colors.blueAccent),
                    _categoryButton(Icons.forest, 'forest', Colors.greenAccent),
                    _volumeToggle(),
                  ],
                ),
                const SizedBox(height: 15),
                // 控制按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(_isRunning ? "PAUSE" : "START"),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _resetTimer,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 類別選擇按鈕（rain / forest）
  Widget _categoryButton(IconData icon, String category, Color color) {
    bool isSelected = _currentCategory == category;
    return GestureDetector(
      onTap: () => _updateSound(category: category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(51) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? color : Colors.white10, width: 2),
        ),
        child: Icon(icon, color: isSelected ? color : Colors.white38, size: 26),
      ),
    );
  }



  // 音量開關
  Widget _volumeToggle() {
    return IconButton(
      icon: Icon(_isSoundOn ? Icons.volume_up : Icons.volume_off),
      color: _isSoundOn ? Colors.orangeAccent : Colors.white24,
      iconSize: 28,
      onPressed: () {
        setState(() => _isSoundOn = !_isSoundOn);
        if (!_isSoundOn) {
          _audioPlayer.pause();
        } else if (_isRunning) {
          _playSound();
        }
      },
    );
  }
}

/// ===============================
/// 設定頁
/// ===============================
class SettingsPage extends StatefulWidget {
  final PomodoroSettings settings;
  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int focus;
  late int shortBreak;
  late int longBreak;
  late int interval;

  @override
  void initState() {
    super.initState();
    focus = widget.settings.focusMinutes;
    shortBreak = widget.settings.shortBreakMinutes;
    longBreak = widget.settings.longBreakMinutes;
    interval = widget.settings.longBreakInterval;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _slider("專注時間（分鐘）", focus, 10, 60,
                  (v) => setState(() => focus = v)),
          _slider("短休息（分鐘）", shortBreak, 3, 15,
                  (v) => setState(() => shortBreak = v)),
          _slider("長休息（分鐘）", longBreak, 10, 30,
                  (v) => setState(() => longBreak = v)),
          _slider("幾次專注後長休", interval, 2, 6,
                  (v) => setState(() => interval = v)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              widget.settings
                ..focusMinutes = focus
                ..shortBreakMinutes = shortBreak
                ..longBreakMinutes = longBreak
                ..longBreakInterval = interval;
              Navigator.pop(context);
            },
            child: const Text("儲存"),
          )
        ],
      ),
    );
  }

  Widget _slider(String title, int value, int min, int max,
      ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title：$value"),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: value.toString(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}