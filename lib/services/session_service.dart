import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class SessionService {
  SessionService._();
  static final instance = SessionService._();

  Future<void> login(String name, AppRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_name', name);
    await prefs.setString('session_role', role.name);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_name');
    await prefs.remove('session_role');
  }
}
