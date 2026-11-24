import 'core/database/app_database.dart';
import 'features/auth/auth_module.dart';
import 'features/reports/reports_module.dart';

final reportsModule = ReportsModule(
  AppDatabase.instance,
  AuthModule.repository,
);
