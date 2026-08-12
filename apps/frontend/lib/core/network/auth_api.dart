import 'api_client.dart';
import 'token_store.dart';

class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
      );
}

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AuthUser user;
  final String token;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token']?.toString() ?? '',
      );
}

class AuthApi {
  AuthApi({ApiClient? client, TokenStore? tokenStore})
      : _client = client ?? ApiClient(tokenStore: tokenStore),
        _tokenStore = tokenStore ?? TokenStore();

  final ApiClient _client;
  final TokenStore _tokenStore;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return _saveSession(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _saveSession(response);
  }

  Future<AuthUser> me() async {
    final response = await _client.get('/auth/me');
    final data = response['data'];
    final user = data is Map<String, dynamic> && data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return AuthUser.fromJson(user);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<AuthSession> _saveSession(Map<String, dynamic> response) async {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Authentication response is missing data.');
    }
    final session = AuthSession.fromJson(data);
    await _tokenStore.write(session.token);
    return session;
  }
}
