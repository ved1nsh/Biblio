class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['user_metadata']?['full_name'] as String?,
      photoUrl: json['user_metadata']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
