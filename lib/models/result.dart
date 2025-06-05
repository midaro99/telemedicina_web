// lib/models/result.dart
class Result {
  final String id;               // Nuevo: identificador único
  final String diagnostico;      // Nuevo: diagnóstico (ejemplo: "alto", "bajo", "negativo")
  final List<String> genotipos;  // Nuevo: lista de genotipos detectados
  final String filename;
  final DateTime date;
  final String url;

  Result({
    required this.id,
    required this.diagnostico,
    required this.genotipos,
    required this.filename,
    required this.date,
    required this.url,
  });

  /// Crea un Result a partir del JSON que devuelve tu API
  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json['id'] as String,
      diagnostico: json['diagnostico'] as String,
      genotipos: (json['genotipos'] as List<dynamic>).map((e) => e as String).toList(),
      filename: json['filename'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      url: json['url'] as String? ?? '',
    );
  }

  /// Serializa de vuelta a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'diagnostico': diagnostico,
        'genotipos': genotipos,
        'filename': filename,
        'date': date.toIso8601String(),
        'url': url,
      };
}
