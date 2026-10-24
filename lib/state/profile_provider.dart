import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/profile/data/profile_models.dart';
import 'package:attendance/features/profile/data/profile_service.dart';
import 'package:attendance/services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileService? service, AuthService? auth})
    : _service = service ?? ProfileService(),
      _auth = auth ?? AuthService();

  final ProfileService _service;
  final AuthService _auth;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool get isAdmin => _profile?.isAdmin ?? false;

  bool get isManager => _profile?.isManager ?? false;

  bool get isAdminOrManager => _profile?.isAdminOrManager ?? false;

  bool get seesAdminDashboard => _profile?.seesAdminDashboard ?? false;

  bool get canReviewLeaveAndWfh => _profile?.canReviewLeaveAndWfh ?? false;

  bool get canEditOfficeTiming => _profile?.canEditOfficeTiming ?? false;

  bool get showsAttendanceInDrawer => _profile?.showsAttendanceInDrawer ?? false;

  bool get canMarkTeamAttendance => _profile?.canMarkTeamAttendance ?? false;

  bool get canSelfPunchAttendance => _profile?.canSelfPunchAttendance ?? false;

  bool get canAccessTeamManagement => _profile?.canAccessTeamManagement ?? false;

  bool get canSubmitLeaveRequest => _profile?.canSubmitLeaveRequest ?? false;

  bool get canSubmitWfhRequest => _profile?.canSubmitWfhRequest ?? false;

  bool get canAccessEmployeeModule => _profile?.canAccessEmployeeModule ?? false;

  bool get canAccessDocumentsModule => _profile?.canAccessDocumentsModule ?? false;
  bool get canAccessClientModule => _profile?.canAccessClientModule ?? false;
  bool get canAccessLeadModule => _profile?.canAccessLeadModule ?? false;
  bool get canManageProjects => _profile?.canManageProjects ?? false;
  bool get canManageTasks => _profile?.canManageTasks ?? false;
  bool get canManageMeetings => _profile?.canManageMeetings ?? false;

  /// Call after login or logout so the next session loads the correct role.
  void resetSession() {
    _profile = null;
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> hydrateFromStoredAuthUser() async {
    await _hydrateFromAuthCache();
    notifyListeners();
  }

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  bool _saving = false;
  bool get saving => _saving;

  DateTime? _loadedAt;
  int _loadSeq = 0;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded && _profile != null && CacheStamp.isFresh(_loadedAt, CachePolicy.profileTtl)) return;
    await refresh(force: false);
  }

  Future<void> refresh({bool force = true}) async {
    if (!force && _hasLoaded && _profile != null && CacheStamp.isFresh(_loadedAt, CachePolicy.profileTtl)) {
      return;
    }
    final seq = ++_loadSeq;
    _loading = _profile == null;
    _error = null;
    notifyListeners();
    try {
      final p = await _service.fetchProfile();
      if (seq != _loadSeq) return;
      _profile = p;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq) {
        _error = e;
        await _hydrateFromAuthCache();
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateFromAuthCache() async {
    final user = await _auth.getUser();
    if (user == null) return;
    _profile = UserProfile.fromJson(user);
    _hasLoaded = true;
  }

  Future<bool> updateProfile({required String name, required String email}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.updateProfile(name: name, email: email);
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar({required String filePath, required String filename}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.uploadAvatar(filePath: filePath, filename: filename);
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    resetSession();
  }
}
