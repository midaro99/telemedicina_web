import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telemedicina_web/models/ubicacion_model.dart';
import 'package:telemedicina_web/config/env.dart';

class UbicacionService {
  static final String baseUrl = '${AppConfig.baseUrl}/api/ubicaciones';

  static Future<List<Ubicacion>> obtenerPorEstablecimiento(String tipo) async {
    final response = await http.get(
      Uri.parse('$baseUrl?establecimiento=$tipo'),
      headers: {'Accept': 'application/json; charset=utf-8'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Ubicacion.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar ubicaciones');
    }
  }

  static Future<void> crearUbicacion(
    Ubicacion ubicacion,
    String establecimiento,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': ubicacion.nombre,
        'direccion': ubicacion.direccion,
        'telefono': ubicacion.telefono,
        'horario': ubicacion.horarioAtencion,
        'sitioWeb': ubicacion.sitioWeb,
        'latitud': ubicacion.latitud,
        'longitud': ubicacion.longitud,
        'establecimiento': establecimiento,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final decoded = utf8.decode(response.bodyBytes); 
        final error = jsonDecode(decoded);
        throw Exception(error['mensaje'] ?? 'Error desconocido');
      } catch (_) {
        throw Exception('Ya existe una ubicación ahí mismo o cercana (10m) en ese punto de coordenadas.');
      }
    }
  }

  static Future<void> eliminarUbicacion(String publicId) async {
    final response = await http.delete(Uri.parse('$baseUrl/$publicId'));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return; // éxito
    } else {
      throw Exception('Error al eliminar: ${response.body}');
    }
  }

  static Future<void> actualizarUbicacion(
    String publicId,
    Ubicacion ubicacion,
    String establecimiento,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$publicId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': ubicacion.nombre,
        'direccion': ubicacion.direccion,
        'telefono': ubicacion.telefono,
        'horario': ubicacion.horarioAtencion,
        'sitioWeb': ubicacion.sitioWeb,
        'latitud': ubicacion.latitud,
        'longitud': ubicacion.longitud,
        'establecimiento': establecimiento, // o el enum adecuado
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar');
    }
  }

  static Future<Map<String, dynamic>> crearUbicacionesLote(List<Ubicacion> lista) async {
    final body = lista.map((u) => {
      'nombre': u.nombre,
      'direccion': u.direccion,
      'telefono': u.telefono,
      'horario': u.horarioAtencion,
      'sitioWeb': u.sitioWeb,
      'latitud': u.latitud,
      'longitud': u.longitud,
      'establecimiento': u.establecimiento,
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/lote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al cargar ubicaciones en lote: ${utf8.decode(response.bodyBytes)}');
    }
  }

}