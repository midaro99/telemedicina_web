import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telemedicina_web/models/estado_dispositivo.dart';
import 'package:telemedicina_web/services/api_service.dart';

/*
******************************************************
Clase con la que se maneja los estados cambiantes de los dispositivos
*****************************************************
*/
class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({Key? key}) : super(key: key);
  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

/*
******************************************************
Clase controladora que le dice a la tabla cómo renderizar cada fila
*****************************************************
*/
class DispositivoDataSource extends DataTableSource {
  final List<EstadoDispositivo> dispositivos;
  final Widget Function(String status) buildStatusChip;

  DispositivoDataSource({
    required this.dispositivos,
    required this.buildStatusChip,
  });

  @override
  DataRow getRow(int index) {
    final d = dispositivos[index];
    // Formatea cada fecha o muestra '---'
    String fmt(DateTime? dt) =>
        dt != null
            ? dt.toLocal().toIso8601String().replaceFirst('T', ' ')
            : '---';

    return DataRow(
      cells: [
        DataCell(Text(d.codigo)),
        DataCell(buildStatusChip(d.estado)),
        DataCell(Text(fmt(d.fechaRegistro))),
        DataCell(Text(fmt(d.fechaExamen))),
        DataCell(Text(fmt(d.fechaResultado))),
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
  //Variables de Estado
  bool _loading = true;
  String? _loadError;
  List<EstadoDispositivo> _dispositivos = [];
  DateTimeRange? _rangoFechas;
  String _filtroStatus = 'todos';
  // Enums para los posibles estados
  final List<String> _statuses = [
    'todos',
    'generado',
    'registrado',
    'en proceso',
    'resultado listo',
  ];

  //Inicialización: Se llama un avez cuando el componente se monta por primera vez
  @override
  void initState() {
    super.initState();
    _cargarDispositivos();
  }

  // Datos de ejemplo para simular la carga
  final List<EstadoDispositivo> _mockData = [
    EstadoDispositivo(
      codigo: '010151-A001',
      estado: 'registrado',
      fechaRegistro: DateTime.parse('2025-06-19T09:46:55'),
      fechaExamen: DateTime.parse('2025-06-19T10:13:00'),
      fechaResultado: DateTime.parse('2025-06-27T11:19:42'),
    ),
    EstadoDispositivo(
      codigo: '010151-A002',
      estado: 'resultado listo',
      fechaRegistro: DateTime.parse('2025-06-19T10:12:01'),
      fechaExamen: DateTime.parse('2025-06-19T10:39:00'),
      fechaResultado: DateTime.parse('2025-06-27T12:34:35'),
    ),
    // Nuevos casos de prueba:
    EstadoDispositivo(
      codigo: '010151-A003',
      estado: 'generado',
      fechaRegistro: DateTime.parse('2025-06-19T10:45:00'),
      fechaExamen: null,
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010152-B001',
      estado: 'generado',
      fechaRegistro: DateTime.parse('2025-06-20T08:30:15'),
      fechaExamen: DateTime.parse('2025-06-20T09:00:00'),
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010152-B002',
      estado: 'registrado',
      fechaRegistro: DateTime.parse('2025-06-20T09:15:22'),
      fechaExamen: DateTime.parse('2025-06-20T09:45:00'),
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010153-C001',
      estado: 'en proceso',
      fechaRegistro: DateTime.parse('2025-06-21T11:00:00'),
      fechaExamen: DateTime.parse('2025-06-21T11:30:00'),
      fechaResultado: DateTime.parse('2025-06-28T10:00:00'),
    ),
    EstadoDispositivo(
      codigo: '010154-D001',
      estado: 'generado',
      fechaRegistro: DateTime.parse('2025-06-22T14:00:00'),
      fechaExamen: null,
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010155-E001',
      estado: 'en proceso',
      fechaRegistro: DateTime.parse('2025-06-10T07:20:00'),
      fechaExamen: DateTime.parse('2025-06-10T07:50:00'),
      fechaResultado: DateTime.parse('2025-06-18T08:00:00'),
    ),
    EstadoDispositivo(
      codigo: '010156-F001',
      estado: 'en proceso',
      fechaRegistro: DateTime.parse('2025-06-23T15:30:00'),
      fechaExamen: DateTime.parse('2025-06-23T16:00:00'),
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010157-G001',
      estado: 'registrado',
      fechaRegistro: DateTime.parse('2025-06-24T09:00:00'),
      fechaExamen: null,
      fechaResultado: null,
    ),
    EstadoDispositivo(
      codigo: '010158-H001',
      estado: 'verificado',
      fechaRegistro: DateTime.parse('2025-06-25T12:15:00'),
      fechaExamen: DateTime.parse('2025-06-25T12:45:00'),
      fechaResultado: DateTime.parse('2025-07-02T13:30:00'),
    ),
    EstadoDispositivo(
      codigo: '010159-I001',
      estado: 'en revisión',
      fechaRegistro: DateTime.parse('2025-06-26T08:05:00'),
      fechaExamen: DateTime.parse('2025-06-26T08:35:00'),
      fechaResultado: null,
    ),
  ];

  Future<void> _cargarDispositivos() async {
    /*    // Descomentar esta sección para cargar datos reales desde la API
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
    */
    setState(() {
      _dispositivos = _mockData;
      _loading = false;
    });
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
    // 1) Primero filtrar por estado
    var filtrados =
        _filtroStatus == 'todos'
            ? _dispositivos
            : _dispositivos.where((d) => d.estado == _filtroStatus).toList();

    // 2) Filtrar por rango de fechas usando _rangoFechas
    if (_rangoFechas != null) {
      filtrados =
          filtrados.where((d) {
            final dt = d.fechaRegistro;
            if (dt == null) return false;
            // extraer solo la fecha
            final date = DateTime(dt.year, dt.month, dt.day);
            return !date.isBefore(_rangoFechas!.start) &&
                !date.isAfter(_rangoFechas!.end);
          }).toList();
    }
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
          // ── FILTRO POR ESTADO SOLO SI HAY DATOS ──
          if (_dispositivos.isNotEmpty) ...[
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
                    setState(() {
                      _filtroStatus = v;
                    });
                    _cargarDispositivos();
                  },
                  itemBuilder:
                      (_) =>
                          _statuses.map((s) {
                            return PopupMenuItem(
                              value: s,
                              child: Text(s[0].toUpperCase() + s.substring(1)),
                            );
                          }).toList(),
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
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                            width: 1200, // Ancho fijo de la tabla
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
                                        'Fecha de Registro',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Fecha de Examen ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Fecha del Resultado listo',
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
