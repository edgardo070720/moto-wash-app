import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/worker_model.dart';
import '../../../models/type_washing_service_model.dart';
import '../../../theme/app_theme.dart';

class ServiceFilterDialog extends StatefulWidget {
  final List<Worker> workers;
  final List<TypeWashingService> serviceTypes;
  final DateTime? initialDate;
  final int? initialWorkerId;
  final int? initialTypeId;

  const ServiceFilterDialog({
    super.key,
    required this.workers,
    required this.serviceTypes,
    this.initialDate,
    this.initialWorkerId,
    this.initialTypeId,
  });

  @override
  State<ServiceFilterDialog> createState() => _ServiceFilterDialogState();
}

class _ServiceFilterDialogState extends State<ServiceFilterDialog> {
  bool _filterByDate = false;
  bool _filterByWorker = false;
  bool _filterByType = false;

  DateTime _selectedDate = DateTime.now();
  int? _selectedWorkerId;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _filterByDate = true;
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialWorkerId != null) {
      _filterByWorker = true;
      _selectedWorkerId = widget.initialWorkerId;
    }
    if (widget.initialTypeId != null) {
      _filterByType = true;
      _selectedTypeId = widget.initialTypeId;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.secondaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'date': _filterByDate ? _selectedDate : null,
      'workerId': _filterByWorker ? _selectedWorkerId : null,
      'typeId': _filterByType ? _selectedTypeId : null,
    });
  }

  void _clearFilters() {
    Navigator.pop(context, {'date': null, 'workerId': null, 'typeId': null});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar Servicios'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date Filter
            _buildFilterRow(
              label: 'Fecha',
              isActive: _filterByDate,
              onChanged: (val) => setState(() => _filterByDate = val ?? false),
              child: InkWell(
                onTap: _filterByDate ? _selectDate : null,
                child: InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    enabled: _filterByDate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Worker Filter
            _buildFilterRow(
              label: 'Trabajador',
              isActive: _filterByWorker,
              onChanged: (val) =>
                  setState(() => _filterByWorker = val ?? false),
              child: DropdownButtonFormField<int>(
                value: _selectedWorkerId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabled: _filterByWorker,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: widget.workers.map((worker) {
                  return DropdownMenuItem(
                    value: worker.idWorker,
                    child: Text(
                      worker.nickname,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _filterByWorker
                    ? (value) => setState(() => _selectedWorkerId = value)
                    : null,
                hint: const Text('Seleccionar'),
              ),
            ),
            const SizedBox(height: 16),

            // Service Type Filter
            _buildFilterRow(
              label: 'Tipo Servicio',
              isActive: _filterByType,
              onChanged: (val) => setState(() => _filterByType = val ?? false),
              child: DropdownButtonFormField<int>(
                value: _selectedTypeId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabled: _filterByType,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: widget.serviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.id,
                    child: Text(type.detail, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _filterByType
                    ? (value) => setState(() => _selectedTypeId = value)
                    : null,
                hint: const Text('Seleccionar'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _clearFilters, child: const Text('Limpiar')),
        ElevatedButton(onPressed: _applyFilters, child: const Text('Aplicar')),
      ],
    );
  }

  Widget _buildFilterRow({
    required String label,
    required bool isActive,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: isActive,
              onChanged: onChanged,
              activeColor: AppTheme.secondaryBlue,
            ),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Opacity(opacity: isActive ? 1.0 : 0.5, child: child),
        ),
      ],
    );
  }
}
