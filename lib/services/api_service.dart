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

String get baseUrl => "https://hybstockadvisor-us.onrender.com/api";

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
        connectTimeout: const Duration(seconds: 150),
        receiveTimeout: const Duration(seconds: 150),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // 🚨 1. NEW: THE INJECTION MIDDLEWARE 🚨
        onRequest: (options, handler) async {
          // Read JWT from encrypted secure storage
          final token = await _secureStorage.read(key: 'auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },

        // 2. KEEP YOUR EXISTING ERROR MIDDLEWARE
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
    } catch (e) {
      log('Error clearing user data: $e');
    }
  }

  // 2. The specific function to fetch our AI Data
  static Future<Map<String, dynamic>?> getStockForecast(String ticker) async {
    try {
      log(
        '📡 Fetching AI Forecast for $ticker from: $baseUrl/forecast/$ticker',
      );

      final response = await _dio.get('/forecast/$ticker');

      if (response.statusCode == 200) {
        log('✅ Successfully fetched data for $ticker');
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      log('❌ Dio Error fetching $ticker: ${e.message}');
      return null;
    } catch (e) {
      log('❌ General Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMarketSummary() async {
    try {
      log('📡 Fetching Market Summary from: $baseUrl/summary');
      final response = await _dio.get('/summary');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      log('❌ Error fetching market summary: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getInsights(String ticker) async {
    try {
      log('📡 Fetching AI Insights for $ticker...');
      final response = await _dio.get('/insights/$ticker');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      log('❌ Error fetching insights: $e');
      return null;
    }
  }
  // --- AUTHENTICATION METHODS ---

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      log('📡 Attempting Login for: $identifier');
      final response = await _dio.post(
        '/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        // SAFE CHECK: Make sure the response is actually JSON before parsing it
        if (e.response!.data is Map<String, dynamic>) {
          return {
            'status': 'error',
            'detail': e.response!.data['detail'] ?? 'Login failed',
          };
        } else {
          return {
            'status': 'error',
            'detail': 'Server error: ${e.response!.statusCode}',
          };
        }
      }
      return {'status': 'error', 'detail': 'Network Error. Check connection.'};
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      log('📡 Attempting Registration for: ${userData['identifier']}');
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        // 🚨 THIS IS THE CRITICAL FIX: Check if it's JSON before reading it!
        if (e.response!.data is Map<String, dynamic>) {
          return {
            'status': 'error',
            'detail': e.response!.data['detail'] ?? 'Registration failed',
          };
        } else {
          // If Python crashes and sends text, we catch it gracefully here
          return {
            'status': 'error',
            'detail': 'Server crashed (500). Check Python terminal.',
          };
        }
      }
      return {'status': 'error', 'detail': 'Network Error. Check connection.'};
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
        'detail': e.response?.data?['detail'] ?? 'Network error',
      };
    } catch (e) {
      return {'status': 'error', 'detail': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getUserAssets() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return null;

      log('📡 Fetching Assets for User: $userId');
      // 2. Fixed the double /api/api typo (Fixed 404 Error)
      final response = await _dio.get('/user/$userId/assets');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      log('❌ Error fetching assets: $e');
      return null;
    }
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
        'detail': e.response?.data?['detail'] ?? 'Network error',
      };
    } catch (e) {
      return {'status': 'error', 'detail': 'Unexpected error: $e'};
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
        'detail': e.response?.data?['detail'] ?? 'Network error',
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
        'detail': e.response?.data?['detail'] ?? 'Network error',
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
      return {'status': 'error', 'detail': 'Network Error. Check connection.'};
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
      return {'status': 'error', 'detail': 'Network Error. Check connection.'};
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
      return {'status': 'error', 'detail': 'Network Error. Check connection.'};
    }
  }

  // --- AI CHATBOT METHOD ---
  // --- AI CHATBOT METHOD ---
  static Future<String> sendChatMessage(
    String message, {
    String? currentTicker,
  }) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'text': message,
          if (currentTicker != null)
            'current_ticker': currentTicker, // Send the ticker to Python!
        },
      );
      if (response.statusCode == 200 && response.data['reply'] != null) {
        // Clean the string by replacing all '**' with nothing!
        String cleanReply = response.data['reply'].replaceAll('**', '');
        return cleanReply;
      }
      return "Sorry, I couldn't process that.";
    } on DioException catch (e) {
      // 🚨 NEW: Catch timeouts and print exact errors to your terminal!
      log("🚨 CHAT ERROR: ${e.type} - ${e.message}");

      if (e.type == DioExceptionType.receiveTimeout) {
        return "Lexi is processing a lot of portfolio data right now! Give me a few more seconds and try again.";
      }
      return "Network error. Please check your connection.";
    } catch (e) {
      log("🚨 GENERAL ERROR: $e");
      return "An unexpected error occurred.";
    }
  }
}
