// lib/models/user.dart

class User {
  final String publicId;
  final String usuario;
  final String nombre;
  final String role;  // ADMIN o DOCTOR
  final String correo;
  final String? especializacion;
  final String? sexo;      
  final String? nRegistro;  // nuevo campo (n_registro)

  User({
    required this.publicId,
    required this.usuario,
    required this.nombre,
    required this.role,
    required this.correo,
    this.especializacion,
    this.sexo,
    this.nRegistro,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        publicId: json['publicId'] as String,
        usuario: json['usuario'] as String,
        nombre: json['nombre'] as String,
        role: json['role'] as String,
        correo: json['correo'] as String? ?? '',
        especializacion: json['especializacion'] as String?,
        sexo: json['sexo'] as String?,                // lectura sexo
        nRegistro: json['n_registro'] as String?,     // lectura n_registro
      );

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'usuario': usuario,
      'nombre': nombre,
      'role': role,
      'correo': correo,
      if (especializacion != null) 'especializacion': especializacion!,
      if (sexo != null) 'sexo': sexo!,
      if (nRegistro != null) 'n_registro': nRegistro!,
    };
  }
}
