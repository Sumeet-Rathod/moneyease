import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String mobile;

  AuthUser({
    required this.id,
    required this.name,
    required this.role,
    this.email = '',
    this.mobile = '',
  });
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? role;
  final int? userId;
  final String? userName;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.role,
    this.userId,
    this.userName,
    this.errorMessage,
  });

  AuthUser? get user {
    if (!isAuthenticated || userId == null) return null;
    return AuthUser(
      id: userId!,
      name: userName ?? 'User',
      role: role ?? 'customer',
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? role,
    int? userId,
    String? userName,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final token = await SecureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final role = await SecureStorageService.getUserRole();
      final userId = await SecureStorageService.getUserId();
      final name = await SecureStorageService.getUserName();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        role: role,
        userId: userId,
        userName: name,
      );
    } else {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<String?> requestOtp(String mobile) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.post('/auth/request-otp', data: {'mobile': mobile});
      state = state.copyWith(isLoading: false);
      return res.data['dev_otp']?.toString();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
      return null;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.post('/auth/verify-otp', data: {
        'mobile': mobile,
        'otp': otp,
      });
      final data = res.data;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final user = data['user'];

      await SecureStorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user['role'],
        userId: user['id'],
        name: user['name'] ?? '',
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        role: user['role'],
        userId: user['id'],
        userName: user['name'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    String? email,
    String? mobile,
    String? password,
    required bool consentAccepted,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email?.isNotEmpty == true ? email : null,
        'mobile': mobile?.isNotEmpty == true ? mobile : null,
        'password': password?.isNotEmpty == true ? password : null,
        'consent_accepted': consentAccepted,
      });

      final data = res.data;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final user = data['user'];

      await SecureStorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user['role'],
        userId: user['id'],
        name: user['name'] ?? '',
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        role: user['role'],
        userId: user['id'],
        userName: user['name'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> login(String emailOrMobile, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {
        'email_or_mobile': emailOrMobile,
        'password': password,
      });

      final data = res.data;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final user = data['user'];

      await SecureStorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user['role'],
        userId: user['id'],
        name: user['name'] ?? '',
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        role: user['role'],
        userId: user['id'],
        userName: user['name'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ApiClient.getErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clearAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
