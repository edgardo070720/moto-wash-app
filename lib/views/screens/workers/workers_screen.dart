import 'package:flutter/material.dart';
import '../../../controllers/worker_controller.dart';
import '../../../models/worker_model.dart';
import '../../../navigation/app_routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/cards/worker_card.dart';
import '../../../theme/app_theme.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final WorkerController _controller = WorkerController();
  bool _isLoading = true;
  String? _errorMessage;
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _controller.getWorkers();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.dataList != null) {
          _workers = response.dataList!;
        } else {
          _errorMessage = response.message ?? 'Error loading workers';
        }
      });
    }
  }

  Future<void> _deleteWorker(Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a ${worker.nickname}?'),
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
      final response = await _controller.deleteWorker(worker.idWorker);
      
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajador eliminado')),
          );
          _loadWorkers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al eliminar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToForm([Worker? worker]) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.workerForm,
      arguments: worker,
    );

    if (result == true) {
      _loadWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Trabajadores',
        showBackButton: false,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando trabajadores...');
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadWorkers,
      );
    }

    if (_workers.isEmpty) {
      return EmptyStateWidget(
        message: 'No hay trabajadores registrados',
        icon: Icons.people_outline,
        actionLabel: 'Agregar Trabajador',
        onAction: () => _navigateToForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkers,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        itemCount: _workers.length,
        itemBuilder: (context, index) {
          final worker = _workers[index];
          return WorkerCard(
            worker: worker,
            onEdit: () => _navigateToForm(worker),
            onDelete: () => _deleteWorker(worker),
          );
        },
      ),
    );
  }
}
