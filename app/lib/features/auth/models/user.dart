/// User Model
class User {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? locationState;
  final String? locationCity;
  final String? tradeNotes;
  final String profileVisibility;
  final String binderVisibility;
  final String locationVisibility;
  final String messageVisibility;
  final String tradeVisibility;
  final String tradeNotesVisibility;
  final bool emailVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.locationState,
    this.locationCity,
    this.tradeNotes,
    this.profileVisibility = 'public',
    this.binderVisibility = 'public',
    this.locationVisibility = 'private',
    this.messageVisibility = 'everyone',
    this.tradeVisibility = 'everyone',
    this.tradeNotesVisibility = 'private',
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      locationState: json['location_state'] as String?,
      locationCity: json['location_city'] as String?,
      tradeNotes: json['trade_notes'] as String?,
      profileVisibility: json['profile_visibility']?.toString() ?? 'public',
      binderVisibility: json['binder_visibility']?.toString() ?? 'public',
      locationVisibility: json['location_visibility']?.toString() ?? 'private',
      messageVisibility: json['message_visibility']?.toString() ?? 'everyone',
      tradeVisibility: json['trade_visibility']?.toString() ?? 'everyone',
      tradeNotesVisibility:
          json['trade_notes_visibility']?.toString() ?? 'private',
      emailVerified: json['email_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'location_state': locationState,
      'location_city': locationCity,
      'trade_notes': tradeNotes,
      'profile_visibility': profileVisibility,
      'binder_visibility': binderVisibility,
      'location_visibility': locationVisibility,
      'message_visibility': messageVisibility,
      'trade_visibility': tradeVisibility,
      'trade_notes_visibility': tradeNotesVisibility,
      'email_verified': emailVerified,
    };
  }

  /// Retorna label de localização formatada (ex: "São Paulo, SP")
  String? get locationLabel {
    if (locationCity != null && locationState != null) {
      return '$locationCity, $locationState';
    }
    if (locationState != null) return locationState;
    return null;
  }

  User copyWith({
    String? displayName,
    String? avatarUrl,
    String? locationState,
    String? locationCity,
    String? tradeNotes,
    String? profileVisibility,
    String? binderVisibility,
    String? locationVisibility,
    String? messageVisibility,
    String? tradeVisibility,
    String? tradeNotesVisibility,
    bool? emailVerified,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locationState: locationState ?? this.locationState,
      locationCity: locationCity ?? this.locationCity,
      tradeNotes: tradeNotes ?? this.tradeNotes,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      binderVisibility: binderVisibility ?? this.binderVisibility,
      locationVisibility: locationVisibility ?? this.locationVisibility,
      messageVisibility: messageVisibility ?? this.messageVisibility,
      tradeVisibility: tradeVisibility ?? this.tradeVisibility,
      tradeNotesVisibility: tradeNotesVisibility ?? this.tradeNotesVisibility,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
