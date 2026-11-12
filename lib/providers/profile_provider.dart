import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/services/api_service.dart';

/// Name, avatar and plain holding counts for the Profile tab.
class ProfileProvider extends ChangeNotifier {
  static const Duration ttl = Duration(minutes: 15);

  String _fullName = '';
  String? _avatarPath;
  int? _holdingsCount;
  int? _watchlistCount;

  bool _isLoading = false;
  bool _hasError = false;
  DateTime? _lastFetchedAt;
  Future<void>? _inFlight;

  String get fullName => _fullName;
  String? get avatarPath => _avatarPath;

  /// Null when the counts could not be loaded.
  int? get holdingsCount => _holdingsCount;
  int? get watchlistCount => _watchlistCount;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  /// "8 holdings · 3 on watchlist", or null when unknown.
  String? get countsLine {
    final h = _holdingsCount;
    final w = _watchlistCount;
    if (h == null || w == null) return null;
    final holdings = h == 1 ? '1 holding' : '$h holdings';
    return '$holdings · $w on watchlist';
  }

  Future<void> load({bool force = false}) async {
    final active = _inFlight;
    if (active != null) return active;

    if (!force && _lastFetchedAt != null) {
      final age = DateTime.now().difference(_lastFetchedAt!);
      if (age < ttl) return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    final future = _loadInternal();
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _loadInternal() async {
    try {
      final box = await Hive.openBox('user');
      final firstName = box.get('first_name', defaultValue: '');
      final lastName = box.get('last_name', defaultValue: '');
      _fullName = '$firstName $lastName'.trim();
      _avatarPath = box.get('avatar_path') as String?;

      final data = await ApiService.getUserAssets();
      if (data != null) {
        _holdingsCount = (data['portfolio'] as List?)?.length ?? 0;
        _watchlistCount = (data['watchlist'] as List?)?.length ?? 0;
      } else {
        _holdingsCount = null;
        _watchlistCount = null;
      }
      _lastFetchedAt = DateTime.now();
      _hasError = false;
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _lastFetchedAt = null;
    _inFlight = null;
  }

  void resetForSessionChange() {
    _fullName = '';
    _avatarPath = null;
    _holdingsCount = null;
    _watchlistCount = null;
    _isLoading = false;
    _hasError = false;
    _lastFetchedAt = null;
    _inFlight = null;
    notifyListeners();
  }
}
