import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class MetaAppEventsService {
  MetaAppEventsService._();

  static final MetaAppEventsService instance = MetaAppEventsService._();
  final FacebookAppEvents _events = FacebookAppEvents();

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await _events.setAdvertiserIdCollectionEnabled(true);
      await _events.activateApp();
      _ready = true;
    } catch (error) {
      debugPrint('Meta App Events disabled: $error');
    }
  }

  Future<void> logRegistrationCompleted({String method = 'phone'}) {
    return _log('CompleteRegistration', {'registration_method': method});
  }

  Future<void> logLogin({String method = 'phone'}) {
    return _log('fb_mobile_login', {'login_method': method});
  }

  Future<void> logViewContent({
    required String contentType,
    required String contentId,
    String? contentName,
  }) {
    return _log('ViewContent', {
      'content_type': contentType,
      'content_id': contentId,
      if (contentName != null && contentName.isNotEmpty)
        'content_name': contentName,
    });
  }

  Future<void> logAddToCart({
    required String contentId,
    String? contentName,
    num? value,
    String currency = 'BDT',
  }) {
    final parameters = <String, Object>{
      'content_id': contentId,
      'currency': currency,
    };
    if (contentName != null && contentName.isNotEmpty) {
      parameters['content_name'] = contentName;
    }
    if (value != null) {
      parameters['value'] = value;
    }
    return _log('AddToCart', parameters);
  }

  Future<void> logPurchase({
    required num value,
    String currency = 'BDT',
    String? orderId,
  }) async {
    try {
      await _events.logPurchase(
        amount: value.toDouble(),
        currency: currency,
        parameters: {
          if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        },
      );
      await _events.flush();
    } catch (error) {
      debugPrint('Meta purchase event skipped: $error');
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object> parameters = const {},
  }) {
    return _log(name, parameters);
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    try {
      await _events.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Meta event skipped: $name $error');
    }
  }
}
