// lib/pages/search_page.dart

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui; // para platformViewRegistry

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:telemedicina_web/services/api_service.dart';
import 'dart:convert';

class SearchPage extends StatefulWidget {
  /// Si se proporciona, se usa para prellenar el sufijo y lanzar la búsqueda
  final String? initialCode;
  const SearchPage({Key? key, this.initialCode}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Lista dinámica de prefijos
  List<String> _prefixes = [];
  String? _selectedPrefix;
  bool _loadingPrefixes = true;

  final TextEditingController _ctrl = TextEditingController();

  bool _loadingSearch = false;
  bool _loadingUpload = false;
  String? _error;

  String? _pacienteNombre;
  String? _pacienteId;

  String? _resultadoTipo;
  Uint8List? _pdfGeneradoBytes;
  String? _pdfUrl;

  List<String> _genotiposSeleccionados = [];

  final Map<String, List<String>> _genotipos = {
    'alto': [
      '16',
      '18',
      '31',
      '33',
      '35',
      '39',
      '45',
      '51',
      '52',
      '56',
      '58',
      '59',
      '68',
      '26',
      '53',
      '66',
      '73',
      '82',
    ],
    'bajo': ['6', '11', '42', '43', '44', '81'],
  };

  pw.Font? _loraFont;

  @override
  void initState() {
    super.initState();
    _loadFont();
    _loadPrefixes().then((_) {
      // Si viene initialCode, lo prellenamos y buscamos
      if (widget.initialCode != null && _selectedPrefix != null) {
        final code = widget.initialCode!;
        if (code.startsWith(_selectedPrefix!)) {
          _ctrl.text = code.substring(_selectedPrefix!.length);
          WidgetsBinding.instance.addPostFrameCallback((_) => _searchDevice());
        }
      }
    });
  }

  Future<void> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/Lora-Regular.ttf');
    setState(() {
      _loraFont = pw.Font.ttf(fontData);
    });
  }

