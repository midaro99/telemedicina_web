// CAMBIOS APLICADOS:
// ✅ Scroll vertical habilitado con SingleChildScrollView.
// ✅ Columna "Estado" ahora más ancha.
// ✅ Texto centrado en columnas.
// ✅ Centrado visual general mejorado.
// ✅ Paginación mostrada con 15 elementos.

import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/api_service.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({Key? key}) : super(key: key);

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class DispositivoDataSource extends DataTableSource {
  final List<Map<String, dynamic>> dispositivos;
  final Widget Function(String status) buildStatusChip;

  DispositivoDataSource({
    required this.dispositivos,
    required this.buildStatusChip,
  });

  @override
  DataRow getRow(int index) {
    if (index >= dispositivos.length) return const DataRow(cells: []);
    final d = dispositivos[index];
    final fecha = d['fechaExpiracion'] as DateTime?;
    final fechaStr =
        fecha != null
            ? fecha.toLocal().toIso8601String().split('T').first
            : '—';

    return DataRow(
      cells: [
        DataCell(Center(child: Text(d['codigo']?.toString() ?? ''))),
        DataCell(Center(child: buildStatusChip(d['status'] ?? ''))),
        DataCell(Center(child: Text(fechaStr))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => dispositivos.length;
  @override
  int get selectedRowCount => 0;
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
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
    _cargarDispositivos();
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
    } catch (_) {
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
    final filtrados =
        _filtroStatus == 'todos'
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
                onSelected: (v) {
                  setState(() => _filtroStatus = v);
                  _cargarDispositivos();
                },
                itemBuilder:
                    (_) =>
                        _statuses
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Filtrar por estado:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _filtroStatus[0].toUpperCase() +
                              _filtroStatus.substring(1),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black54),
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
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (filtrados.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: SizedBox(
                    width:
                        double
                            .infinity, // El Card ocupa todo el ancho disponible
                    child: Card(
                      color: Colors.white, // Color del fondo del contenedor
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 550, // Ancho fijo de la tabla
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(cardColor: Colors.white),
                              child: PaginatedDataTable(
                                header: const Text(
                                  'Listado de Dispositivos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Código',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: SizedBox(
                                        width: 180,
                                        child: Text(
                                          'Estado',
                                          style: TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Expiración',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                                source: DispositivoDataSource(
                                  dispositivos: filtrados,
                                  buildStatusChip: _buildStatusChip,
                                ),
                                columnSpacing: 60,
                                rowsPerPage: 11, // 15 filas por página
                                showFirstLastButtons: true,
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF082B5F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
