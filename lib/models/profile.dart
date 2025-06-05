// lib/models/profile.dart

class Profile {
  //final String publicId;
  final String nombre;
  final String username;
  final String role;   // ADMIN o DOCTOR

  Profile({
    //required this.publicId,
    required this.nombre,
    required this.username,
    required this.role,
  });
}
