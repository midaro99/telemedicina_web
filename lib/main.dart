import 'package:flutter/material.dart';

import 'package:telemedicina_web/pages/login_page.dart';
import 'package:telemedicina_web/pages/home_page.dart';
import 'package:telemedicina_web/pages/users_page.dart';
import 'package:telemedicina_web/pages/device_status_page.dart';  
import 'package:telemedicina_web/pages/search_page.dart';
import 'package:telemedicina_web/pages/codes_page.dart'; 
import 'package:telemedicina_web/pages/resultados_vph_page.dart';
import 'package:telemedicina_web/pages/ubicaciones_admin_page.dart';

void main() {
  runApp(const TelemedicinaWeb());
}

class TelemedicinaWeb extends StatelessWidget {
  const TelemedicinaWeb({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telemedicina Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'ArialNarrow',  // ← aquí pones el family que declaraste
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/admin/users':   (_) => const UsersPage(),
        '/admin/results': (_) => const DeviceStatusPage(),  
        '/admin/codes':   (_) => const QRGeneratorPage(), 
        '/doctor/search': (_) => const SearchPage(),
        '/doctor/resultados': (_) => const ResultadosVphPage(),
        '/admin/ubicaciones': (_) => const UbicacionesAdminPage()
      },
    );
  }
}
