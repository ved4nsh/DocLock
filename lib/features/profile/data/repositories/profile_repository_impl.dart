import 'dart:io';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  ProfileRepositoryImpl({
    ProfileRemoteDataSource? remoteDataSource,
    ProfileLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl(),
        _localDataSource = localDataSource ?? ProfileLocalDataSourceImpl();

  @override
  Future<ProfileModel> getProfile({required String token}) async {
    try {
      final remoteProfile = await _remoteDataSource.getProfile(token: token);
      await _localDataSource.saveProfile(remoteProfile);
      return remoteProfile;
    } catch (e) {
      final cached = await _localDataSource.getProfile();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ProfileModel> updateProfile({
    required String token,
    required String username,
    required String email,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      final updated = await _remoteDataSource.updateProfile(
        token: token,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        bio: bio,
      );
      await _localDataSource.saveProfile(updated);
      return updated;
    } catch (e) {
      // If remote fails but we have cached profile, update cached as fallback
      final cached = await _localDataSource.getProfile();
      if (cached != null) {
        final fallback = cached.copyWith(
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          bio: bio,
        );
        await _localDataSource.saveProfile(fallback);
      }
      rethrow;
    }
  }

  @override
  Future<ProfileModel> uploadPhoto({
    required String token,
    required File photoFile,
  }) async {
    final updated = await _remoteDataSource.uploadProfilePhoto(
      token: token,
      photoFile: photoFile,
    );
    await _localDataSource.saveProfile(updated);
    return updated;
  }

  @override
  Future<void> deletePhoto({required String token}) async {
    await _remoteDataSource.deleteProfilePhoto(token: token);
    final cached = await _localDataSource.getProfile();
    if (cached != null) {
      await _localDataSource.saveProfile(cached.copyWith(photoUrl: ''));
    }
  }

  @override
  Future<ProfileModel?> getCachedProfile() async {
    return await _localDataSource.getProfile();
  }
}
