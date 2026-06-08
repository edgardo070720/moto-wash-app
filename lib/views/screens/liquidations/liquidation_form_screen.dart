import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../controllers/liquidation_controller.dart';
import '../../../controllers/worker_controller.dart';
import '../../../models/liquidation_model.dart';
import '../../../models/worker_model.dart';
import '../../widgets/common/custom_app_bar.dart';

class LiquidationFormScreen extends StatefulWidget {
  final Liquidation? liquidation;

  const LiquidationFormScreen({super.key, this.liquidation});

  @override
  State<LiquidationFormScreen> createState() => _LiquidationFormScreenState();
}

class _LiquidationFormScreenState extends State<LiquidationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LiquidationController _liquidationController = LiquidationController();
  final WorkerController _workerController = WorkerController();

  List<Worker> _workers = [];
  Worker? _selectedWorker;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _deductibleController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();

  bool _isLoadingWorkers = true;
  bool _isCalculating = false;
  bool _isSaving = false;
  bool _hasCalculated = false;

  // Calculation results
  int _servicesCount = 0;
  double _totalServices = 0.0;
  double _totalLiquidation = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    if (widget.liquidation != null) {
      _initializeWithLiquidation();
    }
  }

  void _initializeWithLiquidation() {
    final liq = widget.liquidation!;
    _selectedWorker = liq.worker;
    _selectedDate = liq.dateLiquidation;
    _deductibleController.text = liq.deductible.toStringAsFixed(0);
    _tipController.text = liq.tip.toStringAsFixed(0);
    _totalLiquidation = liq.totalLiquidation;
    _hasCalculated = true;
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoadingWorkers = true);
    final response = await _workerController.getWorkers();
    setState(() {
      _isLoadingWorkers = false;
      if (response.success && response.dataList != null) {
        _workers = response.dataList!;
        if (widget.liquidation != null) {
          _selectedWorker = _workers.firstWhere(
            (w) => w.idWorker == widget.liquidation!.worker.idWorker,
            orElse: () => _workers.first,
          );
        }
      }
    });
  }

  Future<void> _calculateLiquidation() async {
    if (_selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un trabajador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);

    final result = await _liquidationController.calculateLiquidation(
      _selectedWorker!,
      _selectedDate,
    );

    setState(() {
      _isCalculating = false;
      if (result['success']) {
        _servicesCount = result['servicesCount'];
        _totalServices = result['totalServices'];
        _totalLiquidation = result['totalLiquidation'];
        _hasCalculated = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _saveLiquidation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorker == null || !_hasCalculated) return;

    setState(() => _isSaving = true);

    final deductible = double.tryParse(_deductibleController.text) ?? 0.0;
    final tip = double.tryParse(_tipController.text) ?? 0.0;

    final liquidation = Liquidation(
      id: widget.liquidation?.id ?? -DateTime.now().millisecondsSinceEpoch,
      dateLiquidation: _selectedDate,
      totalLiquidation: _totalLiquidation,
      deductible: deductible,
      tip: tip,
      worker: _selectedWorker!,
    );

    final response = widget.liquidation == null
        ? await _liquidationController.createLiquidation(liquidation)
        : await _liquidationController.updateLiquidation(liquidation);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Operación completada'),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
      if (response.success) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasCalculated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.liquidation == null
            ? 'Nueva Liquidación'
            : 'Editar Liquidación',
      ),
      body: _isLoadingWorkers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Worker Selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trabajador',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Worker>(
                              value: _selectedWorker,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: _workers.map((worker) {
                                return DropdownMenuItem(
                                  value: worker,
                                  child: Text(worker.nickname),
                                );
                              }).toList(),
                              onChanged: (worker) {
                                setState(() {
                                  _selectedWorker = worker;
                                  _hasCalculated = false;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Requerido' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(dateFormat.format(_selectedDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calculate Button
                    ElevatedButton.icon(
                      onPressed: _isCalculating ? null : _calculateLiquidation,
                      icon: _isCalculating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate),
                      label: Text(
                        _isCalculating
                            ? 'Calculando...'
                            : 'Calcular Liquidación',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Results Section
                    if (_hasCalculated) ...[
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Resumen de Servicios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildSummaryRow(
                                'Servicios realizados:',
                                '$_servicesCount',
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Total de servicios:',
                                currencyFormat.format(_totalServices),
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Total liquidación (50%):',
                                currencyFormat.format(_totalLiquidation),
                                valueStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deductible Input
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deducible',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _deductibleController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.remove_circle_outline),
                                  prefixText: '\$ ',
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tip Input
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Propina',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _tipController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.add_circle_outline),
                                  prefixText: '\$ ',
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Final Total
                      Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL FINAL:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currencyFormat.format(
                                  _totalLiquidation -
                                      (double.tryParse(
                                            _deductibleController.text,
                                          ) ??
                                          0.0) +
                                      (double.tryParse(_tipController.text) ??
                                          0.0),
                                ),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveLiquidation,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Liquidación',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _deductibleController.dispose();
    _tipController.dispose();
    super.dispose();
  }
}
