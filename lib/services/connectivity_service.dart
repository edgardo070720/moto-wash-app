import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _subscription;

  // Stream to listen to connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  // Current connectivity status
  bool get isOnline => _isOnline;

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _updateConnectivityStatus();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _updateConnectivityStatusFromResult(result);
    });
  }

  Future<void> _updateConnectivityStatus() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectivityStatusFromResult(result);
    } catch (e) {
      // If we can't determine connectivity, assume offline
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(_isOnline);
      }
    }
  }

  void _updateConnectivityStatusFromResult(ConnectivityResult result) {
    // Consider online if any connection is available
    final bool hasConnection =
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _connectivityController.add(_isOnline);
    }
  }

  // Manual check for connectivity
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
