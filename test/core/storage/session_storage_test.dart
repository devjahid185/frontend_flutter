import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/storage/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists the complete session until it is explicitly cleared',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SessionStorage();
      const token = 'persistent-test-token';
      final user = <String, dynamic>{
        'id': 42,
        'name': 'Session Test User',
        'phone': '01700000000',
      };

      await storage.saveSession(token, user: user);

      expect(await SessionStorage().getToken(), token);
      expect(await SessionStorage().getUser(), user);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), token);
      expect(prefs.getString('auth_token_backup'), token);

      await storage.clearSession();

      expect(await storage.getToken(), isNull);
      expect(await storage.getUser(), isNull);
      expect(prefs.containsKey('auth_token'), isFalse);
      expect(prefs.containsKey('auth_token_backup'), isFalse);
      expect(prefs.containsKey('auth_user'), isFalse);
    },
  );
}
