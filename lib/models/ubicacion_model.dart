class Ubicacion {
  final String nombre;
  final String direccion;
  final String telefono;
  final String horarioAtencion;
  final String sitioWeb;
  final double latitud;
  final double longitud;

  Ubicacion({
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.horarioAtencion,
    required this.sitioWeb,
    required this.latitud,
    required this.longitud,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) => Ubicacion(
        nombre: json['nombre'],
        direccion: json['direccion'],
        telefono: json['telefono'],
        horarioAtencion: json['horario'],
        sitioWeb: json['sitioWeb'],
        latitud: json['latitud'],
        longitud: json['longitud'],
      );
}
