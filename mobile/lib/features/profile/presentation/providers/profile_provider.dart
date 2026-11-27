import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

sealed class ProfileState {
  const ProfileState();
}
final class ProfileInitial extends ProfileState { const ProfileInitial(); }
final class ProfileLoading extends ProfileState { const ProfileLoading(); }
final class ProfileLoaded  extends ProfileState {
  const ProfileLoaded(this.profile);
  final ProfileEntity profile;
}
final class ProfileError   extends ProfileState {
  const ProfileError(this.failure);
  final Failure failure;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(const ProfileInitial());

  final ProfileRepository _repository;

  Future<void> load() async {
    state = const ProfileLoading();
    final result = await _repository.getProfile();
    result.fold(
      (failure) => state = ProfileError(failure),
      (profile) => state = ProfileLoaded(profile),
    );
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
  }) async {
    state = const ProfileLoading();
    final result = await _repository.updateProfile(
      fullName: fullName, phone: phone, bio: bio);
    return result.fold(
      (failure) {
        state = ProfileError(failure);
        return false;
      },
      (profile) {
        state = ProfileLoaded(profile);
        return true;
      },
    );
  }
}
