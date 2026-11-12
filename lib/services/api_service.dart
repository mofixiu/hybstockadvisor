import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';

// 1. Point to your Python FastAPI Server (Port 8000)
String get host {
  if (kIsWeb) {
    return "http://127.0.0.1:8000";
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:8000"; // Android Emulator mapping
  } else if (Platform.isIOS) {
    return "http://127.0.0.1:8000"; // iOS Simulator mapping
  } else {
    return "http://127.0.0.1:8000";
  }
}

const String _defaultApiHost = 'https://hybstockadvisor-us.onrender.com';
const String _configuredApiHost = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultApiHost,
);
String get baseUrl =>
    '${(_configuredApiHost.isNotEmpty ? _configuredApiHost : host).replaceFirst(RegExp(r'/$'), '')}/api';

class ApiService {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static final Dio _dio = _createDio();

  // static Dio _createDio() {
  //   final dio = Dio(
  //     BaseOptions(
  //       baseUrl: baseUrl,
  //       connectTimeout: const Duration(seconds: 10),
  //       receiveTimeout: const Duration(seconds: 10),
  //       headers: {'Accept': 'application/json'},
  //     ),
  //   );

  //   dio.interceptors.add(
  //     InterceptorsWrapper(
  //       onError: (DioException e, ErrorInterceptorHandler handler) async {
  //         if (e.response?.statusCode == 401) {
  //           final path = e.requestOptions.path;
  //           final isAuthEndpoint =
  //               path.contains('/auth/login') || path.contains('/auth/register');

  //           if (!isAuthEndpoint) {
  //             final authBox = await Hive.openBox('auth');
  //             final userBox = await Hive.openBox('user');
  //             final chatBox = await Hive.openBox('chat_history');
  //             await authBox.clear();
  //             await userBox.clear();
  //             await chatBox.clear();

  //             navigatorKey.currentState?.pushAndRemoveUntil(
  //               MaterialPageRoute(builder: (_) => const Login()),
  //               (route) => false,
  //             );
  //           }
  //         }
  //         handler.next(e);
  //       },
  //     ),
  //   );

