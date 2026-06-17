import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../services/database_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;

  static final ProfileController _instance = ProfileController._internal();
  
  factory ProfileController() => _instance;

  ProfileController._internal() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseService.instance.getProfile();
      _profile = ProfileModel.fromMap(data);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Intentionally left empty to prevent singleton disposal
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseService.instance.updateProfile(updatedProfile.toMap());
      _profile = updatedProfile;
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
