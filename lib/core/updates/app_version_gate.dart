import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_client.dart';
import '../storage/session_storage.dart';
import 'in_app_update_gate.dart';

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  final _api = ApiClient(getToken: SessionStorage().getToken);
  Map<String, dynamic>? _policy;
  bool _loading = true;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPolicy());
  }

  Future<void> _loadPolicy() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'android';
      final res = await _api.get(
        '/app-version-check',
        auth: false,
        query: {
          'platform': platform,
          'version': info.version,
          'build': info.buildNumber,
        },
      );
      if (!mounted) return;
      setState(() => _policy = Map<String, dynamic>.from(res as Map));
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRecommended());
    } catch (_) {
      // Version check should never block app startup during network issues.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _maintenance => _policy?['maintenance'] == true;
  bool get _forceUpdate => _policy?['force_update'] == true;
  bool get _recommended =>
      _policy?['update_available'] == true &&
      _policy?['update_type'] == 'recommended';

  Future<void> _showRecommended() async {
    if (!mounted ||
        _dialogShown ||
        _maintenance ||
        _forceUpdate ||
        !_recommended) {
      return;
    }
    _dialogShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_text('title', 'নতুন আপডেট এসেছে')),
        content: Text(
          _text('message', 'আরও ভালো অভিজ্ঞতার জন্য অ্যাপ আপডেট করুন।'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('পরে করব'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(_openUpdate());
            },
            child: const Text('আপডেট করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpdate() async {
    if (Platform.isAndroid) {
      final started = await InAppUpdateGate.startUpdateFlow();
      if (started) return;
    }

    final url = (_policy?['store_url'] ?? _policy?['direct_apk_url'])
        ?.toString();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _text(String key, String fallback) {
    final value = _policy?[key]?.toString();
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return widget.child;
    if (_maintenance) {
      return _BlockingNotice(
        title: _text('maintenance_title', 'সার্ভিস আপডেট চলছে'),
        message: _text(
          'maintenance_message',
          'আমরা সিস্টেম উন্নত করছি। কিছুক্ষণ পর আবার চেষ্টা করুন।',
        ),
        actionLabel: 'আবার চেষ্টা করুন',
        onAction: _loadPolicy,
      );
    }
    if (_forceUpdate) {
      return _BlockingNotice(
        title: _text('title', 'আপডেট প্রয়োজন'),
        message: _text(
          'message',
          'অ্যাপ ব্যবহার চালিয়ে যেতে নতুন ভার্সন ইনস্টল করুন।',
        ),
        actionLabel: 'আপডেট করুন',
        onAction: _openUpdate,
      );
    }
    return widget.child;
  }
}

class _BlockingNotice extends StatelessWidget {
  const _BlockingNotice({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      color: scheme.onPrimaryContainer,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
