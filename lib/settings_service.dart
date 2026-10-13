// lib/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _confirmOnCashewKey = 'confirm_on_cashew';
  static const String _continuousScanKey = 'continuous_scan';
  static const String _sendFiscalInfoKey = 'send_fiscal_info_to_cashew';

  /// Get the confirmation preference.
  /// Defaults to true to ensure a safe first-time experience.
  Future<bool> getConfirmOnCashew() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_confirmOnCashewKey) ?? true;
  }

  // Save the user's preference.
  Future<void> setConfirmOnCashew(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmOnCashewKey, value);
  }

  /// Get the continuous scanning preference.
  /// Defaults to true to maximize productivity.
  Future<bool> getContinuousScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_continuousScanKey) ?? true;
  }

  Future<void> setContinuousScan(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_continuousScanKey, value);
  }

  Future<bool> getSendFiscalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sendFiscalInfoKey) ?? false;
  }

  Future<void> setSendFiscalInfo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sendFiscalInfoKey, value);
  }
}
