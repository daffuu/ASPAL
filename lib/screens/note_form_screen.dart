import 'package:flutter/material.dart';

import '../models/road_report.dart';
import '../utils/validators.dart';

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key, required this.report});

  final RoadReport report;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.report.notes);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _popWithNote([String? result]) {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop<String>(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<String>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _popWithNote();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Catatan Laporan')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Laporan ${widget.report.id}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      border: OutlineInputBorder(),
                    ),
                    validator: validateNote,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        _popWithNote(_noteController.text.trim());
                      }
                    },
                    child: const Text('Simpan Catatan'),
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