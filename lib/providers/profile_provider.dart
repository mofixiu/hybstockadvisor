import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  static const Duration ttl = Duration(minutes: 15);

  String _fullName = 'Loading...';
  String? _avatarPath;
  String _investorTier = 'Beginner Investor';
  IconData _tierIcon = Icons.person_outline;
  Color _tierColor = const Color(0xFF888888);
  Color _tierBgColor = const Color(0xFFE8E8E8);

  bool _isLoading = false;
  bool _hasError = false;
  DateTime? _lastFetchedAt;
  Future<void>? _inFlight;

  String get fullName => _fullName;
  String? get avatarPath => _avatarPath;
  String get investorTier => _investorTier;
  IconData get tierIcon => _tierIcon;
  Color get tierColor => _tierColor;
  Color get tierBgColor => _tierBgColor;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

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
      final name = '$firstName $lastName'.trim();
      final avatarPath = box.get('avatar_path') as String?;

      String tier = 'Beginner Investor';
      IconData icon = Icons.person_outline;
      Color color = const Color(0xFF888888);
      Color bgColor = const Color(0xFFE8E8E8);

      final data = await ApiService.getUserAssets();
      if (data != null) {
        final portfolioCount = (data['portfolio'] as List?)?.length ?? 0;
        if (portfolioCount >= 5) {
          tier = 'Premium Investor';
          icon = Icons.verified;
          color = const Color(0xFF0A3D62);
          bgColor = const Color(0xFFEAF1FF);
        } else if (portfolioCount >= 3) {
          tier = 'Committed Investor';
          icon = Icons.trending_up;
          color = const Color(0xFF2DBD6E);
          bgColor = const Color(0xFFD6F5E3);
        } else if (portfolioCount >= 1) {
          tier = 'Active Investor';
          icon = Icons.show_chart;
          color = const Color(0xFF2979FF);
          bgColor = const Color(0xFFDCEAFF);
        }
      }

      if (name.isNotEmpty) {
        _fullName = name;
      }
      _avatarPath = avatarPath;
      _investorTier = tier;
      _tierIcon = icon;
      _tierColor = color;
      _tierBgColor = bgColor;
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
}
