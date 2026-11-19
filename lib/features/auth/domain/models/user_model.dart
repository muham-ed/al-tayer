enum UserRole {
  customer,
  driver,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? token;
  final bool isOnline; // خاص بالمندوب

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.role = UserRole.customer,
    this.token,
    this.isOnline = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? role,
    String? token,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      token: token ?? this.token,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role.name,
    'token': token,
    'isOnline': isOnline,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.customer,
    ),
    token: json['token'],
    isOnline: json['isOnline'] ?? false,
  );
}
