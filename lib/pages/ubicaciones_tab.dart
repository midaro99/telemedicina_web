import 'package:flutter/material.dart';
import 'package:telemedicina_web/models/ubicacion_model.dart';
import 'package:telemedicina_web/services/ubicacion_service.dart';

class UbicacionesTab extends StatefulWidget {
  final String tipo;
  const UbicacionesTab({super.key, required this.tipo});

  @override
  State<UbicacionesTab> createState() => _UbicacionesTabState();
}

class _UbicacionesTabState extends State<UbicacionesTab> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<Ubicacion> ubicaciones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);
    ubicaciones = await UbicacionService.obtenerPorTipo(widget.tipo);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildBotones(),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 1200),
                      child: DataTable(
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Dirección')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Horario de Atención')),
                          DataColumn(label: Text('Sitio Web')),
                          DataColumn(label: Text('Latitud')),
                          DataColumn(label: Text('Longitud')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows:
                            ubicaciones.map((u) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(u.nombre)),
                                  DataCell(Text(u.direccion)),
                                  DataCell(Text(u.telefono)),
                                  DataCell(Text(u.horarioAtencion)),
                                  DataCell(Text(u.sitioWeb)),
                                  DataCell(Text('${u.latitud}')),
                                  DataCell(Text('${u.longitud}')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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

  Widget _buildBotones() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Dialogo para nueva ubicación
          },
          icon: const Icon(Icons.add),
          label: const Text("Agregar nueva"),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Subir CSV
          },
          icon: const Icon(Icons.upload_file),
          label: const Text("Subir CSV"),
        ),
      ],
    );
  }
}
