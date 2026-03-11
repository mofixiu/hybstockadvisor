import 'dart:developer';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';

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

String get baseUrl => "$host/api";

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  static String currentTicker = "GTCO";
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
    String email,
    String password,
  ) async {
    try {
      log('📡 Attempting Login for: $email');
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
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
      log('📡 Attempting Registration for: ${userData['email']}');
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
      final box = await Hive.openBox('auth');
      final userId = box.get('user_id') ?? 1;

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
    }
  }

  static Future<Map<String, dynamic>?> getUserAssets() async {
    try {
      final box = await Hive.openBox('auth');
      final userId = box.get('user_id') ?? 1;

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
      final box = await Hive.openBox('auth');
      final userId = box.get('user_id') ?? 1;

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
  static Future<String> sendChatMessage(String message, {String? currentTicker}) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'text': message,
          if (currentTicker != null) 'current_ticker': currentTicker, // Send the ticker to Python!
        },
      );
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['reply'];
      }
      return "Sorry, I couldn't process that.";
    } catch (e) {
      return "Network error. Please check your connection.";
    }
  }
}
