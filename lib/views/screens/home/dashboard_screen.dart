import 'package:flutter/material.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/charts/service_distribution_chart.dart';
import '../../../navigation/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();
  bool _isLoading = true;
  String? _errorMessage;

  int _totalServices = 0;

  double _totalRevenue = 0.0;
  List<ServiceTypeStat> _serviceTypeStats = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _controller.getDashboardStats(_selectedDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _totalServices = response.data!.totalServices;

          _totalRevenue = response.data!.totalRevenue;
          _serviceTypeStats = response.data!.serviceTypeStats;
        } else {
          _errorMessage = response.message ?? 'Error loading dashboard';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Labo Bar',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando estadísticas...');
    }

    if (_errorMessage != null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadDashboardData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.primaryOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Stats grid
            // Stats grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Service Distribution Chart
            if (_serviceTypeStats.isNotEmpty) ...[
              ServiceDistributionChart(stats: _serviceTypeStats),
              const SizedBox(height: 24),
            ],

            // Quick actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryOrange,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDashboardData();
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona tu lavadero de motos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.two_wheeler, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Servicios',
          value: '$_totalServices',
          valueFontSize: MediaQuery.sizeOf(context).width * 0.04,
          iconSize: MediaQuery.sizeOf(context).width * 0.05,
          titleFontSize: MediaQuery.sizeOf(context).width * 0.03,
          icon: Icons.two_wheeler,
          color: AppTheme.secondaryBlue,
        ),

        StatCard(
          title: 'Ingresos',
          value: '\$${_totalRevenue.toStringAsFixed(0)}',
          valueFontSize: MediaQuery.sizeOf(context).width * 0.04,
          iconSize: MediaQuery.sizeOf(context).width * 0.05,
          titleFontSize: MediaQuery.sizeOf(context).width * 0.03,
          icon: Icons.attach_money,
          color: AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          title: 'Nuevo Servicio',
          subtitle: 'Registrar un nuevo lavado',
          icon: Icons.add_circle,
          color: AppTheme.primaryOrange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.serviceForm),
        ),
        _buildActionCard(
          title: 'Nuevo Trabajador',
          subtitle: 'Agregar un trabajador',
          icon: Icons.person_add,
          color: AppTheme.secondaryBlue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.workerForm),
        ),
        _buildActionCard(
          title: 'Nuevo Tipo de Servicio',
          subtitle: 'Crear tipo de servicio',
          icon: Icons.category,
          color: AppTheme.darkBlue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.serviceTypeForm),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}
