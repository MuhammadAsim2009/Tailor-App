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
    super.dispose();
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileToSave = updatedProfile.copyWith(updatedAt: DateTime.now());
      await DatabaseService.instance.updateProfile(profileToSave.toMap());
      _profile = profileToSave;
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
