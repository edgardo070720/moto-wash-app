import 'package:flutter/material.dart';
import '../../../controllers/service_controller.dart';
import '../../../controllers/worker_controller.dart';
import '../../../controllers/service_type_controller.dart';
import '../../../models/washing_service_model.dart';
import '../../../models/worker_model.dart';
import '../../../models/type_washing_service_model.dart';
import '../../../navigation/app_routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/service_filter_dialog.dart';
import '../../widgets/cards/service_card.dart';
import '../../../theme/app_theme.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServiceController _controller = ServiceController();
  final WorkerController _workerController = WorkerController();
  final ServiceTypeController _serviceTypeController = ServiceTypeController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 10;
  String? _errorMessage;
  List<WashingService> _services = [];

  // Filter data
  List<Worker> _workers = [];
  List<TypeWashingService> _serviceTypes = [];

  // Active filters
  DateTime? _filterDate;
  int? _filterWorkerId;
  int? _filterTypeId;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreServices();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Load everything in parallel
    final results = await Future.wait([
      _controller.getServices(page: 1, limit: _limit),
      _workerController.getWorkers(),
      _serviceTypeController.getServiceTypes(),
    ]);

    final servicesResponse = results[0] as dynamic;
    final workersResponse = results[1] as dynamic;
    final typesResponse = results[2] as dynamic;

    if (mounted) {
      setState(() {
        _isLoading = false;

        // Handle services
        if (servicesResponse.success && servicesResponse.dataList != null) {
          _services = servicesResponse.dataList!;
          _hasMore = _services.length >= _limit;
          _page = 1;
          _services.sort((a, b) => b.dateService.compareTo(a.dateService));
        } else {
          _errorMessage = servicesResponse.message ?? 'Error loading services';
        }

        // Handle workers
        if (workersResponse.success && workersResponse.dataList != null) {
          _workers = workersResponse.dataList!;
        }

        // Handle types
        if (typesResponse.success && typesResponse.dataList != null) {
          _serviceTypes = typesResponse.dataList!;
        }
      });
    }
  }

  Future<void> _loadServices({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _hasMore = true;
        _services.clear();
      });
    }

    final response = _isFiltered
        ? await _controller.filterServices(
            date: _filterDate,
            workerId: _filterWorkerId,
            typeId: _filterTypeId,
            page: 1,
            limit: _limit,
          )
        : await _controller.getServices(page: 1, limit: _limit);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.dataList != null) {
          _services = response.dataList!;
          _hasMore = _services.length >= _limit;
          _services.sort((a, b) => b.dateService.compareTo(a.dateService));
        } else {
          _errorMessage = response.message ?? 'Error loading services';
        }
      });
    }
  }

  Future<void> _loadMoreServices() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;
    final response = _isFiltered
        ? await _controller.filterServices(
            date: _filterDate,
            workerId: _filterWorkerId,
            typeId: _filterTypeId,
            page: nextPage,
            limit: _limit,
          )
        : await _controller.getServices(page: nextPage, limit: _limit);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (response.success && response.dataList != null) {
          final newServices = response.dataList!;
          if (newServices.isEmpty) {
            _hasMore = false;
          } else {
            _services.addAll(newServices);
            _services.sort((a, b) => b.dateService.compareTo(a.dateService));
            _page = nextPage;
            if (newServices.length < _limit) {
              _hasMore = false;
            }
          }
        } else {
          // Optionally handle error for pagination
        }
      });
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ServiceFilterDialog(
        workers: _workers,
        serviceTypes: _serviceTypes,
        initialDate: _filterDate,
        initialWorkerId: _filterWorkerId,
        initialTypeId: _filterTypeId,
      ),
    );

    if (result != null) {
      setState(() {
        _filterDate = result['date'];
        _filterWorkerId = result['workerId'];
        _filterTypeId = result['typeId'];

        _isFiltered =
            _filterDate != null ||
            _filterWorkerId != null ||
            _filterTypeId != null;
      });
      _loadServices(refresh: true);
    }
  }

  Future<void> _deleteService(WashingService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar este servicio de ${service.typeService.detail}?',
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
      final response = await _controller.deleteService(service.idService);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Servicio eliminado')));
          _loadServices(refresh: true);
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

  void _navigateToForm([WashingService? service]) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.serviceForm,
      arguments: service,
    );

    if (result == true) {
      _loadServices(refresh: true);
    }
  }

  void _showTotalDialog() {
    double total = 0;
    for (var service in _services) {
      total += service.totalPrice;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen Total'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              size: 48,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Total de servicios cargados:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(${_services.length} servicios)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Servicios',
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(
              _isFiltered ? Icons.filter_list_off : Icons.filter_list,
              color: _isFiltered ? AppTheme.lightOrange : Colors.white,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btnTotal',
            onPressed: _showTotalDialog,
            backgroundColor: AppTheme.successColor,
            child: const Icon(Icons.attach_money),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btnAdd',
            onPressed: () => _navigateToForm(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando servicios...');
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: () => _loadServices(refresh: true),
      );
    }

    if (_services.isEmpty) {
      return EmptyStateWidget(
        message: _isFiltered
            ? 'No se encontraron servicios con los filtros aplicados'
            : 'No hay servicios registrados',
        icon: Icons.two_wheeler_outlined,
        actionLabel: _isFiltered ? 'Limpiar Filtros' : 'Agregar Servicio',
        onAction: _isFiltered
            ? () {
                setState(() {
                  _filterDate = null;
                  _filterWorkerId = null;
                  _filterTypeId = null;
                  _isFiltered = false;
                });
                _loadServices(refresh: true);
              }
            : () => _navigateToForm(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadServices(refresh: true),
      color: AppTheme.primaryOrange,
      child: Column(
        children: [
          if (_isFiltered)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.secondaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: AppTheme.secondaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros activos',
                    style: TextStyle(
                      color: AppTheme.secondaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterDate = null;
                        _filterWorkerId = null;
                        _filterTypeId = null;
                        _isFiltered = false;
                      });
                      _loadServices(refresh: true);
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _services.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _services.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  );
                }

                final service = _services[index];
                return ServiceCard(
                  service: service,
                  onEdit: () => _navigateToForm(service),
                  onDelete: () => _deleteService(service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
