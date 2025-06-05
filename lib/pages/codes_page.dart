// lib/pages/qr_generator_page.dart

import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:archive/archive.dart';

import 'package:telemedicina_web/services/api_service.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({Key? key}) : super(key: key);

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _prefixController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  DateTime? _fechaExpiracion;
  String _selectedLote = 'A';
  bool _loading = false;

  Future<void> _descargarArchivo(Uint8List bytes, String nombreArchivo) async {
    final blob = html.Blob([bytes], 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<Uint8List> generateQrCodeWithLabel(String code) async {
    const int qrSize = 300;
    const int textHeight = 80;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, qrSize.toDouble(), (qrSize + textHeight).toDouble()),
      Paint()..color = Colors.white,
    );

    // generar QR
    final qrValidationResult = QrValidator.validate(
      data: code,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    final qrCode = qrValidationResult.qrCode!;
    QrPainter.withQr(
      qr: qrCode,
      color: Colors.black,
      emptyColor: Colors.white,
      gapless: true,
    ).paint(canvas, Size(qrSize.toDouble(), qrSize.toDouble()));

    // texto debajo
    final labelText = code.split('-').last;
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 75,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: qrSize.toDouble(), maxWidth: qrSize.toDouble());
    textPainter.paint(canvas, Offset(0, qrSize.toDouble() + 10));

    final picture = recorder.endRecording();
    final image = await picture.toImage(qrSize, qrSize + textHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _generarCodigos() async {
    if (!_formKey.currentState!.validate() || _fechaExpiracion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos correctamente')),
      );
      return;
    }

    setState(() => _loading = true);

    final prefix = _prefixController.text.trim();
    final lote = _selectedLote;
    final cantidad = int.parse(_cantidadController.text);
    final fecha = DateFormat('yyyy-MM-dd').format(_fechaExpiracion!);

    final codigos = List.generate(
      cantidad,
      (i) => '$prefix-$lote${(i + 1).toString().padLeft(3, '0')}',
    );

    final archive = Archive();
    for (final codigo in codigos) {
      try {
        final bytes = await generateQrCodeWithLabel(codigo);
        await ApiService().guardarQRConInfo(
          codigo: codigo,
          fechaExpiracion: fecha,
        );
        archive.addFile(ArchiveFile('$codigo.png', bytes.length, bytes));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando $codigo: $e')),
        );
      }
    }

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData != null) {
      await _descargarArchivo(Uint8List.fromList(zipData), 'codigos_qr.zip');
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Éxito', style: TextStyle(color: Colors.black87)),
        content: const Text(
          'Códigos generados y ZIP descargado exitosamente',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
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
            // Logo 
            Row(
              children: [
                Image.asset(
                  'assets/images/logoucuencaprincipal.png',
                  height: 32,
                ),
                const SizedBox(width: 8),
                ],
            ),
            // Título de la página alineado a la derecha
            const Text(
              'Generador de Códigos QR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(labelText: 'Prefijo'),
                    maxLength: 8,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedLote,
                    decoration:
                        const InputDecoration(labelText: 'Lote (A-Z)'),
                    dropdownColor: Colors.white, // fondo blanco al desplegar
                    items: List.generate(26, (i) {
                      final letra = String.fromCharCode(65 + i);
                      return DropdownMenuItem(value: letra, child: Text(letra));
                    }),
                    onChanged: (v) => setState(() => _selectedLote = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                        labelText: 'Cantidad de códigos (max 999)'),
                    maxLength: 3,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 999) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    tileColor: Colors.white,
                    title: Text(
                      _fechaExpiracion != null
                          ? 'Expira: ${DateFormat('yyyy-MM-dd').format(_fechaExpiracion!)}'
                          : 'Selecciona fecha de expiración',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.calendar_today,
                        color: Colors.black54),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        builder: (ctx, child) => Theme(
                          data: ThemeData(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF002856),
                              onPrimary: Colors.white,
                              onSurface: Colors.black87,
                            ),
                            dialogBackgroundColor: Colors.white,
                          ),
                          child: child!,
                        ),
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                        initialDate: now,
                      );
                      if (picked != null) {
                        setState(() => _fechaExpiracion = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _generarCodigos,
                    icon: const Icon(Icons.qr_code),
                    label: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Generar'),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
