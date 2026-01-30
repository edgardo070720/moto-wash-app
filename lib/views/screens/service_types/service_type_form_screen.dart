import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../controllers/service_type_controller.dart';
import '../../../models/type_washing_service_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../../theme/app_theme.dart';

class ServiceTypeFormScreen extends StatefulWidget {
  final TypeWashingService? serviceType;

  const ServiceTypeFormScreen({super.key, this.serviceType});

  @override
  State<ServiceTypeFormScreen> createState() => _ServiceTypeFormScreenState();
}

class _ServiceTypeFormScreenState extends State<ServiceTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailController = TextEditingController();
  final _priceController = TextEditingController();
  final ServiceTypeController _controller = ServiceTypeController();
  bool _isLoading = false;

  bool get _isEditing => widget.serviceType != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _detailController.text = widget.serviceType!.detail;
      _priceController.text = widget.serviceType!.priceService.toString();
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveServiceType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final serviceType = TypeWashingService(
      id: _isEditing
          ? widget.serviceType!.id
          : -DateTime.now().millisecondsSinceEpoch, // Temp ID for offline
      detail: _detailController.text.trim(),
      priceService: double.parse(_priceController.text),
    );

    final response = _isEditing
        ? await _controller.updateServiceType(serviceType)
        : await _controller.createServiceType(serviceType);

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Tipo de servicio actualizado'
                  : 'Tipo de servicio creado',
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
        title: _isEditing
            ? 'Editar Tipo de Servicio'
            : 'Nuevo Tipo de Servicio',
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.category,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Detail field
            TextFormField(
              controller: _detailController,
              decoration: const InputDecoration(
                labelText: 'Detalle del Servicio',
                hintText: 'Ej: Lavado Básico',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un detalle';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio del Servicio',
                hintText: 'Ej: 10000',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un precio';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Ingresa un precio válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveServiceType,
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
