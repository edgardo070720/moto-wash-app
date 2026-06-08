import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/liquidation_controller.dart';
import '../../../models/liquidation_model.dart';
import '../../../models/api_response.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'liquidation_form_screen.dart';

class LiquidationsScreen extends StatefulWidget {
  const LiquidationsScreen({super.key});

  @override
  State<LiquidationsScreen> createState() => _LiquidationsScreenState();
}

class _LiquidationsScreenState extends State<LiquidationsScreen> {
  final LiquidationController _controller = LiquidationController();
  List<Liquidation> _liquidations = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLiquidations();
  }

  Future<void> _loadLiquidations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ApiResponse<Liquidation> response = await _controller.getLiquidations(
      date: _selectedDate,
    );

    setState(() {
      _isLoading = false;
      if (response.success && response.dataList != null) {
        _liquidations = response.dataList!;
      } else {
        _errorMessage = response.message ?? 'Error al cargar liquidaciones';
      }
    });
  }

  Future<void> _deleteLiquidation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Está seguro de que desea eliminar esta liquidación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _controller.deleteLiquidation(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Liquidación eliminada'
                  : response.message ?? 'Error al eliminar',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) {
          _loadLiquidations();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Liquidaciones',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadLiquidations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _liquidations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay liquidaciones registradas',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLiquidations,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _liquidations.length,
                itemBuilder: (context, index) {
                  final liquidation = _liquidations[index];
                  return _buildLiquidationCard(liquidation);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiquidationFormScreen(),
            ),
          );
          if (result == true) {
            _loadLiquidations();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Liquidación'),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadLiquidations();
    }
  }

  Widget _buildLiquidationCard(Liquidation liquidation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LiquidationFormScreen(liquidation: liquidation),
            ),
          );
          if (result == true) {
            _loadLiquidations();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liquidation.worker.nickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(liquidation.dateLiquidation),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteLiquidation(liquidation.id),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Liquidación:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    currencyFormat.format(liquidation.totalLiquidation),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deducible:', style: TextStyle(color: Colors.grey[700])),
                  Text(
                    currencyFormat.format(liquidation.deductible),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Propina:', style: TextStyle(color: Colors.grey[700])),
                  Text(
                    currencyFormat.format(liquidation.tip),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Final:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currencyFormat.format(liquidation.totalFinal),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
