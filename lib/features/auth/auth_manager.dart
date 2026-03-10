import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';

class AuthManager extends ChangeNotifier {
  final SessionStorage _storage = SessionStorage();
  late final ApiClient _api = ApiClient(getToken: _storage.getToken);

  bool isInitialized = false;
  bool isLoading = false;
  String? errorMessage;
  String? token;
  Map<String, dynamic>? user;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> initialize() async {
    token = await _storage.getToken();
    if (isLoggedIn) {
      await fetchProfile(silent: true);
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<bool> login({required String identity, required String password}) async {
    return _authFlow(() async {
      final isEmail = identity.contains('@');
      final payload = <String, dynamic>{
        'password': password,
        if (isEmail) 'email': identity else 'phone': identity,
      };
      final res = await _api.post('/login', body: payload, auth: false);
      return res as Map<String, dynamic>;
    });
  }

  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    String? district,
    String? upazila,
  }) async {
    return _authFlow(() async {
      final res = await _api.post(
        '/register',
        body: {
          'name': name,
          'phone': phone,
          'email': (email ?? '').trim().isEmpty ? null : email,
          'password': password,
          'district': district,
          'upazila': upazila,
        },
        auth: false,
      );
      return res as Map<String, dynamic>;
    });
  }

  Future<bool> _authFlow(Future<Map<String, dynamic>> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await action();
      token = data['token'] as String?;
      user = data['user'] as Map<String, dynamic>?;
      if (token != null && token!.isNotEmpty) {
        await _storage.saveToken(token!);
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'অপ্রত্যাশিত সমস্যা হয়েছে, আবার চেষ্টা করুন।';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile({bool silent = false}) async {
    if (!isLoggedIn) {
      return;
    }

    if (!silent) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final res = await _api.get('/profile');
      if (res is Map<String, dynamic>) {
        user = res;
      }
    } catch (_) {
      await logout(localOnly: true);
    } finally {
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> uploadProfilePhoto(String imagePath) async {
    if (!isLoggedIn) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.postMultipart(
        '/profile/photo',
        files: {'image': imagePath},
      );

      if (res is Map<String, dynamic>) {
        final updated = res['user'];
        if (updated is Map<String, dynamic>) {
          user = updated;
        } else {
          await fetchProfile(silent: true);
        }
      } else {
        await fetchProfile(silent: true);
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'ছবি আপলোড করা যায়নি।';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly && isLoggedIn) {
      try {
        await _api.post('/logout');
      } catch (_) {}
    }

    token = null;
    user = null;
    errorMessage = null;
    await _storage.clearToken();
    notifyListeners();
  }
}
