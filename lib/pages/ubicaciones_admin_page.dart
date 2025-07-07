import 'package:flutter/material.dart';
import 'ubicaciones_tab.dart';

const Color primaryBlue = Color(0xFF002856);
const Color dangerRed = Color(0xFFA51008);

class UbicacionesAdminPage extends StatelessWidget {
  const UbicacionesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // HEADER SUPERIOR ESTILO UCUENCA
              Container(
                color: primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Botón de regresar
                    Material(
                      color: const Color(0xFFA51008),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'UCUENCA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // TÍTULO Y TABS
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Localización de Servicios Relacionados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const TabBar(
                labelColor: primaryBlue,
                unselectedLabelColor: Colors.black54,
                indicatorColor: primaryBlue,
                tabs: [
                  Tab(text: 'GINECOLOGÍA'),
                  Tab(text: 'EN CASO DE AGRESIÓN'),
                  Tab(text: 'PSICOLOGÍA'),
                ],
              ),

              const Expanded(
                child: TabBarView(
                  children: [
                    UbicacionesTab(tipo: 'CENTRO_SALUD'),
                    UbicacionesTab(tipo: 'CENTRO_PROTECCION'),
                    UbicacionesTab(tipo: 'ATENCION_PSICOLOGICA'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
