import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Completer<bool>? _refreshCompleter;

  void Function()? onTokenExpired;

  ApiService({required this._storage}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final token = await _storage.read(key: _accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
          await clearTokens();
          onTokenExpired?.call();
        }
        handler.next(error);
      },
    ));
  }

  String _resolveUrl(String path) {
    if (kIsWeb) {
      return '${AppConfig.apiBaseUrl}$path';
    }
    return path;
  }

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await Dio().post(
        '${AppConfig.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data['data'];
      if (data != null) {
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
        await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
        _refreshCompleter!.complete(true);
        return true;
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> get accessToken async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> get refreshToken async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<bool> get hasToken async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(_resolveUrl(path), queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(_resolveUrl(path), data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(_resolveUrl(path), data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(_resolveUrl(path), data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(_resolveUrl(path));
  }

  Future<Response> uploadFile(String path, String filePath, {String fieldName = 'file'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(_resolveUrl(path), data: formData);
  }
}