  //   return dio;
  // }
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // Attach the JWT to every request.
        onRequest: (options, handler) async {
          // Read JWT from encrypted secure storage
          final token = await _secureStorage.read(key: 'auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },

        // On 401 outside the auth endpoints, clear the session and go to login.
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            final isAuthEndpoint =
                path.contains('/auth/login') || path.contains('/auth/register');

            if (!isAuthEndpoint) {
              // Clear secure storage JWT
              await _secureStorage.delete(key: 'auth_token');
              // Clear Hive boxes
              final authBox = await Hive.openBox('auth');
              final userBox = await Hive.openBox('user');
              final chatBox = await Hive.openBox('chat_history');
              final notificationsBox = await Hive.openBox('notifications');
              await authBox.clear();
              await userBox.clear();
              await chatBox.clear();
              await notificationsBox.clear();

              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
              );
            }
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  static String currentTicker = "GTCO";

  /// The `detail` message from a JSON error response, if there is one.
  static String? _detail(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return null;
  }

  /// Get user_id from Hive or redirect to login if missing.
  static Future<int?> _getUserId() async {
    final box = await Hive.openBox('auth');
    final userId = box.get('user_id');
    if (userId == null) {
      // user_id missing — session is invalid, force logout
      await clearToken();
      await box.clear();
      final userBox = await Hive.openBox('user');
      final chatBox = await Hive.openBox('chat_history');
      await userBox.clear();
      await chatBox.clear();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
      return null;
    }
    return userId as int;
  }

  /// Save JWT token to encrypted secure storage.
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  /// Delete JWT token from secure storage (for logout).
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  /// Read JWT token from secure storage (for splash screen check).
  static Future<String?> readToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  /// Check if a JWT token is expired by decoding its payload.
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64-decode the payload (part[1]), adding padding if needed
      String payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> data = jsonDecode(decoded);

      final exp = data['exp'];
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true; // If we can't decode it, treat it as expired
    }
  }

  /// Clear all user data (for logout). Replaces RequestService.clearUserData().
  static Future<void> clearUserData() async {
    try {
      await clearToken();
      final authBox = await Hive.openBox('auth');
      await authBox.clear();
      final userBox = await Hive.openBox('user');
      await userBox.clear();
      final chatBox = await Hive.openBox('chat_history');
      await chatBox.clear();
      final notificationsBox = await Hive.openBox('notifications');
      await notificationsBox.clear();
      log('User data cleared');
    } catch (_) {
      log('Local session data could not be cleared');
    }
  }

  // 2. The specific function to fetch our AI Data
  // ── Market data ───────────────────────────────────────

  static final Map<String, String> _failures = {};

  /// Why the last request for [key] failed, as a plain sentence for the user,
  /// or null if it succeeded. Keys: 'summary', 'forecast:TICKER',
  /// 'insights:TICKER', 'assets'.
  static String? failureFor(String key) => _failures[key];

  /// Plain wording for a failed request. A server error is not the user's
  /// connection, so it never tells them to check it.
  static String describeFailure(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The server took too long to answer. It may be starting up; try again in a minute.';
        case DioExceptionType.connectionError:
          return "Couldn't reach the server. Check your connection and try again.";
        default:
          break;
      }
      final code = error.response?.statusCode;
      if (code != null && code >= 500) {
        return 'The HybStockAdvisor server has a problem (error $code), so no data can be shown. '
            "It isn't your connection. Try again later.";
      }
      if (code != null) {
        return 'The server turned the request down (error $code). Try again later.';
      }
    }
    return 'Something went wrong loading the data. Try again.';
  }

  static Future<Map<String, dynamic>?> _getJson(String key, String path) async {
    try {
      final response = await _dio.get(path);
      if (response.statusCode == 200 && response.data is Map) {
        _failures.remove(key);
        return Map<String, dynamic>.from(response.data as Map);
      }
      _failures[key] = 'The server sent an answer the app could not read. Try again later.';
      return null;
    } catch (e) {
      log('Request failed: $path (${e is DioException ? e.type : e.runtimeType})');
      _failures[key] = describeFailure(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStockForecast(String ticker) =>
      _getJson('forecast:$ticker', '/forecast/$ticker');

  static Future<Map<String, dynamic>?> getMarketSummary() =>
      _getJson('summary', '/summary');

  static Future<Map<String, dynamic>?> getInsights(String ticker) =>
      _getJson('insights:$ticker', '/insights/$ticker');

  // --- AUTHENTICATION METHODS ---

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map<String, dynamic>) {
          return {
            'status': 'error',
            'detail': e.response!.data['detail'] ?? 'Login failed',
          };
        } else {
          return {
            'status': 'error',
            'detail': (e.response!.statusCode ?? 0) >= 500
                ? "The server isn't working right now (error ${e.response!.statusCode}), so you can't sign in. "
                      "It isn't your password or your connection. Try again later."
                : "The server couldn't sign you in (error ${e.response!.statusCode}). Try again later.",
          };
        }
      }
      return {'status': 'error', 'detail': describeFailure(e)};
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      log('Submitting tester registration');
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.data is Map<String, dynamic>) {
          return {
            'status': 'error',
            'detail': e.response!.data['detail'] ?? 'Registration failed',
          };
        } else {
          return {
            'status': 'error',
            'detail': "The server couldn't create the account. Try again later.",
          };
        }
      }
      return {'status': 'error', 'detail': "Couldn't reach the server. Check your connection and try again."};
    }
  }

  // --- FIXED PORTFOLIO & WATCHLIST METHODS ---

  static Future<Map<String, dynamic>> addToPortfolio({
    required String ticker,
    required double quantity,
    required double avgBuyPrice,
  }) async {
    try {
      // 1. Grab the User ID
      final userId = await _getUserId();
      if (userId == null) {
        return {'status': 'error', 'detail': 'Session expired'};
      }

      final response = await _dio.post(
        '/portfolio/add', // <-- No extra /api here
        data: {
          'user_id': userId, // <-- THIS IS WHAT WAS MISSING! (Fixed 422 Error)
          'ticker': ticker,
          'quantity': quantity,
          'average_buy_price': avgBuyPrice,
        },
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'detail': _detail(e) ?? "Couldn't reach the server. Check your connection and try again.",
      };
    } catch (_) {
      return {'status': 'error', 'detail': 'Something went wrong. Try again.'};
    }
  }

  static Future<Map<String, dynamic>?> getUserAssets() async {
    final userId = await _getUserId();
    if (userId == null) return null;
    final res = await _getJson('assets', '/user/$userId/assets');
    if (res == null) return null;
    if (res['status'] == 'success' && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    _failures['assets'] = 'The server sent an answer the app could not read. Try again later.';
    return null;
  }

  static Future<Map<String, dynamic>> addToWatchlist({
    required String ticker,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'status': 'error', 'detail': 'Session expired'};
      }

      // 3. Fixed the double /api/api typo
      final response = await _dio.post(
        '/watchlist/add',
        data: {'user_id': userId, 'ticker': ticker},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'detail': _detail(e) ?? "Couldn't reach the server. Check your connection and try again.",
      };
    } catch (e) {
      return {'status': 'error', 'detail': 'Something went wrong. Try again.'};
    }
  }

  static Future<Map<String, dynamic>> removeFromPortfolio({
    required String ticker,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'status': 'error', 'detail': 'Session expired'};
      }

      final response = await _dio.delete(
        '/portfolio/remove',
        data: {'user_id': userId, 'ticker': ticker},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'detail': _detail(e) ?? "Couldn't reach the server. Check your connection and try again.",
      };
    }
  }

  static Future<Map<String, dynamic>> removeFromWatchlist({
    required String ticker,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'status': 'error', 'detail': 'Session expired'};
      }

      final response = await _dio.delete(
        '/watchlist/remove',
        data: {'user_id': userId, 'ticker': ticker},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'status': 'error',
        'detail': _detail(e) ?? "Couldn't reach the server. Check your connection and try again.",
      };
    }
  }

  // ── Password Reset Flow ──────────────────────────────────────

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return {
          'status': 'error',
          'detail': e.response!.data['detail'] ?? 'Request failed',
        };
      }
      return {'status': 'error', 'detail': "Couldn't reach the server. Check your connection and try again."};
    }
  }

  static Future<Map<String, dynamic>> verifyResetOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-reset-otp',
        data: {'email': email.trim(), 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return {
          'status': 'error',
          'detail': e.response!.data['detail'] ?? 'Invalid OTP',
        };
      }
      return {'status': 'error', 'detail': "Couldn't reach the server. Check your connection and try again."};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'reset_token': resetToken, 'new_password': newPassword},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        return {
          'status': 'error',
          'detail': e.response!.data['detail'] ?? 'Reset failed',
        };
      }
      return {'status': 'error', 'detail': "Couldn't reach the server. Check your connection and try again."};
    }
  }

  // --- RESEARCH ASSISTANT ("Ask") ---

  /// Sends a question to the research assistant. The reply is returned as
  /// Markdown; errors come back as short plain sentences for the user.
  static Future<ChatResult> sendChatMessage(
    String message, {
    String? currentTicker,
  }) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'text': message,
          if (currentTicker != null) 'current_ticker': currentTicker,
        },
      );
      final reply = response.data is Map ? response.data['reply'] : null;
      if (response.statusCode == 200 && reply is String && reply.trim().isNotEmpty) {
        return ChatResult.reply(reply.trim());
      }
      return const ChatResult.error('No answer came back. Try asking again.');
    } on DioException catch (e) {
      log('Ask request failed: ${e.type}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ChatResult.error(
            'The answer took too long. Try again in a moment.',
          );
        case DioExceptionType.connectionError:
          return const ChatResult.error(
            "Couldn't reach the server. Check your connection and try again.",
          );
        default:
          break;
      }
      final code = e.response?.statusCode;
      if (code == 503) {
        return const ChatResult.error('Ask is not set up on the server yet.');
      }
      if (code == 502) {
        return const ChatResult.error(
          "Ask couldn't answer just now. Try again in a moment.",
        );
      }
      if (code != null && code >= 500) {
        return ChatResult.error(
          "The server has a problem (error $code), so Ask can't answer right now. Try again later.",
        );
      }
      if (code == 422) {
        return const ChatResult.error(
          'That question is too long. Keep it under 2,000 characters.',
        );
      }
      return const ChatResult.error('Something went wrong. Try again.');
    } catch (_) {
      log('Ask response could not be read');
      return const ChatResult.error('Something went wrong. Try again.');
    }
  }
}

/// Outcome of a question to the research assistant.
class ChatResult {
  final String? reply;
  final String? error;
  const ChatResult.reply(String this.reply) : error = null;
  const ChatResult.error(String this.error) : reply = null;
  bool get ok => reply != null;
}
