import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
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
  bool _allDevice = false;
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

  List<EstadoDispositivo> _aplicarFiltros() {
    // 1) por estado
    var lista =
        _filtroStatus == 'todos'
            ? _dispositivos
            : _dispositivos
                .where(
                  (d) =>
                      (d.estado ?? '').toLowerCase().trim() ==
                      _filtroStatus.toLowerCase().trim(),
                )
                .toList();
    if (!_allDevice) {
      // 2) por rango de fechas (inclusive)
      if (_rangoFechas != null) {
        lista =
            lista.where((d) {
              final dt = d.fechaRegistro;
              if (dt == null) return false;
              final date = DateTime(dt.year, dt.month, dt.day);
              return !date.isBefore(_rangoFechas!.start) &&
                  !date.isAfter(_rangoFechas!.end);
            }).toList();
      }
    }

    return lista;
  }

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
      _allDevice = true;
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

  Future<void> _descargarReporte() async {
    // Asegúrate de tener datos cargados
    if (_dispositivos.isEmpty) {
      await _cargarDispositivos();
    }

    // Toma los que están filtrados actualmente (estado y/o fechas)
    final data = _aplicarFiltros();

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para exportar con los filtros actuales'),
        ),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headerStyle = CellStyle(
      backgroundColorHex: '#D9D9D9',
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    final cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

    final headers = [
      'Código',
      'Estado',
      'Fecha de Registro',
      'Fecha de Examen',
      'Fecha de Resultado',
      'Fecha de Entrega en el GAD',
    ];

    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      );
      cell.value = headers[c];
      cell.cellStyle = headerStyle;
    }

    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final r = i + 1;

      List<dynamic> values = [
        d.codigo,
        d.estado,
        d.fechaRegistro != null
            ? fmt.format(d.fechaRegistro!.toLocal())
            : '---',
        d.fechaExamen != null ? fmt.format(d.fechaExamen!.toLocal()) : '---',
        d.fechaResultado != null
            ? fmt.format(d.fechaResultado!.toLocal())
            : '---',
        '',
      ];

      for (int c = 0; c < values.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = values[c];
        cell.cellStyle = cellStyle;
      }
    }

    final columnWidths = [15.0, 20.0, 25.0, 25.0, 25.0, 30.0];
    for (int i = 0; i < columnWidths.length; i++) {
      sheet.setColWidth(i, columnWidths[i]);
    }

    final bytes = Uint8List.fromList(excel.encode()!);
    final fechaActual = DateFormat(
      'yyyy-MM-dd_HH-mm-ss',
    ).format(DateTime.now());

    await FileSaver.instance.saveFile(
      name: 'reporte_dispositivos_$fechaActual',
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reporte descargado (${data.length} registros, filtros: '
          '${_filtroStatus == "todos" ? "todos" : _filtroStatus}'
          '${_rangoFechas != null ? ", rango ${DateFormat("dd/MM/yyyy").format(_rangoFechas!.start)} - ${DateFormat("dd/MM/yyyy").format(_rangoFechas!.end)}" : ""}'
          ')',
        ),
      ),
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
      child: Center(
        child: Wrap(
          spacing: 18,
          runSpacing: 28,
          alignment: WrapAlignment.center, // <- centra los botones
          children: [
            ElevatedButton.icon(
              onPressed: _cargarDispositivos,
              icon: const Icon(Icons.list),
              label: const Text('Mostrar todos los dispositivos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002856),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    DateTime? fechaInicio;
                    DateTime? fechaFin;

                    String format(DateTime d) => DateFormat(
                      'dd MMM y',
                      'es',
                    ).format(d); // ej: 12 ago 2025

                    return StatefulBuilder(
                      builder: (ctx, setStateDialog) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: const Text('Selecciona un rango de fechas'),
                          content: SizedBox(
                            width: 360,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Vista previa del rango elegido
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (fechaInicio != null && fechaFin != null)
                                        ? 'Desde: ${format(fechaInicio!)}   —   Hasta: ${format(fechaFin!)}'
                                        : 'Selecciona un rango (Desde — Hasta)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // DateRangePicker compacto
                                SizedBox(
                                  width: 350,
                                  height: 320,
                                  child: SfDateRangePicker(
                                    view: DateRangePickerView.month,
                                    selectionMode:
                                        DateRangePickerSelectionMode.range,
                                    showNavigationArrow: true,
                                    maxDate:
                                        DateTime.now(), // opcional: no permitir futuro
                                    monthViewSettings:
                                        const DateRangePickerMonthViewSettings(
                                          firstDayOfWeek: 1, // lunes
                                        ),
                                    onSelectionChanged: (args) {
                                      if (args.value is PickerDateRange) {
                                        final r = args.value as PickerDateRange;
                                        setStateDialog(() {
                                          fechaInicio = r.startDate;
                                          // endDate puede venir null hasta que el usuario suelta
                                          fechaFin = r.endDate ?? r.startDate;
                                        });
                                      }
                                      _allDevice = false;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (fechaInicio != null && fechaFin != null) {
                                  await _cargarDispositivosPorFechas(
                                    fechaInicio!,
                                    fechaFin!,
                                  );
                                  setState(() {
                                    _rangoFechas = DateTimeRange(
                                      start: fechaInicio!,
                                      end: fechaFin!,
                                    );
                                  });
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Buscar por fechas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002856),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _descargarReporte,
              icon: const Icon(Icons.download),
              label: const Text('Descargar reporte de los dispositivos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1) Primero filtrar
    final filtrados = _aplicarFiltros();

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
          if (_loadError != null)
            Container(
              alignment: Alignment.center,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                                rowsPerPage: 10, //
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
