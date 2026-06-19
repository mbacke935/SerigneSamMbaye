class UserModel {
  final int id;
  final String email;
  final String username;
  final String? photoProfil;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.photoProfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        photoProfil: json['photo_profil'] as String?,
      );

  String get initiale => username.isNotEmpty ? username[0].toUpperCase() : '?';
}
