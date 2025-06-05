// lib/pages/device_status_page.dart

import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/api_service.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({Key? key}) : super(key: key);

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  final ScrollController _verticalController = ScrollController();
  bool _isAtBottom = false;
  bool _loading = true;
  String? _loadError;

  List<Map<String, dynamic>> _dispositivos = [];
  String _filtroStatus = 'todos';
  final List<String> _statuses = [
    'todos',
    'generado',
    'registrado',
    'en proceso',
    'resultado listo',
  ];

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(() {
      final atBottom = _verticalController.offset >=
          _verticalController.position.maxScrollExtent;
      if (atBottom != _isAtBottom) {
        setState(() => _isAtBottom = atBottom);
      }
    });
    _cargarDispositivos();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _cargarDispositivos() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final codigos = await ApiService().obtenerCodigosQR(
        status: _filtroStatus == 'todos' ? null : _filtroStatus,
      );
      setState(() => _dispositivos = codigos);
    } catch (e) {
      setState(() => _loadError = 'Error al cargar dispositivos');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'generado':
        color = Colors.amber;
        icon = Icons.circle;
        break;
      case 'registrado':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'en proceso':
        color = Colors.orange;
        icon = Icons.autorenew;
        break;
      case 'resultado listo':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtroStatus == 'todos'
        ? _dispositivos
        : _dispositivos.where((d) => d['status'] == _filtroStatus).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002856),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: const Color(0xFFA51008),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // Título con logo a la izquierda y texto 'Estado de Dispositivos' a la derecha
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/images/logoucuencaprincipal.png', height: 32),
            const Text(
              'Estado de Dispositivos',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Material(
              color: const Color(0xFFA51008),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _cargarDispositivos,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 3)
          else if (_loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: Text(
                _loadError!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          // Filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              child: PopupMenuButton<String>(
                initialValue: _filtroStatus,
                color: Colors.white,
                onSelected: (v) {
                  setState(() => _filtroStatus = v);
                  _cargarDispositivos();
                },
                itemBuilder: (_) => _statuses
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                          ),
                        ))
                    .toList(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Filtrar por estado:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _filtroStatus[0].toUpperCase() +
                              _filtroStatus.substring(1),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_loading && filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay dispositivos para el filtro seleccionado.',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
            ),
          if (filtrados.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateColor.resolveWith((_) => const Color(0xFF002856)),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        dataTextStyle:
                            const TextStyle(color: Colors.black87),
                        dataRowHeight: 56,
                        columns: const [
                          DataColumn(label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Código'),
                          )),
                          DataColumn(label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Estado'),
                          )),
                          DataColumn(label: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('Expiración'),
                          )),
                        ],
                        rows: filtrados.map((d) {
                          final fecha = d['fechaExpiracion'] as DateTime?;
                          final fechaStr = fecha != null
                              ? fecha
                                  .toLocal()
                                  .toIso8601String()
                                  .split('T')
                                  .first
                              : '—';
                          return DataRow(cells: [
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(d['codigo']),
                            )),
                            DataCell(_buildStatusChip(d['status'])),
                            DataCell(Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(fechaStr),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAtBottom
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFA51008),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () {
                _verticalController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            )
          : null,
    );
  }
}
