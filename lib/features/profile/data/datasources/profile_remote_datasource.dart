import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/api_constants.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String token});
  Future<ProfileModel> updateProfile({
    required String token,
    required String username,
    required String email,
    String? phoneNumber,
    String? bio,
  });
  Future<ProfileModel> uploadProfilePhoto({
    required String token,
    required File photoFile,
  });
  Future<void> deleteProfilePhoto({required String token});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  ProfileRemoteDataSourceImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  @override
  Future<ProfileModel> getProfile({required String token}) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.profileEndpoint}');
    try {
      final response = await _client.get(url, headers: _authHeaders(token));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('profile')
            ? body['profile']
            : (body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body);
        return ProfileModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to load profile');
  }

  @override
  Future<ProfileModel> updateProfile({
    required String token,
    required String username,
    required String email,
    String? phoneNumber,
    String? bio,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.profileEndpoint}');
    final payload = <String, dynamic>{
      'username': username,
      'email': email,
      'phone_number': ?phoneNumber,
      'bio': ?bio,
    };

    try {
      final response = await _client.patch(
        url,
        headers: {
          ..._authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return ProfileModel(
            id: '',
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            bio: bio,
          );
        }
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('profile')
            ? body['profile']
            : (body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body);
        return ProfileModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to update profile');
  }

  @override
  Future<ProfileModel> uploadProfilePhoto({
    required String token,
    required File photoFile,
  }) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.profilePhotoEndpoint}');
    try {
      final request = http.MultipartRequest('PUT', url)
        ..headers.addAll(_authHeaders(token))
        ..files.add(await http.MultipartFile.fromPath(
          'photo',
          photoFile.path,
          contentType: MediaType.parse(_mimeFromPath(photoFile.path)),
        ));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          return ProfileModel(
            id: '',
            username: '',
            email: '',
          );
        }
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('profile')
            ? body['profile']
            : (body is Map<String, dynamic> && body.containsKey('data') ? body['data'] : body);
        return ProfileModel.fromJson(data as Map<String, dynamic>);
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
    throw Exception('Failed to upload photo');
  }

  @override
  Future<void> deleteProfilePhoto({required String token}) async {
    final url = Uri.parse('$_baseUrl${ApiConstants.profilePhotoEndpoint}');
    try {
      final response = await _client.delete(url, headers: _authHeaders(token));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      _throwFromResponse(response);
    } on SocketException {
      throw Exception('Network error: Could not reach server');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  void _throwFromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final msg = body['detail'] ?? body['message'] ?? response.reasonPhrase;
      throw Exception(msg.toString());
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatException')) rethrow;
      throw Exception('Server error (${response.statusCode})');
    }
  }

  String _mimeFromPath(String filePath) {
    final ext = path.extension(filePath).toLowerCase().replaceFirst('.', '');
    const mimeMap = {
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'webp': 'image/webp',
    };
    return mimeMap[ext] ?? 'image/jpeg';
  }
}
