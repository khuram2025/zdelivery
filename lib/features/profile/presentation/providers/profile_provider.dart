import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/delivery_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models.dart';

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService(ref.read(apiServiceProvider));
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.read(deliveryServiceProvider));
});

class ProfileState {
  final bool isLoading;
  final AgentProfile? profile;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    AgentProfile? profile,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final DeliveryService _deliveryService;

  ProfileNotifier(this._deliveryService) : super(ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _deliveryService.getProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load profile');
    }
  }

  Future<bool> updateStatus(String status, {double? latitude, double? longitude}) async {
    try {
      await _deliveryService.updateStatus(
        status: status,
        latitude: latitude,
        longitude: longitude,
      );
      if (state.profile != null) {
        final updatedProfile = AgentProfile(
          id: state.profile!.id,
          agentCode: state.profile!.agentCode,
          name: state.profile!.name,
          phoneNumber: state.profile!.phoneNumber,
          alternatePhone: state.profile!.alternatePhone,
          profilePhoto: state.profile!.profilePhoto,
          vehicleType: state.profile!.vehicleType,
          vehicleNumber: state.profile!.vehicleNumber,
          status: status,
          totalDeliveries: state.profile!.totalDeliveries,
          successfulDeliveries: state.profile!.successfulDeliveries,
          averageRating: state.profile!.averageRating,
          totalRatings: state.profile!.totalRatings,
          earningsBalance: state.profile!.earningsBalance,
          totalEarnings: state.profile!.totalEarnings,
          isVerified: state.profile!.isVerified,
        );
        state = state.copyWith(profile: updatedProfile);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile({
    String? phoneNumber,
    String? alternatePhone,
    String? vehicleNumber,
    File? profilePhoto,
  }) async {
    try {
      final profile = await _deliveryService.updateProfile(
        phoneNumber: phoneNumber,
        alternatePhone: alternatePhone,
        vehicleNumber: vehicleNumber,
        profilePhoto: profilePhoto,
      );
      state = state.copyWith(profile: profile);
      return true;
    } catch (e) {
      return false;
    }
  }
}
