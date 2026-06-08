import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';
import 'home_wrapper.dart';
import 'navigation/app_routes.dart';
import 'views/screens/workers/worker_form_screen.dart';
import 'views/screens/services/service_form_screen.dart';
import 'views/screens/service_types/service_type_form_screen.dart';
import 'views/screens/liquidations/liquidations_screen.dart';
import 'views/screens/liquidations/liquidation_form_screen.dart';
import 'models/worker_model.dart';
import 'models/washing_service_model.dart';
import 'models/type_washing_service_model.dart';
import 'models/liquidation_model.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize connectivity service
  await ConnectivityService().initialize();

  // Initialize sync service
  SyncService().initialize();

  runApp(const LavoBarApp());
}

class LavoBarApp extends StatelessWidget {
  const LavoBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeWrapper(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.dashboard:
            return MaterialPageRoute(builder: (_) => const HomeWrapper());

          case AppRoutes.workerForm:
            final worker = settings.arguments as Worker?;
            return MaterialPageRoute(
              builder: (_) => WorkerFormScreen(worker: worker),
            );

          case AppRoutes.serviceForm:
            final service = settings.arguments as WashingService?;
            return MaterialPageRoute(
              builder: (_) => ServiceFormScreen(service: service),
            );

          case AppRoutes.serviceTypeForm:
            final serviceType = settings.arguments as TypeWashingService?;
            return MaterialPageRoute(
              builder: (_) => ServiceTypeFormScreen(serviceType: serviceType),
            );

          case AppRoutes.liquidations:
            return MaterialPageRoute(
              builder: (_) => const LiquidationsScreen(),
            );

          case AppRoutes.liquidationForm:
            final liquidation = settings.arguments as Liquidation?;
            return MaterialPageRoute(
              builder: (_) => LiquidationFormScreen(liquidation: liquidation),
            );

          default:
            return MaterialPageRoute(builder: (_) => const HomeWrapper());
        }
      },
    );
  }
}
