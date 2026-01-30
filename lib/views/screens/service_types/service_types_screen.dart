import 'package:flutter/material.dart';
import '../../../controllers/service_type_controller.dart';
import '../../../models/type_washing_service_model.dart';
import '../../../navigation/app_routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/cards/service_type_card.dart';
import '../../../theme/app_theme.dart';

class ServiceTypesScreen extends StatefulWidget {
  const ServiceTypesScreen({super.key});

  @override
  State<ServiceTypesScreen> createState() => _ServiceTypesScreenState();
}

class _ServiceTypesScreenState extends State<ServiceTypesScreen> {
  final ServiceTypeController _controller = ServiceTypeController();
  bool _isLoading = true;
  String? _errorMessage;
  List<TypeWashingService> _serviceTypes = [];

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
  }

  Future<void> _loadServiceTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _controller.getServiceTypes();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.dataList != null) {
          _serviceTypes = response.dataList!;
        } else {
          _errorMessage = response.message ?? 'Error loading service types';
        }
      });
    }
  }

  Future<void> _deleteServiceType(TypeWashingService serviceType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${serviceType.detail}"?'),
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
      final response = await _controller.deleteServiceType(serviceType.id);
      
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tipo de servicio eliminado')),
          );
          _loadServiceTypes();
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

  void _navigateToForm([TypeWashingService? serviceType]) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.serviceTypeForm,
      arguments: serviceType,
    );

    if (result == true) {
      _loadServiceTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tipos de Servicio',
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
      return const LoadingIndicator(message: 'Cargando tipos de servicio...');
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadServiceTypes,
      );
    }

    if (_serviceTypes.isEmpty) {
      return EmptyStateWidget(
        message: 'No hay tipos de servicio registrados',
        icon: Icons.category_outlined,
        actionLabel: 'Agregar Tipo',
        onAction: () => _navigateToForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadServiceTypes,
      color: AppTheme.primaryOrange,
      child: ListView.builder(
        itemCount: _serviceTypes.length,
        itemBuilder: (context, index) {
          final serviceType = _serviceTypes[index];
          return ServiceTypeCard(
            serviceType: serviceType,
            onEdit: () => _navigateToForm(serviceType),
            onDelete: () => _deleteServiceType(serviceType),
          );
        },
      ),
    );
  }
}
