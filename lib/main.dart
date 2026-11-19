import 'package:flutter/material.dart';

import 'features/auth/auth_module.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthModule.init();
  runApp(
    AuthScope(
      controller: AuthModule.controller,
      child: const AspalApp(),
    ),
  );
}

class AspalApp extends StatelessWidget {
  const AspalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASPAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}
