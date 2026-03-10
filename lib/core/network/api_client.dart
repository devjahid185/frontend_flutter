import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({required this.getToken});

  final Future<String?> Function() getToken;
  static const Duration _timeout = Duration(seconds: 18);

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: query);

    try {
      final response = await http.get(uri, headers: await _headers(auth)).timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw ApiException('সার্ভার সাড়া দিতে দেরি করছে। আবার চেষ্টা করুন।', 408);
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');

    try {
      final response = await http
          .post(uri, headers: await _headers(auth), body: jsonEncode(body ?? <String, dynamic>{}))
          .timeout(_timeout);
      return _parse(response);
    } on TimeoutException {
      throw ApiException('সার্ভার সাড়া দিতে দেরি করছে। আবার চেষ্টা করুন।', 408);
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, dynamic>? files,
    bool auth = true,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final request = http.MultipartRequest('POST', uri);

    final headers = await _headers(auth);
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields.addAll(fields ?? <String, String>{});

    if (files != null) {
      for (final entry in files.entries) {
        final value = entry.value;
        if (value is String) {
          final file = File(value);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath(entry.key, value));
          }
        } else if (value is List<String>) {
          for (final path in value) {
            final file = File(path);
            if (await file.exists()) {
              request.files.add(await http.MultipartFile.fromPath(entry.key, path));
            }
          }
        }
      }
    }

    try {
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on TimeoutException {
      throw ApiException('সার্ভার সাড়া দিতে দেরি করছে। আবার চেষ্টা করুন।', 408);
    }
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final request = http.Request('DELETE', uri)
      ..headers.addAll(await _headers(auth))
      ..body = jsonEncode(body ?? <String, dynamic>{});

    try {
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _parse(response);
    } on TimeoutException {
      throw ApiException('সার্ভার সাড়া দিতে দেরি করছে। আবার চেষ্টা করুন।', 408);
    }
  }

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _parse(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'রিকোয়েস্ট ব্যর্থ হয়েছে';
    if (body is Map<String, dynamic>) {
      if (body['message'] is String) {
        message = body['message'] as String;
      } else if (body['errors'] is Map<String, dynamic>) {
        final errors = body['errors'] as Map<String, dynamic>;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          message = first.first.toString();
        }
      }
    }

    throw ApiException(message, response.statusCode);
  }
}
