import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý giới hạn nghe audio theo ngày.
/// Lưu trạng thái vào SharedPreferences, tự reset khi sang ngày mới.
class AudioDailyLimitService {
  static const _keyDate = 'audio_limit_date';
  static const _keyCount = 'audio_limit_count';
  static const int dailyLimit = 10;
  final SharedPreferences _prefs;

   AudioDailyLimitService(this._prefs);

  /// Trả về số chương đã nghe hôm nay.
  Future<int> getTodayCount() async {
    _resetIfNewDay(_prefs);
    return _prefs.getInt(_keyCount) ?? 0;
  }

  /// Trả về số chương còn lại có thể nghe hôm nay.
  Future<int> getRemainingCount() async {
    final count = await getTodayCount();
    return (dailyLimit - count).clamp(0, dailyLimit);
  }

  /// Kiểm tra còn lượt nghe không.
  Future<bool> canListen() async {
    final count = await getTodayCount();
    return count < dailyLimit;
  }

  /// Tăng số đếm lên 1 khi bắt đầu nghe 1 chương.
  /// Trả về `false` nếu đã hết limit (không tăng).
  Future<bool> incrementCount() async {
    _resetIfNewDay(_prefs);
    final current = _prefs.getInt(_keyCount) ?? 0;
    if (current >= dailyLimit) return false;
    await _prefs.setInt(_keyCount, current + 1);
    return true;
  }

  void _resetIfNewDay(SharedPreferences prefs) {
    final today = _todayString();
    final saved = prefs.getString(_keyDate);
    if (saved != today) {
      prefs.setString(_keyDate, today);
      prefs.setInt(_keyCount, 0);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}