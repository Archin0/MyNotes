import 'dart:async';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _isAuthenticated = false;
  DateTime? _pauseTime;
  static const int _lockTimeoutSeconds = 30;

  final StreamController<bool> _authStreamController =
      StreamController<bool>.broadcast();

  bool get isAuthenticated => _isAuthenticated;
  Stream<bool> get authStream => _authStreamController.stream;

  void authenticate() {
    _isAuthenticated = true;
    _pauseTime = null;
    _authStreamController.add(true);
  }

  void onAppPause() {
    _pauseTime = DateTime.now();
    // Tidak langsung logout, hanya catat waktu pause
  }

  void onAppResume() {
    if (_pauseTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseTime!);

      if (pauseDuration.inSeconds >= _lockTimeoutSeconds) {
        // Jika pause lebih dari 30 detik, require PIN
        logout();
      }
      // Jika pause kurang dari 30 detik, tetap authenticated
    }
    _pauseTime = null;
  }

  void logout() {
    _isAuthenticated = false;
    _pauseTime = null;
    _authStreamController.add(false);
  }

  void dispose() {
    _authStreamController.close();
  }
}
