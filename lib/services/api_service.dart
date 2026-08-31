import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Android emulator: 10.0.2.2. HP fisik: ganti dengan IP LAN/server HTTPS.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String noHp,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'noHp': noHp, 'password': password}),
    );

    final data = _decode(response);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Login gagal.');
    }

    await _storage.write(key: 'jwt_token', value: data['token']?.toString());
    await _storage.write(key: 'user_role', value: data['user']?['role']?.toString());
    await _storage.write(key: 'user_id', value: data['user']?['id']?.toString());
    return data;
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> logout() => _storage.deleteAll();

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      return value is Map<String, dynamic>
          ? value
          : {'success': false, 'message': 'Respons server tidak valid.'};
    } catch (_) {
      return {'success': false, 'message': 'Server mengirim respons tidak valid.'};
    }
  }
}
