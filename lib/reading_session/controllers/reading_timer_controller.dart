import 'dart:async';
import 'package:flutter/material.dart';

class ReadingTimerController extends ChangeNotifier {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  int _selectedMode = 0; // 0 = open, 1 = target, 2 = pomodoro
  int _targetSeconds = 0;
  int _remainingSeconds = 0;

  // NEW: Session tracking fields
  double _startProgress = 0.0;
  double _currentProgress = 0.0;
  String? _currentCfi;

  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  int get selectedMode => _selectedMode;
  int get targetSeconds => _targetSeconds;
  int get remainingSeconds => _remainingSeconds;

  // NEW: Getters for session data
  double get currentProgress => _currentProgress;
  String? get currentCfi => _currentCfi;

  String get displayTime {
    if (_selectedMode == 0) {
      return _formatTime(_elapsedSeconds);
    } else {
      return _formatTime(_remainingSeconds);
    }
  }

  // NEW: Bottom sheet display format (short format)
  String get bottomSheetDisplay {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${_elapsedSeconds}s';
    }
  }

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_selectedMode == 1 && _remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds == 0) {
          pauseTimer();
        }
      } else if (_selectedMode == 2 && _remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds == 0) {
          pauseTimer();
        }
      } else {
        _elapsedSeconds++;
      }
      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isRunning) {
      startTimer();
    }
  }

  void setMode(int mode, {int? targetMinutes}) {
    _selectedMode = mode;
    if (mode == 1 || mode == 2) {
      if (targetMinutes != null) {
        _targetSeconds = targetMinutes * 60;
        _remainingSeconds = _targetSeconds;
      }
    } else {
      _targetSeconds = 0;
      _remainingSeconds = 0;
    }
    notifyListeners();
  }

  void endSession() {
    _timer?.cancel();
    _isRunning = false;
    _elapsedSeconds = 0;
    _selectedMode = 0;
    _targetSeconds = 0;
    _remainingSeconds = 0;
    notifyListeners();
  }

  // NEW: Set initial progress when session starts
  void setInitialProgress(double progress) {
    _startProgress = progress;
    _currentProgress = progress;
  }

  // NEW: Update current position (called from onRelocated)
  void updatePosition(String? cfi, double progress) {
    _currentCfi = cfi;
    _currentProgress = progress;
    notifyListeners();
  }

  // NEW: Calculate progress gained during this session
  double calculateProgressGained() {
    return _currentProgress - _startProgress;
  }

  // NEW: Get all session data for saving
  ReadingSessionData getSessionData() {
    return ReadingSessionData(
      duration: _elapsedSeconds,
      cfi: _currentCfi,
      progress: _currentProgress,
      progressGained: calculateProgressGained(),
    );
  }

  // NEW: Reset for new session
  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _elapsedSeconds = 0;
    _startProgress = 0.0;
    _currentProgress = 0.0;
    _currentCfi = null;
    notifyListeners();
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// NEW: Data class to hold session information
class ReadingSessionData {
  final int duration;
  final String? cfi;
  final double progress;
  final double progressGained;

  ReadingSessionData({
    required this.duration,
    required this.cfi,
    required this.progress,
    required this.progressGained,
  });

  // Format duration as "Xh Ym" for display
  String get formattedDurationShort {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }

  // Format duration as "Xh Ym Zs"
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
