import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
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
      ubicaciones = await UbicacionService.obtenerPorEstablecimiento(
        widget.tipo,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _crearUbicacion() async {
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final horarioCtrl = TextEditingController();
    final sitioWebCtrl = TextEditingController();
    final latitudCtrl = TextEditingController();
    final longitudCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final creado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Agregar Nueva Ubicación'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: direccionCtrl,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: telefonoCtrl,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    TextFormField(
                      controller: horarioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario de Atención',
                      ),
                    ),
                    TextFormField(
                      controller: sitioWebCtrl,
                      decoration: const InputDecoration(labelText: 'Sitio Web'),
                    ),
                    TextFormField(
                      controller: latitudCtrl,
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              double.tryParse(v!) == null
                                  ? 'Número inválido'
                                  : null,
                    ),
                    TextFormField(
                      controller: longitudCtrl,
                      decoration: const InputDecoration(labelText: 'Longitud'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              double.tryParse(v!) == null
                                  ? 'Número inválido'
                                  : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await UbicacionService.crearUbicacion(
                        Ubicacion(
                          publicId: '', // Se generará en backend
                          nombre: nombreCtrl.text,
                          direccion: direccionCtrl.text,
                          telefono: telefonoCtrl.text,
                          horarioAtencion: horarioCtrl.text,
                          sitioWeb: sitioWebCtrl.text,
                          latitud: double.parse(latitudCtrl.text),
                          longitud: double.parse(longitudCtrl.text),
                          establecimiento: widget.tipo,
                        ),
                        widget.tipo,
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      Navigator.pop(context, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );

    if (creado == true) {
      await _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ubicación creada correctamente.")),
      );
    }
  }

  Future<void> _confirmarYEliminarUbicacion(Ubicacion u) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  Future<void> _editarUbicacion(Ubicacion ubicacion) async {
    final nombreCtrl = TextEditingController(text: ubicacion.nombre);
    final direccionCtrl = TextEditingController(text: ubicacion.direccion);
    final telefonoCtrl = TextEditingController(text: ubicacion.telefono);
    final horarioCtrl = TextEditingController(text: ubicacion.horarioAtencion);
    final sitioWebCtrl = TextEditingController(text: ubicacion.sitioWeb);
    final latitudCtrl = TextEditingController(
      text: ubicacion.latitud.toString(),
    );
    final longitudCtrl = TextEditingController(
      text: ubicacion.longitud.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final actualizado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar Ubicación'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: direccionCtrl,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: telefonoCtrl,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    TextFormField(
                      controller: horarioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario de Atención',
                      ),
                    ),
                    TextFormField(
                      controller: sitioWebCtrl,
                      decoration: const InputDecoration(labelText: 'Sitio Web'),
                    ),
                    TextFormField(
                      controller: latitudCtrl,
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              double.tryParse(v!) == null
                                  ? 'Número inválido'
                                  : null,
                    ),
                    TextFormField(
                      controller: longitudCtrl,
                      decoration: const InputDecoration(labelText: 'Longitud'),
                      keyboardType: TextInputType.number,
                      validator:
                          (v) =>
                              double.tryParse(v!) == null
                                  ? 'Número inválido'
                                  : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await UbicacionService.actualizarUbicacion(
                        ubicacion.publicId,
                        Ubicacion(
                          publicId: ubicacion.publicId,
                          nombre: nombreCtrl.text,
                          direccion: direccionCtrl.text,
                          telefono: telefonoCtrl.text,
                          horarioAtencion: horarioCtrl.text,
                          sitioWeb: sitioWebCtrl.text,
                          latitud: double.parse(latitudCtrl.text),
                          longitud: double.parse(longitudCtrl.text),
                          establecimiento:
                              widget.tipo, // directamente desde la pestaña
                        ),
                        widget.tipo,
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      Navigator.pop(context, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );

    if (actualizado == true) {
      await _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ubicación actualizada correctamente.")),
      );
    }
  }

  Future<void> _subirCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter(
        eol: '\n',
      ).convert(content, shouldParseNumbers: false);

      if (rows.isEmpty || rows.first.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Archivo inválido o columnas incompletas"),
          ),
        );
        return;
      }

      final header =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final requiredHeaders = [
        'nombre',
        'direccion',
        'telefono',
        'horario',
        'sitio_web',
        'latitud',
        'longitud',
      ];

      if (!ListEquality().equals(header, requiredHeaders)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Encabezados inválidos. Verifica el CSV base."),
          ),
        );
        return;
      }

      final ubicacionesValidas = <Ubicacion>[];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        try {
          final nombre = row[0].toString().trim();
          final direccion = row[1].toString().trim();
          final telefono = row[2].toString().trim();
          final horario = row[3].toString().trim();
          final sitioWeb = row[4].toString().trim();
          final latitud = double.parse(row[5].toString());
          final longitud = double.parse(row[6].toString());

          if (nombre.isEmpty || direccion.isEmpty) continue;

          ubicacionesValidas.add(
            Ubicacion(
              publicId: '',
              nombre: nombre,
              direccion: direccion,
              telefono: telefono,
              horarioAtencion: horario,
              sitioWeb: sitioWeb,
              latitud: latitud,
              longitud: longitud,
              establecimiento: widget.tipo,
            ),
          );
        } catch (_) {
          // Ignora filas con errores
          continue;
        }
      }

      if (ubicacionesValidas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se encontraron registros válidos")),
        );
        return;
      }

      try {
        final resultado = await UbicacionService.crearUbicacionesLote(
          ubicacionesValidas,
        );
        await _cargarDatos();

        final List<dynamic> creadas = resultado['creadas'] ?? [];
        final List<dynamic> rechazadas = resultado['rechazadas'] ?? [];

        final StringBuffer mensajeBuffer = StringBuffer(
          "Se cargaron ${creadas.length} ubicaciones correctamente.",
        );

        if (rechazadas.isNotEmpty) {
          mensajeBuffer.writeln(
            "\n\nNo se cargaron ${rechazadas.length} ubicaciones por estar cerca de una ya registrada:",
          );
          for (final r in rechazadas) {
            mensajeBuffer.writeln("• ${r['nombre']} (${r['direccion']})");
          }
        }
        final String mensaje = mensajeBuffer.toString();
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Resultado de carga CSV'),
                content: SingleChildScrollView(child: Text(mensaje)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar CSV: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildBotones() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _crearUbicacion(),
          icon: const Icon(Icons.add),
          label: const Text("Agregar nueva"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: const Color(0xFFF2F2F2), // Gris claro
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _subirCSV(),
          icon: const Icon(Icons.upload_file),
          label: const Text("Subir CSV"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: const Color(0xFFF2F2F2),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
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
                onPressed: () => _editarUbicacion(u),
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
        child: Text(text, softWrap: true, overflow: TextOverflow.visible),
      ),
    );
  }
}
