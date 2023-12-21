import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'feb_rtc/entity.dart';

class Local {
  static String get version => '1.0';


  static set lastUpdate(String value) => setString('lastUpdate', value );

  static String get token => getString('token') ?? '';
  static set token(String value) => setString('token', value );

  static bool get securityNotification => getBool('securityNotification') ?? false;
  static set securityNotification(bool value) => setBool('securityNotification', value);

  static const String defaultLocale = 'en';
  static String get locale => 'en' ?? getString('locale') ?? defaultLocale;
  static set locale(String value) => setString('locale', value );

  static String get station => getString('station') ?? '';
  static set station(String value) => setString('station', value );
  static String get cookies => getString('cookies') ?? '';
  static set cookies(String value) => setString('cookies', value );
  static Map<String, dynamic>? get iceServers => getJson('iceServers');
  static set iceServers(Map<String, dynamic>? value) => setJson('iceServers', value ?? {});
  static Map<String, dynamic> get args => getJson('args') ?? {};
  static set args(Map<String, dynamic> value) => setJson('args', value);
  static User? get user => getJson('user') != null ? User.fromJson(getJson('user')!) : null;
  static set user(User? value) {
    setJson('user', value?.toJson() ?? {});
  }

  static bool get isLogged => user?.id != null;
  static bool get isProfileComplete => user?.dname != null;

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Map<String, dynamic>? getJson(String key) {
    final json = _prefs?.getString(key);
    return json != null ? jsonDecode(json) : null;
  }

  static Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _prefs?.setString(key, jsonEncode(value)) ?? Future.value(false);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setString(String key, String value) {
    return _prefs?.setString(key, value) ?? Future.value(false);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<bool> setBool(String key, bool value) {
    return _prefs?.setBool(key, value) ?? Future.value(false);
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs?.setInt(key, value) ?? Future.value(false);
  }

  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  static Future<bool> setDouble(String key, double value) {
    return _prefs?.setDouble(key, value) ?? Future.value(false);
  }

  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs?.setStringList(key, value) ?? Future.value(false);
  }

  static Future<bool> remove(String key) {
    return _prefs?.remove(key) ?? Future.value(false);
  }

  static Future<bool> clear() {
    return _prefs?.clear() ?? Future.value(false);
  }
}