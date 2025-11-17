import 'package:flutter/material.dart';
import '../services/excel_import_service.dart';

class ImportScreen extends StatefulWidget {
  final String assetPath;
  const ImportScreen({super.key, required this.assetPath});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _json;
  bool _loading = false;
  String? _error;

  Future<void> _runImport() async {
    setState(() {
      _loading = true;
      _error = null;
      _json = null;
    });
    try {
      final svc = ExcelImportService(widget.assetPath);
      final out = await svc.parseToJson();
      setState(() {
        _json = out;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import XLSX')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _runImport,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importer assets/ATP_Cincinnati.xlsx'),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                'Erreur: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            if (_json != null)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _json ?? '',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
