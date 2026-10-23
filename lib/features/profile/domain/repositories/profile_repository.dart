import 'dart:io';
import '../../data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile({required String token});
  Future<ProfileModel> updateProfile({
    required String token,
    required String username,
    required String email,
    String? phoneNumber,
    String? bio,
  });
  Future<ProfileModel> uploadPhoto({
    required String token,
    required File photoFile,
  });
  Future<void> deletePhoto({required String token});
  Future<ProfileModel?> getCachedProfile();
}
