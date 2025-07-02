class Ubicacion {
  final String publicId;
  final String nombre;
  final String direccion;
  final String telefono;
  final String horarioAtencion;
  final String sitioWeb;
  final double latitud;
  final double longitud;
  final String establecimiento;

  Ubicacion({
    required this.publicId,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.horarioAtencion,
    required this.sitioWeb,
    required this.latitud,
    required this.longitud,
    required this.establecimiento,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) => Ubicacion(
        publicId: json['publicId'],
        nombre: json['nombre'],
        direccion: json['direccion'],
        telefono: json['telefono'],
        horarioAtencion: json['horario'],
        sitioWeb: json['sitioWeb'],
        latitud: json['latitud'],
        longitud: json['longitud'],
        establecimiento: json['establecimiento'],
      );
}
