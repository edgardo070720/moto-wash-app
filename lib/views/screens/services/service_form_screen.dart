import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/service_controller.dart';
import '../../../controllers/worker_controller.dart';
import '../../../controllers/service_type_controller.dart';
import '../../../models/washing_service_model.dart';
import '../../../models/worker_model.dart';
import '../../../models/type_washing_service_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../../theme/app_theme.dart';

class ServiceFormScreen extends StatefulWidget {
  final WashingService? service;

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceController _serviceController = ServiceController();
  final WorkerController _workerController = WorkerController();
  final ServiceTypeController _serviceTypeController = ServiceTypeController();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Worker> _workers = [];
  List<TypeWashingService> _serviceTypes = [];

  Worker? _selectedWorker;
  TypeWashingService? _selectedServiceType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);

    // Load workers and service types in parallel
    final workersResponse = await _workerController.getWorkers();
    final serviceTypesResponse = await _serviceTypeController.getServiceTypes();

    if (mounted) {
      setState(() {
        _isLoadingData = false;

        if (workersResponse.success && workersResponse.dataList != null) {
          _workers = workersResponse.dataList!;
        }

        if (serviceTypesResponse.success &&
            serviceTypesResponse.dataList != null) {
          _serviceTypes = serviceTypesResponse.dataList!;
        }

        // If editing, set selected values
        if (_isEditing) {
          _selectedWorker = _workers.firstWhere(
            (w) => w.idWorker == widget.service!.worker.idWorker,
            orElse: () => widget.service!.worker,
          );
          _selectedServiceType = _serviceTypes.firstWhere(
            (st) => st.id == widget.service!.typeService.id,
            orElse: () => widget.service!.typeService,
          );
          _selectedDate = widget.service!.dateService;
          _selectedTime = TimeOfDay.fromDateTime(widget.service!.dateService);
        }
      });
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
            colorScheme: ColorScheme.light(primary: AppTheme.primaryOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un trabajador')),
      );
      return;
    }

    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de servicio'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Combine date and time
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final service = WashingService(
      idService: _isEditing
          ? widget.service!.idService
          : -DateTime.now().millisecondsSinceEpoch, // Temp ID for offline
      dateService: dateTime,
      worker: _selectedWorker!,
      typeService: _selectedServiceType!,
    );

    final response = _isEditing
        ? await _serviceController.updateService(service)
        : await _serviceController.createService(service);

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Servicio actualizado' : 'Servicio creado',
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
        title: _isEditing ? 'Editar Servicio' : 'Nuevo Servicio',
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                        color: AppTheme.secondaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.two_wheeler,
                        size: 50,
                        color: AppTheme.secondaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Worker dropdown
                  DropdownButtonFormField<Worker>(
                    value: _selectedWorker,
                    decoration: const InputDecoration(
                      labelText: 'Trabajador',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _workers.map((worker) {
                      return DropdownMenuItem(
                        value: worker,
                        child: Text(worker.nickname),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedWorker = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selecciona un trabajador';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Service type dropdown
                  DropdownButtonFormField<TypeWashingService>(
                    value: _selectedServiceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Servicio',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _serviceTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.detail),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedServiceType = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selecciona un tipo de servicio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date picker
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time picker
                  InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price summary
                  if (_selectedWorker != null && _selectedServiceType != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de Precio',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trabajador:'),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(_selectedWorker!.priceWorker),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Servicio:'),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(_selectedServiceType!.priceService),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(
                                  _selectedWorker!.priceWorker +
                                      _selectedServiceType!.priceService,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveService,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
