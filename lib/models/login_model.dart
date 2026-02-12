class LoginResponse {
  final String token;
  final AppLogin appLogin;
  final String warehouseCode;
  final List<dynamic> rolePermissions;

  LoginResponse({
    required this.token,
    required this.appLogin,
    required this.warehouseCode,
    required this.rolePermissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      appLogin: AppLogin.fromJson(json['AppLogin'] ?? {}),
      warehouseCode: json['warehouseCode'] ?? '',
      rolePermissions: json['RolePermissions'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'AppLogin': appLogin.toJson(),
      'warehouseCode': warehouseCode,
      'RolePermissions': rolePermissions,
    };
  }
}

class AppLogin {
  final bool active;
  final String email;
  final String id;
  final String name;
  final String user;
  final int sapId;
  final dynamic activeBurn;
  final int serie;
  final String lastPasswordChange;

  AppLogin({
    required this.active,
    required this.email,
    required this.id,
    required this.name,
    required this.user,
    required this.sapId,
    this.activeBurn,
    required this.serie,
    required this.lastPasswordChange,
  });

  factory AppLogin.fromJson(Map<String, dynamic> json) {
    return AppLogin(
      active: json['active'] ?? false,
      email: json['Email'] ?? '',
      id: json['id'] ?? '',
      name: json['Name'] ?? '',
      user: json['User'] ?? '',
      sapId: json['SAPID'] ?? 0,
      activeBurn: json['Active_Burn'],
      serie: json['Serie'] ?? 0,
      lastPasswordChange: json['LastPasswordChange'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'Email': email,
      'id': id,
      'Name': name,
      'User': user,
      'SAPID': sapId,
      'Active_Burn': activeBurn,
      'Serie': serie,
      'LastPasswordChange': lastPasswordChange,
    };
  }
}
