// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = AuthService();
    final ok = await auth.login(
      _userCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      setState(() => _error = 'Usuario o contraseña inválidos');
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002856), // azul de fondo
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            constraints: const BoxConstraints(
              minHeight: 480, // altura mínima para dar espacio
            ),
            margin: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF), // blanco puro
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado con logo sobre fondo azul
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF002856),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logoucuencaprincipal.png',
                      height: 60,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // ¡Bienvenido!
                      const Text(
                        '¡Bienvenido!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002856),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Nuevo texto de proyecto
                      const Text(
                        'Proyecto de IA en la promoción de automuestreo para la detección temprana de VPH en la prevención del cáncer de cuello uterino',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF002856),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Campos de usuario/contraseña
                      TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_loading) _doLogin();
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón Ingresar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA51008),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24), // espacio extra abajo
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