  Future<void> _loadPrefixes() async {
    try {
      // Implementa este método en ApiService
      final lista = await ApiService().fetchDevicePrefixes();
      setState(() {
        _prefixes = lista;
        _selectedPrefix = lista.isNotEmpty ? lista.first : null;
        _loadingPrefixes = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar prefijos';
        _loadingPrefixes = false;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    if (_pdfUrl != null) html.Url.revokeObjectUrl(_pdfUrl!);
    super.dispose();
  }

  Future<void> _searchDevice() async {
    final suffix = _ctrl.text.trim();
    if (_selectedPrefix == null || suffix.isEmpty) return;
    final fullCode = '$_selectedPrefix$suffix';

    setState(() {
      _loadingSearch = true;
      _error = null;
      _pacienteNombre = null;
      _pacienteId = null;
      _resultadoTipo = null;
      _pdfGeneradoBytes = null;
      _genotiposSeleccionados = [];
      if (_pdfUrl != null) {
        html.Url.revokeObjectUrl(_pdfUrl!);
        _pdfUrl = null;
      }
    });

    try {
      final nombre = await ApiService().fetchPatientNameFromExamenVph(fullCode);
      final id = await ApiService().fetchPatientIdFromDevice(fullCode);
      setState(() {
        _pacienteNombre = nombre;
        _pacienteId = id;
      });
    } catch (e) {
      setState(() {
        _error = 'No se encontró examen o dispositivo';
      });
    } finally {
      setState(() {
        _loadingSearch = false;
      });
    }
  }

  String _getInterpretacion() {
    if (_resultadoTipo == 'alto') {
      return 'Se detectaron genotipos de VPH de riesgo intermedio y/o alto, los cuales se asocian con una mayor probabilidad de desarrollar lesiones cervicales. Por ello, se recomienda acudir a una consulta con un especialista en ginecología y obstetricia, a fin de evaluar la pertinencia de realizar una colposcopia que permita identificar posibles alteraciones y determinar la necesidad de seguimiento o tratamiento.';
    } else if (_resultadoTipo == 'bajo') {
      return 'Se detectaron genotipos de VPH de bajo riesgo, los cuales raramente se asocian con lesiones precancerosas. Se recomienda seguimiento habitual y la repetición del estudio de VPH en un plazo de 3 a 5 años, según indicación médica.';
    } else {
      return 'No se detectaron genotipos de VPH dentro de los incluidos en la prueba. Se sugiere repetir el estudio en 5 años, de acuerdo con las recomendaciones para el tamizaje rutinario.';
    }
  }

  Future<void> _generarPdf() async {
    if (_pacienteNombre == null ||
        _pacienteId == null ||
        _resultadoTipo == null) {
      _showDialog(
        'Error',
        'Debe buscar y seleccionar un paciente y diagnóstico antes.',
      );
      return;
    }
    if (_loraFont == null) {
      _showDialog(
        'Error',
        'La fuente aún no se ha cargado, por favor intenta de nuevo.',
      );
      return;
    }

    final docData = await ApiService().fetchMedicoById(1);
    final docNombre = docData['nombre'] as String;
    final rawEspecializacion = docData['especializacion'];
    final docEspecializacion =
        rawEspecializacion != null
            ? utf8.decode(latin1.encode(rawEspecializacion))
            : '';

    final docNRegistro = docData['nregistro'] as String? ?? '';

    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String textoDiag;
    if (_resultadoTipo == 'alto') {
      textoDiag = 'Positivo para VPH de intermedio/alto riesgo';
    } else if (_resultadoTipo == 'bajo') {
      textoDiag = 'Positivo para VPH de bajo riesgo';
    } else {
      textoDiag = 'Negativo para VPH';
    }

    final interpretacion = _getInterpretacion();

    final logo1 =
        (await rootBundle.load(
          'assets/images/logoucuenca.png',
        )).buffer.asUint8List();
    final logo2 =
        (await rootBundle.load('assets/images/clias.png')).buffer.asUint8List();
    final logo3 =
        (await rootBundle.load('assets/images/idcr.png')).buffer.asUint8List();
    final logo4 =
        (await rootBundle.load('assets/images/iecs.png')).buffer.asUint8List();
    final firma =
        (await rootBundle.load('assets/images/firma.png')).buffer.asUint8List();

    final pdf = pw.Document();
    final base = pw.TextStyle(font: _loraFont, fontSize: 14);
    final small = pw.TextStyle(font: _loraFont, fontSize: 10);
    final smallBold = pw.TextStyle(
      font: _loraFont,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final interpretStyle = pw.TextStyle(font: _loraFont, fontSize: 12);
    final bold = pw.TextStyle(
      font: _loraFont,
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (c) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Image(pw.MemoryImage(logo1), width: 60),
                        pw.SizedBox(width: 8),
                        pw.Image(pw.MemoryImage(logo2), width: 60),
                        pw.SizedBox(width: 8),
                        pw.Image(pw.MemoryImage(logo3), width: 60),
                        pw.SizedBox(width: 8),
                        pw.Image(pw.MemoryImage(logo4), width: 60),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Fecha de ingreso:', style: small),
                        pw.Text(fecha, style: smallBold),
                        pw.SizedBox(height: 4),
                        pw.Text('Página 1', style: small),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'ANÁLISIS MOLECULAR DEL VIRUS DE PAPILOMA HUMANO (VPH)',
                    style: base.copyWith(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Mediante el uso de la Reacción en Cadena de la Polimerasa en tiempo real (qPCR) para la amplificación del virus del VPH obtenido en muestras, se llevó a cabo la genotipificación del VPH utilizando el kit Jiangsu Mole Bioscience MOSPIRE.',
                  style: small,
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 24),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(150),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _row(
                      'Código Dispositivo',
                      '$_selectedPrefix${_ctrl.text.trim()}',
                      base,
                      bold,
                    ),
                    _row('Paciente', _pacienteNombre!, base, bold),
                    _row('Diagnóstico', textoDiag, base, bold),
                    if (_genotiposSeleccionados.isNotEmpty)
                      _row(
                        'Genotipos detectados',
                        _genotiposSeleccionados.join(', '),
                        base,
                        bold,
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Interpretación:\n', style: bold),
                      pw.TextSpan(text: interpretacion, style: interpretStyle),
                    ],
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.Spacer(),
                pw.Container(
                  width: 120,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: pw.Image(
                    pw.MemoryImage(firma),
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(docNombre, style: small),
                pw.Text(
                  docEspecializacion.isNotEmpty
                      ? docEspecializacion
                      : 'Especialización no disponible',
                  style: small,
                ),
                pw.Text(
                  docNRegistro.isNotEmpty
                      ? docNRegistro
                      : 'N° registro no disponible',
                  style: smallBold,
                ),
              ],
            ),
      ),
    );

    final bytes = await pdf.save();
    if (_pdfUrl != null) html.Url.revokeObjectUrl(_pdfUrl!);
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    setState(() {
      _pdfGeneradoBytes = bytes;
      _pdfUrl = url;
    });

    _downloadPdf(bytes, 'resultado_vph_${_ctrl.text.trim()}.pdf');
  }

  void _downloadPdf(Uint8List data, String name) {
    final blob = html.Blob([data], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = name
          ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _uploadResult() async {
    if (_pdfGeneradoBytes == null || _resultadoTipo == null) {
      _showDialog(
        'Error',
        'Completa todos los campos y genera el PDF antes de subir.',
      );
      return;
    }
    if ((_resultadoTipo == 'alto' || _resultadoTipo == 'bajo') &&
        _genotiposSeleccionados.isEmpty) {
      _showDialog('Error', 'Selecciona al menos un genotipo detectado');
      return;
    }
    setState(() => _loadingUpload = true);
    try {
      await ApiService().uploadResultadoMedico(
        fileBytes: _pdfGeneradoBytes!,
        fileName: 'resultado_vph_${_ctrl.text.trim()}.pdf',
        dispositivo: '$_selectedPrefix${_ctrl.text.trim()}',
        diagnostico: _resultadoTipo!,
        genotipos: _genotiposSeleccionados,
      );

      //Obtener el UUID del paciente justo antes de enviar la notificación
      try {
        final publicId = await ApiService().fetchPublicIdFromInternalId(
          _pacienteId!,
        );
        print('📌 Public ID del paciente: $publicId'); // 👈 Esto lo verás en la consola del navegador

        await ApiService().enviarNotificacionPuntual(
          cuentaUsuarioPublicId: publicId,
          titulo: '¡Tu resultado está disponible!',
          mensaje:'Ya puedes consultar el resultado de tu examen desde la aplicación. Haz clic aquí para revisarlo.',
          tipoAccion: 'VER_RESULTADOS',
          accionUrl: 'https://miapp.com/video-tutorial',
        );

        _showDialog('Éxito', 'Resultado subido y notificación enviada.');
      } catch (notiError) {
        _showDialog(
          'Advertencia',
          'Resultado subido, pero la notificación falló.\nDetalles: $notiError',
        );
      }
    
      setState(() {
        _pdfGeneradoBytes = null;
        _pdfUrl = null;
        _resultadoTipo = null;
        _genotiposSeleccionados = [];
      });
    } catch (e) {
      _showDialog('Error', 'Error al subir: $e');
    } finally {
      setState(() => _loadingUpload = false);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(title, style: const TextStyle(color: Colors.black87)),
            content: Text(
              content,
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  pw.TableRow _row(String a, String b, pw.TextStyle base, pw.TextStyle bold) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.grey300,
          child: pw.Text(a, style: bold),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(b, style: base),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Buscar Paciente y Subir Resultado',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Desplegable de prefijos + campo de sufijo
                  if (_loadingPrefixes)
                    const Center(child: CircularProgressIndicator())
                  else if (_prefixes.isEmpty)
                    const Text(
                      'No hay prefijos disponibles',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedPrefix,
                          dropdownColor: Colors.white, // fondo del menú
                          style: const TextStyle(
                            color: Colors.black,
                          ), // texto negro
                          underline: Container(
                            // línea bajo el control
                            height: 1,
                            color: Colors.black54,
                          ),
                          items:
                              _prefixes
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _selectedPrefix = v),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            decoration: const InputDecoration(
                              labelText: 'Código (p.ej. A001)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: (_) {
                              if (!_loadingSearch) _searchDevice();
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadingSearch ? null : _searchDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA51008),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _loadingSearch
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Buscar'),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],

                  if (_pacienteNombre != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Paciente: $_pacienteNombre',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selección de resultado
                    DropdownButtonFormField<String>(
                      value: _resultadoTipo,
                      decoration: const InputDecoration(
                        labelText: 'Resultado',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 'alto',
                          child: Text('Positivo riesgo intermedio/alto'),
                        ),
                        DropdownMenuItem(
                          value: 'bajo',
                          child: Text('Positivo bajo'),
                        ),
                        DropdownMenuItem(
                          value: 'negativo',
                          child: Text('Negativo'),
                        ),
                      ],
                      onChanged:
                          (v) => setState(() {
                            _resultadoTipo = v;
                            _genotiposSeleccionados.clear();
                            _pdfGeneradoBytes = null;
                            if (_pdfUrl != null) {
                              html.Url.revokeObjectUrl(_pdfUrl!);
                              _pdfUrl = null;
                            }
                          }),
                    ),

                    // Chips de genotipos si aplica
                    if (_resultadoTipo == 'alto' ||
                        _resultadoTipo == 'bajo') ...[
                      const SizedBox(height: 16),
                      // Si es "alto", mostramos los dos grupos de genotipos con sus títulos para un resultado mixto
                      if (_resultadoTipo == 'alto') ...[
                        const Text('Genotipos de Alto Riesgo:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children:
                              _genotipos['alto']!.map((g) {
                                final sel = _genotiposSeleccionados.contains(g);
                                return FilterChip(
                                  label: Text(g),
                                  selected: sel,
                                  selectedColor:
                                      Colors
                                          .blue
                                          .shade100, // Color cuando está seleccionado
                                  backgroundColor: Colors.white, // Fondo
                                  side: BorderSide(color: Colors.grey.shade400),
                                  checkmarkColor: Colors.black,
                                  onSelected:
                                      (v) => setState(() {
                                        if (v) {
                                          _genotiposSeleccionados.add(g);
                                        } else {
                                          _genotiposSeleccionados.remove(g);
                                        }
                                        _pdfGeneradoBytes = null;
                                        if (_pdfUrl != null)
                                          html.Url.revokeObjectUrl(_pdfUrl!);
                                        _pdfUrl = null;
                                      }),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Genotipos de Bajo Riesgo:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children:
                              _genotipos['bajo']!.map((g) {
                                final sel = _genotiposSeleccionados.contains(g);
                                return FilterChip(
                                  label: Text(g),
                                  selected: sel,
                                  selectedColor:
                                      Colors
                                          .blue
                                          .shade100, // Color cuando está seleccionado
                                  backgroundColor: Colors.white, // Fondo blanco
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                  ), // Borde gris
                                  checkmarkColor:
                                      Colors
                                          .black, // Color de la marca de verificación
                                  onSelected:
                                      (v) => setState(() {
                                        if (v) {
                                          _genotiposSeleccionados.add(g);
                                        } else {
                                          _genotiposSeleccionados.remove(g);
                                        }
                                        _pdfGeneradoBytes = null;
                                        if (_pdfUrl != null)
                                          html.Url.revokeObjectUrl(_pdfUrl!);
                                        _pdfUrl = null;
                                      }),
                                );
                              }).toList(),
                        ),
                      ],
                      // Si es "bajo", solo mostramos los genotipos bajos
                      if (_resultadoTipo == 'bajo') ...[
                        const Text('Genotipos de Bajo Riesgo:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children:
                              _genotipos['bajo']!.map((g) {
                                final sel = _genotiposSeleccionados.contains(g);
                                return FilterChip(
                                  label: Text(g),
                                  selected: sel,
                                  selectedColor:
                                      Colors
                                          .blue
                                          .shade100, // Color cuando está seleccionado
                                  backgroundColor: Colors.white, // Fondo blanco
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                  ), // Borde gris
                                  checkmarkColor:
                                      Colors
                                          .black, // Color de la marca de verificación
                                  onSelected:
                                      (v) => setState(() {
                                        if (v) {
                                          _genotiposSeleccionados.add(g);
                                        } else {
                                          _genotiposSeleccionados.remove(g);
                                        }
                                        _pdfGeneradoBytes = null;
                                        if (_pdfUrl != null)
                                          html.Url.revokeObjectUrl(_pdfUrl!);
                                        _pdfUrl = null;
                                      }),
                                );
                              }).toList(),
                        ),
                      ],
                    ],

                    // Interpretación
                    if (_resultadoTipo != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Interpretación:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getInterpretacion(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _generarPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA51008),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    if (_pdfUrl != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final viewId =
                              'pdf-preview-${DateTime.now().millisecondsSinceEpoch}';
                          ui.platformViewRegistry.registerViewFactory(
                            viewId,
                            (int _) =>
                                html.IFrameElement()
                                  ..style.border = 'none'
                                  ..style.width = '100%'
                                  ..style.height = '100%'
                                  ..src = _pdfUrl!,
                          );
                          showDialog(
                            context: context,
                            builder:
                                (_) => Dialog(
                                  insetPadding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: 800,
                                    height: 600,
                                    child: HtmlElementView(viewType: viewId),
                                  ),
                                ),
                          );
                        },
                        icon: const Icon(Icons.pageview),
                        label: const Text('Vista Previa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002856),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadingUpload ? null : _uploadResult,
                      icon: const Icon(Icons.upload_file),
                      label:
                          _loadingUpload
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Subir Resultado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA51008),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
