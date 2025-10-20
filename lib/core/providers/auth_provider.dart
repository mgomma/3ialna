import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthProvider(this._apiService, this._storageService) {
    _initializeAuth();
  }

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _apiService.isAuthenticated;

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      await _apiService.initializeTokens();
      if (_apiService.isAuthenticated) {
        _currentUser = await _apiService.getUserProfile();
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(email, password);
      
      if (response['success']) {
        final userData = response['data']['user'];
        _currentUser = User.fromJson(userData);
        
        // Save user role to storage
        await _storageService.saveUserRole(_currentUser!.role);
        
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(userData);
      
      if (response['success']) {
        final userData = response['data']['user'];
        _currentUser = User.fromJson(userData);
        
        // Save user role to storage
        await _storageService.saveUserRole(_currentUser!.role);
        
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _apiService.logout();
      await _storageService.clearAuthTokens();
      await _storageService.clearUserData();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      // This would be implemented in the API service
      // final response = await _apiService.resetPassword(email);
      // return response['success'];
      
      // Placeholder implementation
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _apiService.updateUserProfile(profileData);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Role-based access control helpers
  bool canAccessAdminFeatures() {
    return _currentUser?.isAdmin ?? false;
  }

  bool canAccessMasterParentFeatures() {
    return _currentUser?.isMasterParent ?? false;
  }

  bool canAccessParentFeatures() {
    return _currentUser?.isParent ?? false;
  }

  String getUserRole() {
    return _currentUser?.role ?? 'guest';
  }

  String getUserDisplayName() {
    return _currentUser?.fullName ?? 'Guest';
  }
}
