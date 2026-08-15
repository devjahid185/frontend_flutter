import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/notification_service.dart';
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
      await _syncNotificationPreference();
    }
    isInitialized = true;
    notifyListeners();
  }

  Future<bool> login({
    required String identity,
    required String password,
  }) async {
    return _authFlow(() async {
      final isEmail = identity.contains('@');
      final payload = <String, dynamic>{
        'password': password,
        ..._devicePayload(),
        if (isEmail) 'email': identity else 'phone': identity,
      };
      final res = await _api.post('/login', body: payload, auth: false);
      return res as Map<String, dynamic>;
    }, context: 'login');
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
          ..._devicePayload(),
          'district': district,
          'upazila': upazila,
        },
        auth: false,
      );
      return res as Map<String, dynamic>;
    }, context: 'register');
  }

  Future<bool> requestOtp({
    required String phone,
    required String purpose,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/request-otp',
        body: {'phone': phone, 'purpose': purpose},
        auth: false,
      );
    }, context: 'request-otp');
  }

  Future<bool> verifyOtp({
    required String phone,
    required String purpose,
    required String otp,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/verify-otp',
        body: {'phone': phone, 'purpose': purpose, 'otp': otp},
        auth: false,
      );
    }, context: 'verify-otp');
  }

  Future<bool> registerWithOtp({
    required String name,
    required String phone,
    String? email,
    required String password,
    String? district,
    String? upazila,
    required String otp,
  }) async {
    return _authFlow(() async {
      final res = await _api.post(
        '/register-otp',
        body: {
          'name': name,
          'phone': phone,
          'email': (email ?? '').trim().isEmpty ? null : email,
          'password': password,
          'district': district,
          'upazila': upazila,
          'otp': otp,
          ..._devicePayload(),
        },
        auth: false,
      );
      return res as Map<String, dynamic>;
    }, context: 'register-otp');
  }

  Future<bool> resetPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/reset-password',
        body: {'phone': phone, 'otp': otp, 'password': password},
        auth: false,
      );
    }, context: 'reset-password');
  }

  Future<bool> requestEmailPasswordReset({required String email}) async {
    return _simpleFlow(() async {
      await _api.post(
        '/forgot-password-email',
        body: {'email': email},
        auth: false,
      );
    }, context: 'forgot-password-email');
  }

  Future<bool> verifyEmailPasswordReset({
    required String email,
    required String otp,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/verify-password-email',
        body: {'email': email, 'otp': otp},
        auth: false,
      );
    }, context: 'verify-password-email');
  }

  Future<bool> resetPasswordWithEmail({
    required String email,
    required String otp,
    required String password,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/reset-password-email',
        body: {'email': email, 'otp': otp, 'password': password},
        auth: false,
      );
    }, context: 'reset-password-email');
  }

  Future<bool> loginWithGoogle() async {
    return _authFlow(() async {
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConfig.googleWebClientId,
      );
      final account = await google.signIn();
      if (account == null) {
        throw ApiException('গুগল লগইন বাতিল হয়েছে।', 400);
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('গুগল আইডি টোকেন পাওয়া যায়নি।', 400);
      }

      final res = await _api.post(
        '/login-google',
        body: {'id_token': idToken, ..._devicePayload()},
        auth: false,
      );
      return res as Map<String, dynamic>;
    }, context: 'login-google');
  }

  Map<String, dynamic> _devicePayload() {
    if (kIsWeb) {
      return {'device_name': 'Web Browser', 'device_platform': 'web'};
    }

    final os = Platform.operatingSystem;
    final name = switch (os) {
      'android' => 'Android Phone',
      'ios' => 'iPhone',
      'macos' => 'Mac',
      'windows' => 'Windows PC',
      'linux' => 'Linux PC',
      _ => 'Mobile App',
    };

    return {'device_name': name, 'device_platform': os};
  }

  Future<bool> _authFlow(
    Future<Map<String, dynamic>> Function() action, {
    required String context,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await action();
      token = data['token'] as String?;
      user = data['user'] as Map<String, dynamic>?;
      if (token != null && token!.isNotEmpty) {
        await _storage.saveToken(token!);
        await _syncNotificationPreference();
      }
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      debugPrint('[Auth:$context] ApiException: ${e.message}');
      return false;
    } catch (e, stack) {
      debugPrint('[Auth:$context] Unexpected: $e');
      debugPrint('[Auth:$context] Stack: $stack');
      errorMessage = 'অপ্রত্যাশিত সমস্যা হয়েছে, আবার চেষ্টা করুন।';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _simpleFlow(
    Future<void> Function() action, {
    required String context,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      debugPrint('[Auth:$context] ApiException: ${e.message}');
      return false;
    } catch (e, stack) {
      debugPrint('[Auth:$context] Unexpected: $e');
      debugPrint('[Auth:$context] Stack: $stack');
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
    } catch (e) {
      debugPrint('[Auth:profile] Error: $e');
      await logout(localOnly: true);
    } finally {
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _syncNotificationPreference() async {
    try {
      final res = await _api.get('/notifications/preferences');
      if (res is Map<String, dynamic>) {
        final enabled = res['push_enabled'];
        if (enabled is bool) {
          await NotificationService.setPushEnabled(enabled);
        }
      }
    } catch (_) {
      await NotificationService.registerDeviceToken();
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
      debugPrint('[Auth:photo] ApiException: ${e.message}');
      return false;
    } catch (e, stack) {
      debugPrint('[Auth:photo] Unexpected: $e');
      debugPrint('[Auth:photo] Stack: $stack');
      errorMessage = 'ছবি আপলোড করা যায়নি।';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? district,
    String? upazila,
    String? unionName,
    String? address,
  }) async {
    if (!isLoggedIn) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email.trim().isNotEmpty ? email : null;
      if (district != null) body['district'] = district;
      if (upazila != null) body['upazila'] = upazila;
      if (unionName != null) body['union_name'] = unionName;
      if (address != null) body['address'] = address;

      final res = await _api.post('/update-profile', body: body);

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
      debugPrint('[Auth:update] ApiException: ${e.message}');
      return false;
    } catch (e, stack) {
      debugPrint('[Auth:update] Unexpected: $e');
      debugPrint('[Auth:update] Stack: $stack');
      errorMessage = 'প্রোফাইল আপডেট করা যায়নি।';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordChangeOtp() async {
    return _simpleFlow(() async {
      await _api.post('/change-password/request-otp');
    }, context: 'change-password-otp');
  }

  Future<bool> verifyPasswordChangeOtp({
    required String phone,
    required String otp,
  }) async {
    return verifyOtp(phone: phone, purpose: 'password_change', otp: otp);
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String otp,
    required String password,
  }) async {
    return _simpleFlow(() async {
      await _api.post(
        '/change-password',
        body: {
          'current_password': currentPassword,
          'otp': otp,
          'password': password,
        },
      );
    }, context: 'change-password');
  }

  Future<List<Map<String, dynamic>>> loginDevices() async {
    final res = await _api.get('/login-devices');
    if (res is Map<String, dynamic> && res['devices'] is List) {
      return (res['devices'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Future<bool> revokeLoginDevice(int id) async {
    return _simpleFlow(() async {
      final res = await _api.delete('/login-devices/$id');
      if (res is Map<String, dynamic> && res['revoked_current'] == true) {
        token = null;
        user = null;
        await _storage.clearToken();
      }
    }, context: 'revoke-login-device');
  }

  Future<bool> revokeOtherLoginDevices() async {
    return _simpleFlow(() async {
      await _api.delete('/login-devices/others');
    }, context: 'revoke-other-login-devices');
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly && isLoggedIn) {
      try {
        await _api.post('/logout');
      } catch (_) {}
    }

    if (isLoggedIn) {
      await NotificationService.unregisterDeviceToken();
    }

    token = null;
    user = null;
    errorMessage = null;
    await _storage.clearToken();
    notifyListeners();
  }
}
