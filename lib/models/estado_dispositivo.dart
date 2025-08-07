// lib/models/estado_dispositivo.dart
class EstadoDispositivo {
  final String codigo;
  final String estado;
  final DateTime? fechaRegistro;
  final DateTime? fechaExamen;
  final DateTime? fechaResultado;

  EstadoDispositivo({
    required this.codigo,
    required this.estado,
    this.fechaRegistro,
    this.fechaExamen,
    this.fechaResultado,
  });
}
