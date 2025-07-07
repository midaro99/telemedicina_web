import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/auth_service.dart';
import 'package:telemedicina_web/models/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = AuthService();
  bool _loading = true;
  String? _error;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prof = await _auth.fetchProfile();
      setState(() {
        _profile = prof;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar perfil';
        _loading = false;
      });
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final prof = _profile!;
    final saludo = '¡Bienvenido/a ${prof.nombre}!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── HEADER ──────────────────────────────────────────────────────────
            Container(
              color: const Color(0xFF002856),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logoucuencaprincipal.png',
                    height: 40,
                  ),
                  const Spacer(),
                  Text(
                    saludo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),

            // ─── CUERPO ──────────────────────────────────────────────────────────
            Expanded(
              child: Center(child: _buildMenu()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final role = _profile?.role ?? '';

    // 🔴 Estilo de botón con fondo rojo (#A51008)
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFA51008),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    if (role == 'ADMIN') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/admin/users'),
            child: const Text('Gestionar Usuarios'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/admin/results'),
            child: const Text('Status de Dispositivos'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/admin/codes'),
            child: const Text('Generación de Códigos'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/admin/ubicaciones'),
            child: const Text('Localización de Servicios Relacionados'),
          ),
        ],
      );
    } else if (role == 'DOCTOR') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/doctor/search'),
            child: const Text('Ingresar Resultado'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.pushNamed(context, '/doctor/resultados'),
            child: const Text('Ver Resultados'),
          ),
        ],
      );
    } else {
      return const Text(
        'Rol desconocido',
        style: TextStyle(color: Colors.grey),
      );
    }
  }
}
