// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telemedicina_web/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  Profile? _profile;
  
  final String _baseUrl = 'https://clias.ucuenca.edu.ec/api'; //servidor
  //final String _baseUrl = 'http://localhost:8080/api';

  // Iniciar sesión 
  Future<bool> login(String usuario, String contrasena) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      // Guardamos el perfil del usuario 
      _profile = Profile(
        nombre: data['nombre'] as String,
        username: data['usuario'] as String,
        role: data['role'] as String,
      );

      return true; // Inicio de sesión exitoso
    } else {
      return false; // Fallamos el inicio de sesión si el código de estado no es 200
    }
  }

  // Obtener el perfil del usuario
  Future<Profile> fetchProfile() async {
    if (_profile == null) throw Exception('Perfil no cargado');
    return _profile!;
  }

  // Logout, eliminar el perfil
  void logout() async {
    _profile = null;  // Eliminar el perfil cargado
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');  
  }
}