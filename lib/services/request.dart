import 'dart:developer';
import 'dart:convert' as dart_convert;
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Platform-specific host configuration
String get host {
  if (kIsWeb) {
    return "http://localhost:3001";
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:3001";
    // return "http://192.168.1.XXX:3001"; // For physical device
  } else if (Platform.isIOS) {
    return "http://localhost:3001";
  } else {
    return "http://localhost:3001";
  }
}

String get baseUrl => "$host/api";

class RequestService {
  static late Dio _dio;
  static String? _authToken;
  static bool _isInitialized = false;

  // Initialize RequestService with Dio setup
  static Future<void> initialize() async {
    if (_isInitialized) {
      log('RequestService already initialized');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Load token first before setting up interceptors
    await loadAuthToken();

    // Add interceptors for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get fresh token from storage before each request
          if (_authToken == null) {
            await loadAuthToken();
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          log('REQUEST: ${options.method} ${options.uri}');
          log('DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            'RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
          );
          log('RESPONSE DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          log('ERROR: ${error.message}');
          if (error.response != null) {
            log('ERROR RESPONSE: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
    log('RequestService initialized successfully');
  }

  // Load auth token from storage
  static Future<void> loadAuthToken() async {
    try {
      final box = await Hive.openBox(
        'auth',
      ); // Changed from 'userBox' to 'auth'
      final token = box.get('token'); // Changed from 'auth_token' to 'token'
      if (token != null) {
        _authToken = token;
        log('Auth token loaded from storage');
      } else {
        log('No auth token found in storage');
      }
    } catch (e) {
      log('Error loading auth token: $e');
    }
  }

  // Get current auth token
  static String? get authToken => _authToken;

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Auth Methods
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    return post('/auth/login', {'email': email, 'password': password});
  }

  // Password Reset Methods
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    return post('/auth/forgot-password', {'email': email});
  }

  static Future<Map<String, dynamic>?> verifyResetOTP(
    String email,
    String otp,
  ) async {
    return post('/auth/verify-reset-otp', {'email': email, 'otp': otp});
  }

  static Future<Map<String, dynamic>?> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    return post('/auth/reset-password', {
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }

  // Generic HTTP Methods
  static Future<Map<String, dynamic>?> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making POST request to: $path');
      final response = await _dio.post(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          try {
            final Map<String, dynamic> parsed = Map<String, dynamic>.from(
              dart_convert.jsonDecode(response.data),
            );
            return parsed;
          } catch (e) {
            log('Failed to parse string response as JSON: $e');
            return {
              'status': 'error',
              'message': 'Invalid response format',
              'data': response.data,
            };
          }
        } else {
          return {'status': 'success', 'data': response.data};
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> get(String path) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      final response = await _dio.get(path);

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making PATCH request to: $path');
      final response = await _dio.patch(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('PATCH DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('PATCH General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making PUT request to: $path');
      log('PUT data: $data');

      final response = await _dio.put(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('PUT response: ${response.data}');
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'status': 'success', 'data': response.data};
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('PUT DioException: ${e.message}');
      if (e.response != null) {
        log('PUT Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('PUT General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> delete(String path) async {
    try {
      if (!isInitialized) {
        throw Exception('RequestService not initialized');
      }

      log('DELETE Request to: $baseUrl$path');
      final response = await _dio.delete(path);

      log('DELETE Response: ${response.data}');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'success', 'data': response.data};
    } catch (e) {
      log('DELETE Error: $e');
      return {'status': 'error', 'message': 'Delete failed: $e'};
    }
  }

  // Auth token management
  static Future<void> saveAuthToken(String token) async {
    try {
      _authToken = token;
      final box = await Hive.openBox('auth');
      await box.put('token', token);
      log('Auth token saved');
    } catch (e) {
      log('Error saving auth token: $e');
    }
  }

  // User data management
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final box = await Hive.openBox('user');
      await box.put('userData', dart_convert.jsonEncode(userData));
      log('User data saved');
    } catch (e) {
      log('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final box = await Hive.openBox('user');
      final userDataString = box.get('userData');
      if (userDataString != null) {
        log('User data loaded from storage');
        return dart_convert.jsonDecode(userDataString);
      }
      log('No user data found in storage');
      return null;
    } catch (e) {
      log('Error loading user data: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async {
    try {
      // Clear both auth and user boxes
      final authBox = await Hive.openBox('auth');
      await authBox.clear();

      final userBox = await Hive.openBox('user');
      await userBox.clear();

      final chatBox = await Hive.openBox('chat_history');
      await chatBox.clear();

      _authToken = null;
      log('User data cleared');
    } catch (e) {
      log('Error clearing user data: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      await clearUserData();
      log('All data cleared');
    } catch (e) {
      log('Error clearing all data: $e');
    }
  }

  // Get student by ID (for fetching internship dates)
  static Future<Map<String, dynamic>?> getStudentById(int studentId) async {
    return get('/students/$studentId');
  }

  // Get supervisor by ID (for fetching supervisor profile)
  static Future<Map<String, dynamic>?> getSupervisorById(
    int supervisorId,
  ) async {
    return get('/supervisors/$supervisorId');
  }
}
