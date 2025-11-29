class User {
  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final String? nis;
  final String? nisn;
  final String? telepon;
  final String? kelas;
  final String? alamat;
  final String? jenisKelamin;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.nis,
    this.nisn,
    this.telepon,
    this.kelas,
    this.alamat,
    this.jenisKelamin,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle roles properly - can be array of objects or strings
    List<String> rolesList = [];
    if (json['roles'] != null) {
      final rolesData = json['roles'] as List<dynamic>;
      rolesList = rolesData.map((role) {
        if (role is Map) {
          return role['name']?.toString() ?? '';
        }
        return role.toString();
      }).toList();
    }
    
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: rolesList,
      nis: json['nis'] as String?,
      nisn: json['nisn'] as String?,
      telepon: json['telepon'] as String?,
      kelas: json['kelas'] as String?,
      alamat: json['alamat'] as String?,
      jenisKelamin: json['jenis_kelamin'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles,
      'nis': nis,
      'nisn': nisn,
      'telepon': telepon,
      'kelas': kelas,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
    };
  }
}

