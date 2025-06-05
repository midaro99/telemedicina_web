// lib/pages/resultados_vph_page.dart

import 'package:flutter/material.dart';
import 'package:telemedicina_web/services/api_service.dart';
import 'package:telemedicina_web/pages/search_page.dart';

class ResultadosVphPage extends StatefulWidget {
  const ResultadosVphPage({Key? key}) : super(key: key);

  @override
  State<ResultadosVphPage> createState() => _ResultadosVphPageState();
}

class _ResultadosVphPageState extends State<ResultadosVphPage> {
  final ScrollController _verticalController = ScrollController();

  bool _loading = true;
  String? _loadError;
  bool _isAtBottom = false;

  List<Map<String, dynamic>> _resultados = [];
  String _filtro = 'todos';
  final List<String> _filtros = ['todos', 'alto', 'bajo', 'negativo'];

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_scrollListener);
    _cargarResultados();
  }

  @override
  void dispose() {
    _verticalController
      ..removeListener(_scrollListener)
      ..dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_verticalController.hasClients) return;
    final atBottom = _verticalController.offset >=
        _verticalController.position.maxScrollExtent;
    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  Future<void> _cargarResultados() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final datos = await ApiService().getResultadosVph();
      setState(() => _resultados = datos);
    } catch (e) {
      setState(() => _loadError = 'Error al cargar resultados');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _textoDiagnostico(String valor) {
    switch (valor.toLowerCase()) {
      case 'alto':
        return '🟥 Positivo riesgo intermedio/alto';
      case 'bajo':
        return '🟨 Positivo bajo riesgo';
      case 'negativo':
        return '✅ Negativo';
      default:
        return valor;
    }
  }

  /// Vacía los campos en el backend y navega a SearchPage para re-crear el resultado
  Future<void> _vaciarYCrear(String codigo) async {
    try {
      await ApiService().clearExamenVphFields(codigo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos vaciados, creando nuevo...')),
      );
      await _cargarResultados(); // ← Esto recarga los datos y actualiza la tabla
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchPage(initialCode: codigo),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al vaciar campos: $e')),
      );
    }
  }

  /// Muestra confirmación y, si acepta, vacía los campos en el backend
  Future<void> _confirmarYVaciar(String codigo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar borrado de campos'),
        content: const Text(
          'Se eliminarán solo los campos de contenido, fecha, nombre, tamaño, tipo y diagnóstico. ¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await ApiService().clearExamenVphFields(codigo);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campos vaciados correctamente')),
        );
        await _cargarResultados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al vaciar campos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtro == 'todos'
        ? _resultados
        : _resultados
            .where((r) => (r['diagnostico'] as String?)?.toLowerCase() == _filtro)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002856),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
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
          children: [
            Image.asset('assets/images/logoucuencaprincipal.png', height: 32),
            const SizedBox(width: 8),
            const Text('Resultados VPH', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        actions: [
          // Refrescar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: const Color(0xFFA51008),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _cargarResultados,
              ),
            ),
          ),
          // Crear
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              color: const Color(0xFFA51008),
              shape: const StadiumBorder(),
              child: TextButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Crear', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  );
                },
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
              child: Text(_loadError!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          // Filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: PopupMenuButton<String>(
                initialValue: _filtro,
                color: Colors.white,
                onSelected: (v) => setState(() => _filtro = v),
                itemBuilder: (_) => _filtros
                    .map((s) => PopupMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('Filtrar por estado:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_filtro[0].toUpperCase() + _filtro.substring(1), style: const TextStyle(color: Colors.black87))),
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
              padding: const EdgeInsets.all(16),
              child: Text('No hay resultados para el filtro seleccionado.', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
            ),
          if (filtrados.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Scrollbar(
                   	controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((_) => const Color(0xFF002856)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          dataTextStyle: const TextStyle(color: Colors.black87),
                          dataRowHeight: 56,
                          columns: const [
                            DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Código'))),
                            DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Diagnóstico'))),
                            DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Genotipos'))),
                            DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Acciones'))),
                          ],
                          rows: filtrados.map((r) {
                           final diagnostico = r['diagnostico'] as String?;
                          final genos = (diagnostico != null && diagnostico.trim().isNotEmpty)
                              ? ((r['genotipos'] as List<String>?)?.join(', ') ?? '')
                              : '';
                            final codigo = r['codigo'] as String? ?? '';
                            return DataRow(cells: [
                              DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(codigo))),
                              DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(_textoDiagnostico(r['diagnostico'] as String? ?? '')))),
                              DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(genos))),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: diagnostico != null && diagnostico.trim().isNotEmpty
                                  ? const Color(0xFF002856) // Azul oscuro para habilitado
                                  : Colors.grey.shade400,    // Gris para deshabilitado
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Vaciar y editar',
                              onPressed: (diagnostico != null && diagnostico.trim().isNotEmpty)
                                  ? () async {
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Confirmar edición'),
                                          content: const Text('¿Deseas vaciar los campos y editar este resultado?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
                                          ],
                                        ),
                                      );
                                      if (confirmar == true) {
                                        _vaciarYCrear(codigo);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: diagnostico != null && diagnostico.trim().isNotEmpty
                                  ? const Color(0xFF002856)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              tooltip: 'Vaciar campos',
                              onPressed: (diagnostico != null && diagnostico.trim().isNotEmpty)
                                  ? () => _confirmarYVaciar(codigo)
                                  : null,
                            ),
                          ),

                                ],
                              )),
                            ]);
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
      floatingActionButton: _isAtBottom
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFA51008),
              child: const Icon(Icons.arrow_upward, color: Colors.white),
              onPressed: () => _verticalController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
            )
          : null,
    );
  }
}
