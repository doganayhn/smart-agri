import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/dio_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  static const _absent = Object();

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Object? error = _absent,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _absent) ? this.error : error as String?,
    );
  }
}

class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final tokenProvider = NotifierProvider<TokenNotifier, String?>(() => TokenNotifier());

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return await _checkInitialAuth();
  }

  Future<AuthState> _checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      ref.read(tokenProvider.notifier).state = token;
      return AuthState(isAuthenticated: true);
    }
    return AuthState();
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        ref.read(tokenProvider.notifier).state = token;
        state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: true));
        return true;
      } else {
        state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: 'Invalid response from server'));
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message ?? 'Login failed';
      state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: msg));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: 'Unexpected error occurred'));
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': name,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false));
        return true;
      } else {
        state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: 'Registration failed'));
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message ?? 'Registration failed';
      state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: msg));
      return false;
    } catch (e) {
      state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false, error: 'Unexpected error occurred'));
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    ref.read(tokenProvider.notifier).state = null;
    state = AsyncValue.data(AuthState(isLoading: false, isAuthenticated: false));
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
