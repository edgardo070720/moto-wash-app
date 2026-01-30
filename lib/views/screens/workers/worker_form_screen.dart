import 'package:flutter/material.dart';

import '../../../controllers/worker_controller.dart';
import '../../../models/worker_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../../theme/app_theme.dart';

class WorkerFormScreen extends StatefulWidget {
  final Worker? worker;

  const WorkerFormScreen({super.key, this.worker});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final WorkerController _controller = WorkerController();
  bool _isLoading = false;

  bool get _isEditing => widget.worker != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nicknameController.text = widget.worker!.nickname;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final worker = Worker(
      idWorker: _isEditing
          ? widget.worker!.idWorker
          : -DateTime.now().millisecondsSinceEpoch, // Temp ID for offline
      nickname: _nicknameController.text.trim(),
      priceWorker: 0.0, // Default value since field is removed
    );

    final response = _isEditing
        ? await _controller.updateWorker(worker)
        : await _controller.createWorker(worker);

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Trabajador actualizado' : 'Trabajador creado',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Error al guardar'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Editar Trabajador' : 'Nuevo Trabajador',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),

            // Nickname field
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Apodo',
                hintText: 'Ej: Juan',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un apodo';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveWorker,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isEditing ? 'Actualizar' : 'Guardar',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
