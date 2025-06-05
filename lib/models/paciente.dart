// lib/models/paciente.dart
class Paciente {
  final String publicId;
  final String nombre;
  // añade otros campos que te interesen

  Paciente({required this.publicId, required this.nombre});

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      publicId: json['publicId'] as String,
      nombre:   json['nombre']   as String,
    );
  }
}
