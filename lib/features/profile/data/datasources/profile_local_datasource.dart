import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<void> saveProfile(ProfileModel profile);
  Future<ProfileModel?> getProfile();
  Future<void> deleteProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final FlutterSecureStorage _storage;

  ProfileLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _profileKey = 'doclock_cached_profile';

  @override
  Future<void> saveProfile(ProfileModel profile) async {
    await _storage.write(
      key: _profileKey,
      value: jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<ProfileModel?> getProfile() async {
    final raw = await _storage.read(key: _profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteProfile() async {
    await _storage.delete(key: _profileKey);
  }
}
