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
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    String fmt(DateTime? dt) =>
        dt != null ? dateFormat.format(dt.toLocal()) : '---';

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
    //_cargarDispositivos();
    _loadError = null;
  }

  Future<void> _cargarDispositivos() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final dispositivos =
          await ApiService()
              .obtenerTodosDispositivos(); // Usaremos el endpoint real
      //Mandamos a mostrar a través del debugger
      debugPrint('Dispositivos cargados: ${dispositivos.length}');
      setState(() {
        _dispositivos = dispositivos;
      });
    } catch (e) {
      setState(() => _loadError = 'Error al cargar dispositivos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarDispositivosPorFechas(
    DateTime desde,
    DateTime hasta,
  ) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final formato = DateFormat('yyyy-MM-dd');

    try {
      final dispositivos = await ApiService().obtenerDispositivosPorFecha(
        desde: formato.format(desde),
        hasta: formato.format(hasta),
      );

      setState(() {
        _dispositivos = dispositivos;
      });
    } catch (e) {
      setState(() => _loadError = 'Error al filtrar por fechas');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _descargarReporte() {
    // Por ahora solo muestra un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de descarga en desarrollo')),
    );
  }

  Widget _buildStatusChip(String status) {
    status = status.toLowerCase();
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

  Widget _buildOpcionesIniciales() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Wrap(
        spacing: 18,
        runSpacing: 28,
        children: [
          ElevatedButton.icon(
            onPressed: _cargarDispositivos,
            icon: const Icon(Icons.list),
            label: const Text('Mostrar todos los dispositivos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002856),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final rango = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024, 1, 1),
                lastDate: DateTime.now(),
              );

              if (rango != null) {
                await _cargarDispositivosPorFechas(rango.start, rango.end);
                setState(() {
                  _rangoFechas = rango;
                });
              }
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Buscar por fechas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002856),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _descargarReporte,
            icon: const Icon(Icons.download),
            label: const Text('Descargar Reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            ),
          ),
        ],
      ),
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
          // LO QUE SIEMPRE SE MUESTRA
          _buildOpcionesIniciales(),
          const SizedBox(height: 16),
          // ── FILTRO POR ESTADO SOLO SI HAY DATOS ──
          if (_dispositivos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      vertical: 4,
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
                        const SizedBox(width: 18, height: 12),
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
              padding: const EdgeInsets.all(10.0),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 0,
                  ),
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
                                        width: 50,
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
                                columnSpacing: 30,
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
