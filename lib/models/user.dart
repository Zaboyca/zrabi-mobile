class SpecialistProfileSummary {
  const SpecialistProfileSummary({
    required this.id,
    this.slug,
    this.title,
    this.isPublished = false,
    this.cityId,
  });

  final int id;
  final String? slug;
  final String? title;
  final bool isPublished;
  final int? cityId;

  factory SpecialistProfileSummary.fromJson(Map<String, dynamic> json) {
    return SpecialistProfileSummary(
      id: json['id'] as int,
      slug: json['slug'] as String?,
      title: json['title'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      cityId: json['city_id'] as int?,
    );
  }
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.specialistStatus,
    this.accountLabel,
    this.canOrder = false,
    this.isSpecialist = false,
    this.isAdmin = false,
    this.canApplyAsSpecialist = false,
    this.emailVerifiedAt,
    this.specialistProfile,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? specialistStatus;
  final String? accountLabel;
  final bool canOrder;
  final bool isSpecialist;
  final bool isAdmin;
  final bool canApplyAsSpecialist;
  final String? emailVerifiedAt;
  final SpecialistProfileSummary? specialistProfile;

  String get specialistStatusLabel {
    switch (specialistStatus) {
      case 'approved':
        return 'Исполнитель';
      case 'pending':
        return 'На модерации';
      case 'rejected':
        return 'Отклонено';
      case 'none':
        return 'Не исполнитель';
      default:
        return specialistStatus ?? '—';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['specialist_profile'];
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      specialistStatus: json['specialist_status'] as String?,
      accountLabel: json['account_label'] as String?,
      canOrder: json['can_order'] as bool? ?? false,
      isSpecialist: json['is_specialist'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      canApplyAsSpecialist: json['can_apply_as_specialist'] as bool? ?? false,
      emailVerifiedAt: json['email_verified_at'] as String?,
      specialistProfile: profileRaw is Map<String, dynamic>
          ? SpecialistProfileSummary.fromJson(profileRaw)
          : null,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
