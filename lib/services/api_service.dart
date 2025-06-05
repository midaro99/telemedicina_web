import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:telemedicina_web/models/result.dart';
import 'package:telemedicina_web/models/profile.dart';
import 'package:telemedicina_web/models/paciente.dart';

class ApiService {
  final String _baseUrl = 'https://clias.ucuenca.edu.ec/api'; // servidor
 // final String _baseUrl = 'http://localhost:8080/api';


  Future<List<Result>> getResults(String patientId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/patients/$patientId/results'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Result.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al cargar resultados: ${response.statusCode}');
  }

  Future<void> uploadResult( 
    String patientId,
    List<int> fileBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_baseUrl/patients/$patientId/results');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

    final token = html.window.localStorage['jwt'];
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Error al subir PDF: ${response.statusCode}');
    }
  }

  Future<Profile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Profile(nombre: 'admin', username: 'admin', role: 'ADMIN');
  }

  Future<String> fetchPatientIdFromDevice(String deviceCode) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/dispositivos_registrados/$deviceCode'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['pacienteId'].toString();
    }
    throw Exception('Error al cargar pacienteId: ${resp.statusCode}');
  }

  Future<Paciente> getPaciente(String publicId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/paciente/usuario/$publicId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Error al cargar paciente: ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return Paciente.fromJson(json);
  }
  // Subir resultado en PDF
  Future<void> uploadResultadoMedico({
    required String pacienteId,
    required List<int> fileBytes,
    required String fileName,
    required String dispositivo,
    required String diagnostico,
    required List<String> genotipos,
  }) async {
    
    //final uri = Uri.parse('http://localhost:8080/prueba/medico/subir/$pacienteId');
    final uri = Uri.parse('https://clias.ucuenca.edu.ec/prueba/medico/subir/$pacienteId');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      ))
      ..fields['nombre'] = fileName
      ..fields['dispositivo'] = dispositivo
      ..fields['diagnostico'] = diagnostico
      ..fields['genotipos'] = jsonEncode(genotipos);

    final token = html.window.localStorage['jwt'];
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Error al subir resultado: ${response.statusCode} - $body');
    }
  }

  /// Nuevo método para obtener datos del médico por ID
  Future<Map<String, dynamic>> fetchMedicoById(int id) async {
  final resp = await http.get(
    Uri.parse('$_baseUrl/medicos/$id'),
    headers: {'Content-Type': 'application/json'},
  );
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data;
  }
  throw Exception('Error al obtener médico: ${resp.statusCode}');
}


  /// Método corregido para guardar código QR 
  Future<void> guardarQRConInfo({
    required String codigo,
    required String fechaExpiracion,
  }) async {
    final uri = Uri.parse('$_baseUrl/codigosqr');
    final request = http.MultipartRequest('POST', uri)
      ..fields['codigo'] = codigo
      ..fields['fechaExpiracion'] = fechaExpiracion;

    final token = html.window.localStorage['jwt'];
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = await response.stream.bytesToString();
      throw Exception('Error al guardar código QR: ${response.statusCode} - $body');
    }
  }

  /// Listar códigos QR con su status derivado
  Future<List<Map<String, dynamic>>> obtenerCodigosQR({String? status}) async {
    final token = html.window.localStorage['jwt'];

    final uri = Uri.parse(
      '$_baseUrl/codigosqr${(status != null && status != 'todos') ? '?status=$status' : ''}',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        return {
          'codigo': item['codigo'],
          'status': item['status'],
          'fechaExpiracion': DateTime.parse(item['fechaExpiracion']),
        };
      }).toList();
    } else {
      throw Exception('Error al cargar códigos QR: ${response.statusCode}');
    }
  }

  /// Listar resultados
  /// Llama a GET /prueba/admin y mapea la respuesta
  Future<List<Map<String, dynamic>>> getResultadosVph() async {
    final backendBase = _baseUrl.replaceFirst(RegExp(r'/api$'), '');
    final uri = Uri.parse('$backendBase/prueba/admin');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        return {
          'codigo': item['dispositivo'],
          'diagnostico': item['diagnostico'],
          'genotipos': List<String>.from(item['genotipos'] ?? []),
        };
      }).toList();
    } else {
      throw Exception('Error al cargar resultados VPH: ${response.statusCode}');
    }
  }

  /// Consulta sólo el nombre del paciente a partir del código de dispositivo
  Future<String> fetchPatientNameFromExamenVph(String dispositivoCodigo) async {
    //final uri = Uri.parse('http://localhost:8080/prueba/medico/nombre/$dispositivoCodigo');
    final uri = Uri.parse('https://clias.ucuenca.edu.ec/prueba/medico/nombre/$dispositivoCodigo');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return resp.body;
    }
    throw Exception('Error al obtener nombre del paciente: ${resp.statusCode}');
  }

  /// Borra SOLO los campos de contenido, fecha_resultado, nombre, tamano, tipo y diagnostico
  Future<void> clearExamenVphFields(String codigo) async {
    //final uri = Uri.parse('http://localhost:8080/prueba/medico/clear-fields/$codigo');
    final uri = Uri.parse('https://clias.ucuenca.edu.ec/prueba/medico/clear-fields/$codigo');
    final token = html.window.localStorage['jwt'];
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.patch(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Error al vaciar campos: ${response.statusCode} - ${response.body}',
      );
    }
  }  
  /// Devuelve la lista de prefijos de dispositivo desde el backend.
  Future<List<String>> fetchDevicePrefixes() async {
    //final uri = Uri.parse('http://localhost:8080//prueba/medico/prefixes');
    final uri = Uri.parse('https://clias.ucuenca.edu.ec/prueba/medico/prefixes');
    final token = html.window.localStorage['jwt'];
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      // Esperamos un JSON como ["010151-", "020202-", ...]
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((e) => e.toString()).toList();
    } else {
      throw Exception(
        'Error al cargar prefijos (${response.statusCode}): ${response.body}'
      );
    }
  }

}
