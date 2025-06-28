import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telemedicina_web/models/ubicacion_model.dart';
import 'package:telemedicina_web/config/env.dart';

class UbicacionService {
  static final String baseUrl = '${AppConfig.baseUrl}/api/ubicaciones';

  static Future<List<Ubicacion>> obtenerPorTipo(String tipo) async {
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
}
