import 'package:attendance/core/auth/user_role_slugs.dart';
import 'package:attendance/services/app_config.dart';

class ProfileReportingManager {
  const ProfileReportingManager({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;

  static ProfileReportingManager? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    final manager = ProfileReportingManager(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
    return manager.id > 0 || manager.name.isNotEmpty ? manager : null;
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

class ProfileEmployee {
  const ProfileEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.employmentType,
    required this.status,
    this.reportingManagerId,
    this.reportingManager,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final String employmentType;
  final String status;
  final int? reportingManagerId;
  final ProfileReportingManager? reportingManager;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'designation': designation,
    'department': department,
    'employment_type': employmentType,
    'status': status,
    'reporting_manager_id': reportingManagerId,
    'reporting_manager': reportingManager?.toJson(),
  };

  factory ProfileEmployee.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProfileEmployee(
        id: 0,
        name: '',
        email: '',
        phone: '',
        designation: '',
        department: '',
        employmentType: '',
        status: '',
      );
    }
    return ProfileEmployee(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      designation: (json['designation'] as String?) ?? '',
      department: (json['department'] as String?) ?? '',
      employmentType: (json['employment_type'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      reportingManagerId: int.tryParse((json['reporting_manager_id'] ?? '').toString()),
      reportingManager: ProfileReportingManager.tryParse(json['reporting_manager']),
    );
  }
}

class UserRole {
  const UserRole({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory UserRole.fromJson(Map<String, dynamic> json) => UserRole(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    name: (json['name'] as String?) ?? '',
    slug: (json['slug'] as String?) ?? '',
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.emailVerifiedAt,
    required this.role,
    this.employee,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? emailVerifiedAt;
  final UserRole role;
  final ProfileEmployee? employee;
  final String? createdAt;
  final String? updatedAt;

  String get roleSlug => role.slug.toLowerCase().trim();

  bool get isAdmin => roleSlug == UserRoleSlugs.admin;

  bool get isManager => roleSlug == UserRoleSlugs.manager;

  /// Admin and manager share operational dashboards and request approvals.
  bool get isAdminOrManager => isAdmin || isManager;

  bool get seesAdminDashboard => isAdminOrManager;

  bool get canReviewLeaveAndWfh => isAdminOrManager;

  bool get canEditOfficeTiming => isAdmin;

  /// Drawer attendance module for all roles (admin sees org records + mark actions).
  bool get showsAttendanceInDrawer => true;

  /// Mark attendance / holiday for others (admin and manager).
  bool get canMarkTeamAttendance => isAdminOrManager;

  /// Personal check-in / check-out (employees and managers).
  bool get canSelfPunchAttendance => !isAdmin;

  /// Team hub (members, attendance, leave) for managers and admins.
  bool get canAccessTeamManagement => isAdminOrManager;

  /// Submit own leave (employees and managers; admins review only).
  bool get canSubmitLeaveRequest => !isAdmin;

  bool get canSubmitWfhRequest => !isAdmin;

  bool get canAccessEmployeeModule => isAdminOrManager;

  bool get canAccessDocumentsModule => isAdminOrManager;

  bool get canAccessClientModule => isAdminOrManager;

  bool get canAccessLeadModule => isAdminOrManager;

  /// Create projects, update status, delete, upload/delete project files.
  bool get canManageProjects => isAdminOrManager;

  /// Create, edit, delete tasks and delete task files.
  bool get canManageTasks => isAdminOrManager;

  /// Create, edit, delete meetings and upload/delete meeting files.
  bool get canManageMeetings => isAdminOrManager;

  String? get avatarUrl {
    final raw = avatar?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return Uri.parse(AppConfig.baseUrl.trim()).resolve(raw).toString();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['role'];
    final empRaw = json['employee'];
    ProfileEmployee? employee;
    if (empRaw is Map<String, dynamic>) {
      final parsed = ProfileEmployee.fromJson(empRaw);
      if (parsed.id > 0) employee = parsed;
    } else if (empRaw is Map) {
      final parsed = ProfileEmployee.fromJson(empRaw.cast<String, dynamic>());
      if (parsed.id > 0) employee = parsed;
    }
    return UserProfile(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      avatar: json['avatar'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      role: roleRaw is Map<String, dynamic>
          ? UserRole.fromJson(roleRaw)
          : roleRaw is Map
          ? UserRole.fromJson(roleRaw.cast<String, dynamic>())
          : const UserRole(id: 0, name: '', slug: ''),
      employee: employee,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toAuthUserJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'role': {'id': role.id, 'name': role.name, 'slug': role.slug},
    'employee': employee?.toJson(),
  };

  UserProfile copyWith({String? name, String? email, String? avatar}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      emailVerifiedAt: emailVerifiedAt,
      role: role,
      employee: employee,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
