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
    try {
      ubicaciones = await UbicacionService.obtenerPorEstablecimiento(widget.tipo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmarYEliminarUbicacion(Ubicacion u) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Deseas eliminar '${u.nombre}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        setState(() => isLoading = true);
        await UbicacionService.eliminarUbicacion(u.publicId);
        await _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ubicación eliminada correctamente.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: ${e.toString()}")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildBotones() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Diálogo para nueva ubicación
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
                        columnSpacing: 12,
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
                        rows: ubicaciones.map((u) => _buildDataRow(u)).toList(),
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

  DataRow _buildDataRow(Ubicacion u) {
    return DataRow(
      cells: [
        _buildWrappedCell(u.nombre),
        _buildWrappedCell(u.direccion),
        _buildWrappedCell(u.telefono, maxWidth: 110),
        _buildWrappedCell(u.horarioAtencion, maxWidth: 250),
        _buildWrappedCell(u.sitioWeb, maxWidth: 270),
        DataCell(Text('${u.latitud}')),
        DataCell(Text('${u.longitud}')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Abrir formulario de edición
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmarYEliminarUbicacion(u),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataCell _buildWrappedCell(String text, {double maxWidth = 270}) {
    return DataCell(
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          text,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
