import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/token_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenModel> login({required String email, required String password});
  Future<TokenModel> register({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  AuthRemoteDataSourceImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  @override
  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.loginEndpoint}');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TokenModel.fromJson(responseData);
      } else {
        final message = responseData['detail'] ?? 'Failed to authenticate';
        throw Exception(message.toString());
      }
    } on FormatException {
      throw Exception('Invalid server response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Could not reach backend server at $_baseUrl');
    }
  }

  @override
  Future<TokenModel> register({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.registerEndpoint}');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TokenModel.fromJson(responseData);
      } else {
        final message = responseData['detail'] ?? 'Failed to create account';
        throw Exception(message.toString());
      }
    } on FormatException {
      throw Exception('Invalid server response format');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: Could not reach backend server at $_baseUrl');
    }
  }
}
